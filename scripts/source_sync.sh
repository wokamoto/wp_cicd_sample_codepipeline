#!/usr/bin/env bash
# scripts/source_sync.sh (方式A: artifact に web/ を展開)
set -euo pipefail

DEST_DIR="/var/www/html"
RELEASES_DIR="$DEST_DIR/releases"
CURRENT_LINK="$DEST_DIR/current"
SRC_DIR="$PWD/dest"
NGINX_USER="nginx"
NGINX_GROUP="www-data"

# ここに wp-config.php を追加
EXCLUDES=(
  "--exclude" "wp-content/uploads/"
  "--exclude" "wp-config.php"
)

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

ensure_rsync() {
  if ! command -v rsync >/dev/null 2>&1; then
    log "rsync not found. Installing..."
    if command -v dnf >/dev/null 2>&1; then dnf -y install rsync >/dev/null
    elif command -v yum >/dev/null 2>&1; then yum -y install rsync >/dev/null
    else log "No package manager found to install rsync."; exit 1; fi
  fi
}

[[ -d "$SRC_DIR" ]] || { log "Source not found: $SRC_DIR"; exit 1; }
mkdir -p "$RELEASES_DIR"
TIMESTAMP="$(date '+%Y%m%d%H%M%S')"
RELEASE_DIR="$RELEASES_DIR/$TIMESTAMP"
mkdir -p "$RELEASE_DIR"

ensure_rsync
log "Syncing files from $SRC_DIR to $RELEASE_DIR ..."
# SRC_DIR の末尾スラッシュで中身のみコピー
rsync -a --delete "${EXCLUDES[@]}" "$SRC_DIR/" "$RELEASE_DIR/"

# uploads を引き継ぎ（任意）
if [[ -d "$CURRENT_LINK/wp-content/uploads" ]]; then
  mkdir -p "$RELEASE_DIR/wp-content/uploads"
  rsync -a "$CURRENT_LINK/wp-content/uploads/" "$RELEASE_DIR/wp-content/uploads/" || true
else
  mkdir -p "$RELEASE_DIR/wp-content/uploads"
fi

# ★ 既存の wp-config.php を引き継ぐ（除外しているため明示的にコピー）
if [[ -f "$CURRENT_LINK/wp-config.php" ]]; then
  cp -a "$CURRENT_LINK/wp-config.php" "$RELEASE_DIR/wp-config.php"
fi

chown -R "${NGINX_USER}:${NGINX_GROUP}" "$RELEASE_DIR"

log "Updating symlink: $CURRENT_LINK -> $RELEASE_DIR"
ln -sfn "$RELEASE_DIR" "$CURRENT_LINK"

log "Done. Active release: $RELEASE_DIR"
# サービスの reload/restart は ApplicationStart 等で実施推奨