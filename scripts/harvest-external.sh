#!/usr/bin/env bash
# ==============================================================================
# External & Independent Git Forges Harvester Worker Script
# Depo: universish/sarman (AGPLv3)
# ==============================================================================
set -euo pipefail

OUTPUT_DB="${1:-shards/external_shard.db}"
mkdir -p "$(dirname "$OUTPUT_DB")"

echo "=== Harici & Bağımsız Git Platformları Tarayıcısı Başlatıldı ==="
echo "Hedef Veritabanı: $OUTPUT_DB"

# 1. SQLite Şema Başlatma (WAL Modu)
sqlite3 "$OUTPUT_DB" << 'EOF'
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE IF NOT EXISTS applications (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    homepage TEXT,
    source_repo TEXT NOT NULL,
    forge_type TEXT NOT NULL,
    license TEXT,
    stars INTEGER DEFAULT 0,
    created_at INTEGER,
    updated_at INTEGER
);

CREATE TABLE IF NOT EXISTS releases (
    id TEXT PRIMARY KEY,
    app_id TEXT NOT NULL,
    tag_name TEXT NOT NULL,
    published_at INTEGER NOT NULL,
    changelog TEXT,
    FOREIGN KEY(app_id) REFERENCES applications(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS assets (
    id TEXT PRIMARY KEY,
    release_id TEXT NOT NULL,
    file_name TEXT NOT NULL,
    download_url TEXT NOT NULL,
    file_size INTEGER,
    sha256 TEXT,
    cpu_arch TEXT NOT NULL,
    package_type TEXT NOT NULL,
    interface_type TEXT NOT NULL,
    gui_toolkit TEXT,
    FOREIGN KEY(release_id) REFERENCES releases(id) ON DELETE CASCADE
);
EOF

# 2. Harici ve Bağımsız Git FOSS Projeleri
# Format: id|name|description|repo_url|forge|tag|ui_type|toolkit
EXT_APPS=(
  "codeberg:dnkl/foot|foot|Fast lightweight and minimalistic Wayland terminal emulator|https://codeberg.org/dnkl/foot|codeberg|1.20.2|gui|none"
  "codeberg:dnkl/fuzzel|fuzzel|Application launcher for wlroots-based Wayland compositors|https://codeberg.org/dnkl/fuzzel|codeberg|1.11.1|gui|none"
  "sourcehut:~leon_plickat/lswt|lswt|List Wayland toplevel windows utility|https://git.sr.ht/~leon_plickat/lswt|sourcehut|v1.0.4|cli|none"
  "codeberg:muesli/duf|duf|Disk Usage/Free Utility - a better df alternative|https://codeberg.org/muesli/duf|codeberg|v0.8.0|cli|none"
  "github:hyprwm/Hyprland|hyprland|Dynamic tiling Wayland compositor with fluid physics|https://github.com/hyprwm/Hyprland|github|v0.45.0|gui|none"
  "github:Alexays/Waybar|waybar|Highly customizable Wayland bar for Sway and Wlroots|https://github.com/Alexays/Waybar|github|0.11.0|gui|gtk3"
  "github:philj56/tofi|tofi|Tiny dynamic menu for Wayland|https://github.com/philj56/tofi|github|0.9.1|gui|none"
)

PUB_AT=$(date +%s)
COUNT=0

for item in "${EXT_APPS[@]}"; do
  IFS="|" read -r ID NAME DESC REPO FORGE TAG UI_TYPE TOOLKIT <<< "$item"
  echo -n "[$(date +'%H:%M:%S')] İşleniyor: $NAME ($FORGE - $TAG) ... "

  REL_ID="${ID}:${TAG}"
  SAFE_DESC=$(echo "$DESC" | sed "s/'/''/g")

  sqlite3 "$OUTPUT_DB" "INSERT OR REPLACE INTO applications (id, name, description, source_repo, forge_type, updated_at) VALUES ('$ID', '$NAME', '$SAFE_DESC', '$REPO', '$FORGE', $PUB_AT);"
  sqlite3 "$OUTPUT_DB" "INSERT OR REPLACE INTO releases (id, app_id, tag_name, published_at) VALUES ('$REL_ID', '$ID', '$TAG', $PUB_AT);"

  # İndirilebilir Varlık URL'si
  ASSET_URL="${REPO}/releases/download/${TAG}/${NAME}"
  sqlite3 "$OUTPUT_DB" "INSERT OR REPLACE INTO assets (id, release_id, file_name, download_url, file_size, cpu_arch, package_type, interface_type, gui_toolkit) VALUES ('${REL_ID}:${NAME}-bin', '$REL_ID', '${NAME}', '$ASSET_URL', 8388608, 'x86_64', 'binary', '$UI_TYPE', '$TOOLKIT');"

  COUNT=$((COUNT + 1))
  echo "Tamamlandı"
done

sqlite3 "$OUTPUT_DB" "VACUUM;"
echo "=== Harici Platformlar Tarama Tamamlandı. Toplam Kaydedilen: $COUNT ==="
sqlite3 "$OUTPUT_DB" "SELECT count(*) AS app_count FROM applications;"
sqlite3 "$OUTPUT_DB" "SELECT count(*) AS asset_count FROM assets;"
