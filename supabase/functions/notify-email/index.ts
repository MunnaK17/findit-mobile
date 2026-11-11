// notify-email: buat notifikasi in-app (tabel app_notifications) dan kirim email lewat Gmail SMTP.
// Dipanggil trigger database (public.notify_email_dispatch) via pg_net dengan body {event, id}.
// Isi email selalu dibaca ulang dari database; payload hanya menunjuk baris mana yang berubah.
//
// Secret yang diperlukan (Dashboard > Edge Functions > Secrets):
//   GMAIL_USER          alamat Gmail pengirim, mis. findit.ubsi@gmail.com
//   GMAIL_APP_PASSWORD  App Password 16 karakter dari akun Google tersebut
//   FCM_SERVICE_ACCOUNT isi JSON service account Firebase (Project settings > Service accounts).
//                       Opsional: tanpa secret ini push notification dilewati, email tetap jalan.
// SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY disediakan otomatis oleh Supabase.
import { createClient } from "npm:@supabase/supabase-js@2";
import nodemailer from "npm:nodemailer@6.9.16";
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

type EventName =
  | "report_approved"
  | "report_rejected"
  | "report_completed"
  | "claim_created"
  | "claim_approved"
  | "claim_rejected";

const EVENTS: EventName[] = [
  "report_approved",
  "report_rejected",
  "report_completed",
  "claim_created",
  "claim_approved",
  "claim_rejected",
];

type Mail = {
  recipient: string;
  reportId: number;
  claimId: number | null;
  subject: string;
  heading: string;
  lines: string[];
  note?: string | null;
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false } },
);

const escapeHtml = (s: string) =>
  s.replace(/[&<>"']/g, (ch) =>
    ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[ch]!)
  );

const jenis = (r: { jenis_laporan: string }) => (r.jenis_laporan === "temuan" ? "temuan" : "kehilangan");

async function loadReport(id: number) {
  const { data, error } = await db
    .from("reports")
    .select("id, id_user, jenis_laporan, nama_barang, lokasi, status, admin_notes, campus:campuses(nama_kampus)")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

/** Susun email sesuai event. Mengembalikan null bila data tidak lagi cocok dengan event. */
async function buildMail(event: EventName, id: number): Promise<Mail | null> {
  if (event.startsWith("report_")) {
    const r = await loadReport(id);
    const expected = event.replace("report_", "");
    if (!r || r.status !== expected) return null;
    const campus = (r.campus as { nama_kampus?: string } | null)?.nama_kampus ?? "kampus";
    const base = [`Barang: ${r.nama_barang}`, `Lokasi: ${r.lokasi} (${campus})`];
    if (event === "report_approved") {
      return {
        recipient: r.id_user,
        reportId: r.id,
        claimId: null,
        subject: `Laporan ${jenis(r)} "${r.nama_barang}" sudah disetujui`,
        heading: "Laporanmu sudah tayang",
        lines: [
          ...base,
          "Admin sudah memverifikasi laporanmu. Sekarang laporan bisa dilihat semua pengguna FindIT.",
        ],
        note: r.admin_notes,
      };
    }
    if (event === "report_rejected") {
      return {
        recipient: r.id_user,
        reportId: r.id,
        claimId: null,
        subject: `Laporan ${jenis(r)} "${r.nama_barang}" ditolak`,
        heading: "Laporanmu belum bisa ditayangkan",
        lines: [
          ...base,
          "Admin menolak laporan ini. Periksa catatan admin di bawah, lalu buat laporan baru bila perlu.",
        ],
        note: r.admin_notes,
      };
    }
    return {
      recipient: r.id_user,
      reportId: r.id,
      claimId: null,
      subject: `Laporan "${r.nama_barang}" selesai`,
      heading: "Barang sudah kembali ke pemiliknya",
      lines: [...base, "Laporan ini ditandai selesai. Terima kasih sudah memakai FindIT."],
      note: r.admin_notes,
    };
  }

  const { data: c, error } = await db
    .from("claims")
    .select("id, id_report, id_user, status_klaim, catatan_admin")
    .eq("id", id)
    .maybeSingle();
  if (error) throw error;
  if (!c) return null;
  const r = await loadReport(c.id_report);
  if (!r) return null;

  if (event === "claim_created") {
    if (c.id_user === r.id_user) return null;
    return {
      recipient: r.id_user,
      reportId: r.id,
      claimId: c.id,
      subject: `Ada klaim baru untuk "${r.nama_barang}"`,
      heading: "Seseorang mengklaim barang temuanmu",
      lines: [
        `Barang: ${r.nama_barang}`,
        "Admin akan memeriksa bukti kepemilikan sebelum serah terima. Kamu tidak perlu menghubungi pengklaim secara langsung.",
      ],
    };
  }

  const expected = event.replace("claim_", "");
  if (c.status_klaim !== expected) return null;
  if (event === "claim_approved") {
    return {
      recipient: c.id_user,
      reportId: r.id,
      claimId: c.id,
      subject: `Klaim "${r.nama_barang}" disetujui`,
      heading: "Klaimmu disetujui",
      lines: [
        `Barang: ${r.nama_barang}`,
        "Ambil barang di resepsionis atau pos keamanan kampus dengan membawa kartu identitas. Serah terima dicatat di Berita Acara.",
      ],
      note: c.catatan_admin,
    };
  }
  return {
    recipient: c.id_user,
    reportId: r.id,
    claimId: c.id,
    subject: `Klaim "${r.nama_barang}" ditolak`,
    heading: "Klaimmu belum bisa disetujui",
    lines: [
      `Barang: ${r.nama_barang}`,
      "Bukti kepemilikan belum cukup meyakinkan admin. Periksa catatan admin di bawah.",
    ],
    note: c.catatan_admin,
  };
}

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

let fcmToken: { value: string; expires: number } | null = null;

/** Access token OAuth untuk FCM HTTP v1, di-cache selama instance function hidup. */
async function fcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (fcmToken && fcmToken.expires - 60 > now) return fcmToken.value;
  const key = await importPKCS8(sa.private_key, "RS256");
  const assertion = await new SignJWT({ scope: "https://www.googleapis.com/auth/firebase.messaging" })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(sa.client_email)
    .setAudience("https://oauth2.googleapis.com/token")
    .setIssuedAt(now)
    .setExpirationTime(now + 3600)
    .sign(key);
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  if (!res.ok) throw new Error(`oauth ${res.status}: ${await res.text()}`);
  const body = await res.json();
  fcmToken = { value: body.access_token, expires: now + Number(body.expires_in ?? 3600) };
  return fcmToken.value;
}

