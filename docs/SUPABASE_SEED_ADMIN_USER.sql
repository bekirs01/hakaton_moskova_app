-- MemeOps demo kullanıcısı (Flutter: kullanıcı adı admin, şifre 12345678)
-- Supabase Dashboard → SQL Editor → Run
--
-- ÖNEMLİ: SQL ile eklenen auth.users satırında bazı token alanları NULL kalırsa,
-- girişte GoTrue "Database error querying schema" döner (NULL → string scan hatası).
-- Bu dosya boş string ('') yazar; aşağıdaki FIX bloğu eski kayıtları da onarır.
--
-- Not: auth.users + auth.identities birlikte gerekir.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- FIX: SQL ile eklenmiş kullanıcılarda token NULL ise giriş patlar — boş string yap
-- ---------------------------------------------------------------------------
update auth.users
set
  confirmation_token = coalesce(confirmation_token, ''),
  recovery_token = coalesce(recovery_token, ''),
  email_change = coalesce(email_change, ''),
  email_change_token_new = coalesce(email_change_token_new, '')
where
  confirmation_token is null
  or recovery_token is null
  or email_change is null
  or email_change_token_new is null;

do $$
declare
  v_email text := 'admin@memeops.local';
  v_password text := '12345678';
  v_id uuid := gen_random_uuid();
  v_instance uuid;
begin
  select id into v_instance from auth.instances limit 1;
  if v_instance is null then
    v_instance := '00000000-0000-0000-0000-000000000000'::uuid;
  end if;

  if exists (select 1 from auth.users where email = v_email) then
    raise notice 'Kullanıcı zaten var (token alanları yukarıdaki UPDATE ile düzeltildi): %', v_email;
    return;
  end if;

  insert into auth.users (
    instance_id,
    id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    recovery_sent_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at,
    confirmation_token,
    email_change,
    email_change_token_new,
    recovery_token
  ) values (
    v_instance,
    v_id,
    'authenticated',
    'authenticated',
    v_email,
    crypt(v_password, gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"display_name":"admin"}'::jsonb,
    now(),
    now(),
    '',
    '',
    '',
    ''
  );

  insert into auth.identities (
    id,
    user_id,
    provider_id,
    identity_data,
    provider,
    last_sign_in_at,
    created_at,
    updated_at
  ) values (
    gen_random_uuid(),
    v_id,
    v_id::text,
    jsonb_build_object('sub', v_id::text, 'email', v_email),
    'email',
    now(),
    now(),
    now()
  );

  raise notice 'Oluşturuldu: % (uygulamada kullanıcı adı: admin)', v_email;
end $$;
