// FindBot: asisten FindIT. Port dari ChatbotController Laravel.
// Memakai Gemini bila secret GEMINI_API_KEY diisi; tanpa itu (atau saat Gemini gagal) membalas dengan template lokal.
// Data dibaca dengan anon key sehingga tetap tunduk pada RLS: hanya laporan approved/completed yang terlihat.
import { createClient } from "npm:@supabase/supabase-js@2";

type Action = { label: string; url: string } | null;
type QuickReply = { label: string; value: string };
type Reply = { reply: string; action: Action; quickReplies: QuickReply[] };

// URL aksi dibaca app mobile (ChatbotView._handleAction), bukan route web.
const ACTION_CREATE_REPORT = "findit://create-report";
const ACTION_MY_CLAIMS = "findit://my-claims";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

const DEFAULT_QUICK_REPLIES: QuickReply[] = [
  { label: "📦 Barang Temuan", value: "barang temuan terbaru" },
  { label: "🔍 Barang Hilang", value: "barang hilang terbaru" },
  { label: "📊 Statistik", value: "statistik findit" },
  { label: "📁 Kategori", value: "kategori barang" },
];

type Stats = {
  totalTemuan: number;
  totalHilang: number;
  totalSelesai: number;
  categories: string;
  temuanTerbaru: string;
  hilangTerbaru: string;
};

async function loadStats(authHeader: string | null): Promise<Stats> {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: authHeader ? { Authorization: authHeader } : {} } },
  );

  const count = (jenis: string | null, status: string) => {
    let q = supabase.from("reports").select("id", { count: "exact", head: true }).eq("status", status);
    if (jenis) q = q.eq("jenis_laporan", jenis);
    return q;
  };
  const latest = (jenis: string) =>
    supabase
      .from("reports")
      .select("nama_barang, lokasi, category:categories(nama_category)")
      .eq("jenis_laporan", jenis)
      .eq("status", "approved")
      .order("created_at", { ascending: false })
      .limit(5);

  const [temuan, hilang, selesai, cats, temuanList, hilangList] = await Promise.all([
    count("temuan", "approved"),
    count("hilang", "approved"),
    count(null, "completed"),
    supabase.from("categories").select("nama_category").order("id"),
    latest("temuan"),
    latest("hilang"),
  ]);

  // deno-lint-ignore no-explicit-any
  const formatList = (rows: any[] | null) =>
    (rows ?? [])
      .map((r) => `- ${r.nama_barang} (${r.category?.nama_category ?? "Tanpa kategori"}) di ${r.lokasi}`)
      .join("\n");

  return {
    totalTemuan: temuan.count ?? 0,
    totalHilang: hilang.count ?? 0,
    totalSelesai: selesai.count ?? 0,
    categories: (cats.data ?? []).map((c) => c.nama_category).join(", "),
    temuanTerbaru: formatList(temuanList.data),
    hilangTerbaru: formatList(hilangList.data),
  };
}

function systemPrompt(s: Stats): string {
  return `Kamu adalah asisten virtual FindIt, sistem Lost & Found kampus BSI.
Tugasmu membantu mahasiswa menemukan informasi barang hilang dan temuan di kampus.

DATA TERKINI:
- Barang temuan aktif: ${s.totalTemuan} item
- Barang hilang aktif: ${s.totalHilang} item
- Berhasil dikembalikan: ${s.totalSelesai} item
- Kategori tersedia: ${s.categories}

BARANG TEMUAN TERBARU:
${s.temuanTerbaru}

BARANG HILANG TERBARU:
${s.hilangTerbaru}

PANDUAN MENJAWAB:
- Jawab dalam Bahasa Indonesia yang ramah dan singkat
- Maksimal 3-4 kalimat per jawaban
- Jika ditanya barang spesifik, arahkan ke menu pencarian di aplikasi
- Jika tidak ada info, sarankan buat laporan atau hubungi admin
- Jangan membuat informasi yang tidak ada di data di atas
- Jika pertanyaan di luar konteks FindIt, arahkan kembali ke fitur aplikasi FindIt`;
}

async function askGemini(prompt: string, message: string): Promise<string | null> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return null;
  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash";

  try {
    const res = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: prompt }] },
          contents: [{ role: "user", parts: [{ text: message }] }],
          generationConfig: { temperature: 0.7, maxOutputTokens: 300 },
        }),
        signal: AbortSignal.timeout(20_000),
      },
    );
    if (!res.ok) {
      console.error("Gemini error", res.status, await res.text());
      return null;
    }
    const data = await res.json();
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
    return typeof text === "string" && text.trim() ? text.trim() : null;
  } catch (e) {
    console.error("Gemini request failed", e);
    return null;
  }
}