/** Kirim push ke semua perangkat penerima. Token yang sudah mati dihapus. Tidak pernah melempar error. */
async function sendPush(mail: Mail, event: EventName) {
  const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
  if (!raw) return;
  try {
    const sa = JSON.parse(raw) as ServiceAccount;
    const { data: tokens, error } = await db
      .from("device_tokens")
      .select("token")
      .eq("user_id", mail.recipient);
    if (error) throw error;
    if (!tokens?.length) return;

    const access = await fcmAccessToken(sa);
    const url = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;
    await Promise.all(tokens.map(async ({ token }) => {
      const res = await fetch(url, {
        method: "POST",
        headers: { Authorization: `Bearer ${access}`, "Content-Type": "application/json" },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: mail.subject, body: mail.lines[mail.lines.length - 1] },
            data: {
              event,
              report_id: String(mail.reportId),
              claim_id: mail.claimId == null ? "" : String(mail.claimId),
            },
            android: { priority: "high", notification: { channel_id: "findit_updates" } },
          },
        }),
      });
      if (res.ok) return;
      const text = await res.text();
      // 404 UNREGISTERED / 400 INVALID_ARGUMENT pada token: aplikasi sudah dihapus atau token kedaluwarsa.
      if (res.status === 404 || (res.status === 400 && text.includes("registration token"))) {
        await db.from("device_tokens").delete().eq("token", token);
      } else {
        console.error(`fcm ${res.status}:`, text.slice(0, 300));
      }
    }));
  } catch (e) {
    console.error("push gagal:", e instanceof Error ? e.message : String(e));
  }
}

function renderHtml(name: string, mail: Mail) {
  const rows = mail.lines.map((l) => `<p style="margin:0 0 12px">${escapeHtml(l)}</p>`).join("");
  const note = mail.note
    ? `<div style="margin:16px 0;padding:12px 16px;background:#F7F8FA;border-radius:12px">
         <p style="margin:0 0 4px;font-size:12px;color:#475569">Catatan admin</p>
         <p style="margin:0">${escapeHtml(mail.note)}</p></div>`
    : "";
  return `<!doctype html><html lang="id"><body style="margin:0;background:#F7F8FA;font-family:Arial,sans-serif;color:#0F172A">
  <div style="max-width:520px;margin:0 auto;padding:32px 16px">
    <div style="background:#FFFFFF;border:1px solid #E8EAEE;border-radius:16px;padding:24px">
      <p style="margin:0 0 16px;font-size:13px;color:#475569">FindIT · Lost &amp; Found Kampus UBSI</p>
      <h1 style="margin:0 0 16px;font-size:20px">${escapeHtml(mail.heading)}</h1>
      <p style="margin:0 0 12px">Halo ${escapeHtml(name)},</p>
      ${rows}${note}
      <p style="margin:16px 0 0;font-size:13px;color:#475569">Buka aplikasi FindIT untuk detail lengkap.</p>
    </div>
    <p style="margin:16px 0 0;font-size:12px;color:#64708A;text-align:center">
      Kamu menerima email ini karena notifikasi email aktif di Profil FindIT. Matikan lewat Profil &gt; Notifikasi Email.
    </p>
  </div></body></html>`;
}

