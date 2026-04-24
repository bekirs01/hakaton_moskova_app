#!/usr/bin/env bash
# Kullanıcı (OAuth) access token: VK, topluluk token'ı ile foto yükletmez.
# Kullanım: proje kökünde .env içine VK_APP_ID=UygulamaID yaz, sonra: ./setup_vk_user_token.sh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${ROOT}/.env"
if [[ ! -f "$ENV_FILE" ]]; then
  echo "Bulunamadı: $ENV_FILE" >&2
  exit 1
fi
# Basit ayrıştırma: VK_APP_ID= değer (tırnaksız sayı)
RAW="$(grep -E '^VK_APP_ID=' "$ENV_FILE" 2>/dev/null | head -1 || true)"
Val="${RAW#VK_APP_ID=}"
Val="${Val%$'\r'}"
Val="$(echo -n "$Val" | tr -d ' ')"
if [[ -z "$Val" ]]; then
  echo "VK_APP_ID boş. vk.com / dev bölgesinde uygulamanı aç, ayarlardaki uygulama (client) id'yi al." >&2
  echo "Sonra $ENV_FILE içine ekleyin: VK_APP_ID=123456789" >&2
  exit 1
fi
# VK uygulama ayarlarına \"İzin verilen redirect\": https://oauth.vk.com/blank.html ekli olmalı
SCOPE="wall,photos,video,groups,offline"
REPLY="https%3A%2F%2Foauth.vk.com%2Fblank.html"
Url="https://oauth.vk.com/authorize?client_id=${Val}&display=page&redirect_uri=${REPLY}&scope=${SCOPE}&response_type=token&v=5.199&revoke=1"
echo ""
echo "Aşağıdaki adresi aç, VK'ya giriş yap, izin ver. Yönlendirmede tarayıcı adres çubuğunda:"
echo "  ...#access_token=vk1.XXXX&expires_in=...&user_id=..."
echo "içindeki access_token= sonrası değeri ( & öncesine kadar) kopyala."
echo ""
echo "→ .env dosyasına: VK_USER_ACCESS_TOKEN=<yapıştırdığın token>"
echo "  Uygulamayı (Flutter) tam yeniden çalıştır."
echo ""
echo "Oturum linki:"
echo "$Url"
echo ""
if command -v open &>/dev/null; then
  open "$Url"
  echo "Tarayıcı açıldı. İzin verince adres çubuğundaki #access_token= değerini kopyala."
fi