const containsAny = (text: string, keywords: string[]) => keywords.some((k) => text.includes(k));
// Sapaan pendek ("hi", "ok") harus utuh satu kata, kalau tidak "hilang" terbaca sebagai "hi".
const containsWord = (text: string, words: string[]) =>
  words.some((w) => new RegExp(`(^|[^a-z])${w}([^a-z]|$)`).test(text));

function detectAction(m: string): Action {
  if (containsAny(m, ["buat laporan", "lapor barang", "melaporkan barang"])) {
    return { label: "Buat Laporan", url: ACTION_CREATE_REPORT };
  }
  if (containsAny(m, ["klaim saya", "cek klaim saya"])) {
    return { label: "Klaim Saya", url: ACTION_MY_CLAIMS };
  }
  return null;
}

function localReply(m: string, s: Stats): Reply {
  const has = (t: string[]) => containsAny(m, t);
  const q = DEFAULT_QUICK_REPLIES;

  if (has(["assalam"]) || containsWord(m, ["halo", "hi", "hai", "hey", "pagi", "siang", "sore", "malam", "selamat"])) {
    return {
      reply: "Halo! 👋 Selamat datang di FindIt!\n\nSaya siap membantu kamu menemukan info barang hilang & temuan di kampus.\n\nSilakan pilih atau ketik pertanyaanmu!",
      action: null,
      quickReplies: q,
    };
  }
  if (containsWord(m, ["terima kasih", "thanks", "thx", "makasih", "okeh", "oke", "ok"])) {
    return {
      reply: "Sama-sama! 😊 Semoga barangmu segera ketemu. Kalau butuh bantuan lagi, jangan ragu untuk bertanya ya!",
      action: null,
      quickReplies: q,
    };
  }
  if (has(["bantu", "tolong", "bantuan", "help"])) {
    return {
      reply: "Tentu, saya siap membantu! 🙌\n\nSaya bisa bantu kamu untuk:\n• 🔍 Mencari info barang hilang/temuan\n• 📊 Melihat statistik FindIt\n• 📁 Mengetahui kategori barang\n• 📝 Cara membuat laporan\n• 🎁 Cara klaim barang temuan\n\nSilakan pilih atau ketik pertanyaanmu!",
      action: null,
      quickReplies: q,
    };
  }
  if (has(["temuan", "menemukan", "ditemukan"])) {
    if (s.totalTemuan > 0) {
      return {
        reply: `📦 Saat ini ada ${s.totalTemuan} barang temuan di kampus!\n\nBerikut barang temuan terbaru:\n${s.temuanTerbaru}`,
        action: null,
        quickReplies: [
          { label: "🔍 Barang Hilang", value: "barang hilang terbaru" },
          { label: "📝 Buat Laporan", value: "cara buat laporan" },
          { label: "📊 Statistik", value: "statistik findit" },
        ],
      };
    }
    return {
      reply: "😔 Belum ada barang temuan yang dilaporkan saat ini.\n\nTapi kalau kamu menemukan barang, segera laporkan ya! 😊",
      action: { label: "Buat Laporan", url: ACTION_CREATE_REPORT },
      quickReplies: q,
    };
  }
  if (has(["hilang", "kehilangan", "dicari", "mencari"])) {
    if (s.totalHilang > 0) {
      return {
        reply: `🔍 Saat ini ada ${s.totalHilang} laporan barang hilang di kampus.\n\nBerikut barang hilang terbaru:\n${s.hilangTerbaru}`,
        action: null,
        quickReplies: [
          { label: "📦 Barang Temuan", value: "barang temuan terbaru" },
          { label: "📝 Buat Laporan", value: "cara buat laporan" },
          { label: "📊 Statistik", value: "statistik findit" },
        ],
      };
    }
    return {
      reply: "😊 Kabar baiknya, belum ada laporan barang hilang saat ini!\n\nKalau barangmu hilang, segera buat laporan ya!",
      action: { label: "Buat Laporan", url: ACTION_CREATE_REPORT },
      quickReplies: q,
    };
  }
  if (has(["cari", "search", "ketemu"])) {
    return {
      reply: "🔎 Untuk mencari barang, kamu bisa:\n\n1️⃣ Buka tab Cari di aplikasi\n2️⃣ Gunakan kata kunci atau filter\n3️⃣ Pilih kategori dan kampus yang sesuai\n\nAtau tanya saya langsung, misalnya \"barang temuan terbaru\".",
      action: null,
      quickReplies: q,
    };
  }
  if (has(["statistik", "jumlah", "berapa", "total", "info"])) {
    const penutup = s.totalSelesai > 0
      ? `🎉 Sudah ada ${s.totalSelesai} barang yang berhasil dikembalikan ke pemiliknya!`
      : "Ayo bantu sesama mahasiswa dengan melaporkan barang temuan!";
    return {
      reply: `📊 Statistik FindIt\n\n📦 Barang Temuan: ${s.totalTemuan} item\n🔍 Barang Hilang: ${s.totalHilang} item\n✅ Berhasil Dikembalikan: ${s.totalSelesai} item\n\n${penutup}`,
      action: null,
      quickReplies: q,
    };
  }
  if (has(["kategori", "jenis", "tipe", "macam"])) {
    return {
      reply: s.categories
        ? `📁 Kategori Barang\n\nSaat ini tersedia: ${s.categories}\n\nKamu bisa filter barang berdasarkan kategori di tab Cari!`
        : "Saat ini belum ada kategori yang tersedia.",
      action: null,
      quickReplies: q,
    };
  }
  // Dicek sebelum "cara lapor": chip "Cara Klaim" juga mengandung kata "cara".
  if (has(["klaim", "claim", "ambil", "dapatkan"])) {
    return {
      reply: "🎁 Cara Klaim Barang Temuan\n\n1️⃣ Buka detail barang temuan\n2️⃣ Ketuk \"Klaim Barang Ini\"\n3️⃣ Jelaskan ciri spesifik barang sebagai bukti kepemilikan\n4️⃣ Kirim klaim\n\nAdmin akan memverifikasi klaimmu, lalu barang diambil di pos keamanan kampus.",
      action: { label: "Klaim Saya", url: ACTION_MY_CLAIMS },
      quickReplies: [
        { label: "📦 Barang Temuan", value: "barang temuan terbaru" },
        { label: "📝 Buat Laporan", value: "cara buat laporan" },
        { label: "📊 Statistik", value: "statistik findit" },
      ],
    };
  }
  if (has(["cara", "lapor", "report", "bagaimana"])) {
    return {
      reply: "📝 Cara Membuat Laporan\n\n1️⃣ Masuk ke akun FindIt kamu\n2️⃣ Ketuk tombol Lapor\n3️⃣ Pilih jenis: Hilang atau Temuan\n4️⃣ Isi nama barang, kategori, lokasi, tanggal, dan deskripsi\n5️⃣ Tambahkan foto (jika ada)\n6️⃣ Kirim laporan\n\nLaporanmu akan diverifikasi admin sebelum dipublikasikan.",
      action: { label: "Buat Laporan Sekarang", url: ACTION_CREATE_REPORT },
      quickReplies: [
        { label: "📦 Barang Temuan", value: "barang temuan terbaru" },
        { label: "🔍 Barang Hilang", value: "barang hilang terbaru" },
        { label: "🎁 Cara Klaim", value: "cara klaim barang" },
      ],
    };
  }
  return {
    reply: `👋 Halo! Saya asisten FindIt\n\n📦 Barang Temuan: ${s.totalTemuan} item\n🔍 Barang Hilang: ${s.totalHilang} item\n✅ Dikembalikan: ${s.totalSelesai} item\n\nSilakan pilih opsi di bawah atau ketik pertanyaanmu!`,
    action: null,
    quickReplies: q,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  let message = "";
  try {
    const body = await req.json();
    message = typeof body?.message === "string" ? body.message.trim() : "";
  } catch {
    return json({ error: "Body harus JSON" }, 400);
  }
  if (!message || message.length > 500) {
    return json({ error: "Pesan wajib diisi, maksimal 500 karakter" }, 422);
  }

  const lower = message.toLowerCase();
  const stats = await loadStats(req.headers.get("Authorization"));

  const aiReply = await askGemini(systemPrompt(stats), message);
  if (aiReply) {
    return json({ reply: aiReply, action: detectAction(lower), quickReplies: [] });
  }
  return json(localReply(lower, stats));
});