function renderText(name: string, mail: Mail) {
  return [
    `Halo ${name},`,
    "",
    mail.heading,
    ...mail.lines,
    mail.note ? `\nCatatan admin: ${mail.note}` : "",
    "",
    "Matikan notifikasi email lewat Profil > Notifikasi Email di aplikasi FindIT.",
  ].join("\n");
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const secret = req.headers.get("x-findit-secret") ?? "";
  const { data: ok, error: secretErr } = await db.rpc("verify_notify_secret", { p_secret: secret });
  if (secretErr || ok !== true) return json({ error: "unauthorized" }, 401);

  let body: { event?: string; id?: number };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid json" }, 400);
  }
  const event = body.event as EventName;
  const id = Number(body.id);
  if (!EVENTS.includes(event) || !Number.isInteger(id)) {
    return json({ error: "invalid payload" }, 400);
  }

  const mail = await buildMail(event, id);
  if (!mail) return json({ skipped: "data tidak cocok dengan event" });

  // Notifikasi di dalam app selalu dibuat, terlepas dari pengaturan email.
  const { data: inApp, error: inAppErr } = await db.from("app_notifications").upsert(
    {
      user_id: mail.recipient,
      event,
      report_id: mail.reportId,
      claim_id: mail.claimId,
      title: mail.subject,
      body: mail.lines[mail.lines.length - 1],
    },
    { onConflict: "user_id,event,report_id,claim_id", ignoreDuplicates: true },
  ).select("id");
  if (inAppErr) console.error("app_notifications gagal:", inAppErr.message);
  // Baris baru berarti event ini belum pernah diproses; push hanya sekali per event.
  if (inApp?.length) await sendPush(mail, event);

  const { data: profile } = await db
    .from("profiles")
    .select("id, name, email, email_notifications")
    .eq("id", mail.recipient)
    .maybeSingle();
  if (!profile?.email) return json({ skipped: "penerima tanpa email" });

  // Klaim baris log; bila sudah ada, event ini pernah diproses (retry / panggilan ganda).
  const { data: log, error: logErr } = await db
    .from("email_notifications")
    .insert({
      event,
      ref_id: id,
      recipient: profile.id,
      recipient_email: profile.email,
      status: profile.email_notifications ? "pending" : "skipped",
      error: profile.email_notifications ? null : "dimatikan pengguna",
    })
    .select("id")
    .maybeSingle();
  if (logErr) {
    if (logErr.code === "23505") return json({ skipped: "sudah dikirim" });
    throw logErr;
  }
  if (!profile.email_notifications) return json({ skipped: "dimatikan pengguna" });

  const user = Deno.env.get("GMAIL_USER");
  const pass = Deno.env.get("GMAIL_APP_PASSWORD");
  if (!user || !pass) {
    await db.from("email_notifications")
      .update({ status: "failed", error: "GMAIL_USER / GMAIL_APP_PASSWORD belum diisi" })
      .eq("id", log!.id);
    return json({ error: "smtp belum dikonfigurasi" }, 500);
  }

  try {
    // Port 587 diblokir di Edge Functions; pakai 465 (TLS langsung).
    const transport = nodemailer.createTransport({
      host: "smtp.gmail.com",
      port: 465,
      secure: true,
      auth: { user, pass },
    });
    const name = profile.name || "Sobat FindIT";
    await transport.sendMail({
      from: `"FindIT UBSI" <${user}>`,
      to: profile.email,
      subject: mail.subject,
      text: renderText(name, mail),
      html: renderHtml(name, mail),
    });
    await db.from("email_notifications")
      .update({ status: "sent", sent_at: new Date().toISOString() })
      .eq("id", log!.id);
    return json({ sent: true });
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    console.error("notify-email gagal kirim:", message);
    await db.from("email_notifications")
      .update({ status: "failed", error: message.slice(0, 500) })
      .eq("id", log!.id);
    return json({ error: "gagal kirim email" }, 502);
  }
});
