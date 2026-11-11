-- Adds a building photo URL to campuses, shown in the branch picker.
alter table public.campuses add column if not exists foto_url text;
comment on column public.campuses.foto_url is 'Public URL of the campus building photo, shown in the branch picker.';
