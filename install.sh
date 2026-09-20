#!/usr/bin/env bash
#
# install.sh — Installa Neovim con la configurazione Omarchy (omarchy-nvim)
#
# Cosa fa:
#   1. Installa Neovim (user-local, senza sudo) in ~/.local
#   2. Installa ripgrep e fd (necessari a LazyVim) in ~/.local/bin
#   3. Installa il font JetBrainsMono Nerd Font (icone di LazyVim)
#   4. Copia la config Omarchy in ~/.config/nvim
#   5. Estrae la cache dei plugin pre-clonati dal pacchetto ufficiale
#      omarchy-nvim (nessun download di plugin alla prima esecuzione)
#   6. Aggiunge l'alias `n` e il PATH a ~/.zshrc e ~/.bashrc
#   7. Imposta Neovim come editor predefinito per i file di testo
#   8. Sincronizza i plugin con Lazy
#
# Architetture supportate: x86_64 e aarch64 (Raspberry Pi 4 con OS a 64 bit)
#
# Opzioni:
#   --refresh    Sovrascrive config/dati esistenti (backup automatico)
#   --skip-font  Non installa il Nerd Font
#   --skip-data  Non estrae la cache plugin dal pacchetto .zst
#
# Versioni (modificabili via variabili d'ambiente):
#   NVIM_VERSION  (default v0.12.5)
#   RG_VERSION    (default 15.2.0)
#   FD_VERSION    (default v10.5.0)

set -euo pipefail

# ---------- variabili ----------
NVIM_VERSION="${NVIM_VERSION:-v0.12.5}"
RG_VERSION="${RG_VERSION:-15.2.0}"
FD_VERSION="${FD_VERSION:-v10.5.0}"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_TARBALL="$KIT_DIR/omarchy-nvim-2026.8.13-1-any.pkg.tar.zst"
CONFIG_SRC="$KIT_DIR/config"

BIN_DIR="$HOME/.local/bin"
NVIM_DIR="$HOME/.local/nvim"
FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"

REFRESH=false
SKIP_FONT=false
SKIP_DATA=false

# ---------- helper ----------
info() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32mOK\033[0m  %s\n' "$*"; }
skip() { printf '\033[1;33m--\033[0m  %s\n' "$*"; }
die()  { printf '\033[1;31mERRORE:\033[0m %s\n' "$*" >&2; exit 1; }

backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local backup="${path}.backup.$(date +%Y%m%d-%H%M%S)"
    info "Backup di $path -> $backup"
    mv "$path" "$backup"
  fi
}

download() {
  # download <url> <dest>
  info "Scarico: $1"
  curl -fsSL --retry 3 "$1" -o "$2"
}

# ---------- architettura ----------
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)
    NVIM_ARCH="x86_64"
    RG_TARGET="x86_64-unknown-linux-musl"
    FD_TARGET="x86_64-unknown-linux-musl"
    ;;
  aarch64|arm64)
    NVIM_ARCH="arm64"
    RG_TARGET="aarch64-unknown-linux-musl"
    FD_TARGET="aarch64-unknown-linux-musl"
    ;;
  *)
    die "Architettura non supportata: $ARCH. Supportate: x86_64 e aarch64 (Raspberry Pi 4 con OS a 64 bit)."
    ;;
esac

NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-${NVIM_ARCH}.tar.gz"
NVIM_TAR_DIR="nvim-linux-${NVIM_ARCH}"
RG_URL="https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep-${RG_VERSION}-${RG_TARGET}.tar.gz"
RG_TAR_DIR="ripgrep-${RG_VERSION}-${RG_TARGET}"
FD_URL="https://github.com/sharkdp/fd/releases/download/${FD_VERSION}/fd-${FD_VERSION}-${FD_TARGET}.tar.gz"
FD_TAR_DIR="fd-${FD_VERSION}-${FD_TARGET}"

# ---------- parse argomenti ----------
for arg in "$@"; do
  case "$arg" in
    --refresh)   REFRESH=true ;;
    --skip-font) SKIP_FONT=true ;;
    --skip-data) SKIP_DATA=true ;;
    -h|--help)
      cat <<'HELP'
Uso: ./install.sh [opzioni]

Installa Neovim con la configurazione Omarchy (omarchy-nvim) in user-space.

Opzioni:
  --refresh    Sovrascrive config/dati esistenti (backup automatico)
  --skip-font  Non installa il Nerd Font
  --skip-data  Non estrae la cache plugin dal pacchetto .zst
  -h, --help   Mostra questo aiuto

Versioni modificabili via variabili d'ambiente:
  NVIM_VERSION (default v0.12.5)  RG_VERSION (default 15.2.0)  FD_VERSION (default v10.5.0)

Architetture supportate: x86_64, aarch64 (Raspberry Pi 4 con OS a 64 bit)
HELP
      exit 0
      ;;
    *)
      die "Opzione sconosciuta: $arg (usa --help)"
      ;;
  esac
done

# ---------- no sudo ----------
if [[ $EUID -eq 0 ]]; then
  die "Non eseguire con sudo/root: il kit installa in user-space (~/.local e ~/.config). Esegui: ./install.sh (come utente normale)."
fi

echo
info "Kit Omarchy Neovim — installazione in corso (architettura: $ARCH)"
echo

# ---------- 1. Neovim ----------
if [[ -x "$BIN_DIR/nvim" && $REFRESH != true ]]; then
  ok "Neovim già installato: $($BIN_DIR/nvim --version | head -1)"
else
  info "Installazione Neovim $NVIM_VERSION (user-local, $ARCH)"
  tmp="$(mktemp -d)"
  mkdir -p "$BIN_DIR"
  download "$NVIM_URL" "$tmp/nvim.tar.gz"
  tar -xzf "$tmp/nvim.tar.gz" -C "$tmp"
  [[ -d "$NVIM_DIR" ]] && backup_path "$NVIM_DIR"
  mv "$tmp/$NVIM_TAR_DIR" "$NVIM_DIR"
  ln -sf "$NVIM_DIR/bin/nvim" "$BIN_DIR/nvim"
  rm -rf "$tmp"
  "$BIN_DIR/nvim" --version >/dev/null 2>&1 || die "Neovim installato ma non eseguibile (architettura $ARCH)."
  ok "Neovim installato: $($BIN_DIR/nvim --version | head -1)"
fi

# ---------- 2. ripgrep ----------
if [[ -x "$BIN_DIR/rg" && $REFRESH != true ]]; then
  ok "ripgrep già presente"
else
  info "Installazione ripgrep $RG_VERSION ($ARCH)"
  tmp="$(mktemp -d)"
  download "$RG_URL" "$tmp/rg.tar.gz"
  tar -xzf "$tmp/rg.tar.gz" -C "$tmp"
  mkdir -p "$BIN_DIR"
  install -m 0755 "$tmp/$RG_TAR_DIR/rg" "$BIN_DIR/rg"
  rm -rf "$tmp"
  ok "ripgrep installato"
fi

# ---------- 3. fd ----------
if [[ -x "$BIN_DIR/fd" && $REFRESH != true ]]; then
  ok "fd già presente"
else
  info "Installazione fd $FD_VERSION ($ARCH)"
  tmp="$(mktemp -d)"
  download "$FD_URL" "$tmp/fd.tar.gz"
  tar -xzf "$tmp/fd.tar.gz" -C "$tmp"
  mkdir -p "$BIN_DIR"
  install -m 0755 "$tmp/$FD_TAR_DIR/fd" "$BIN_DIR/fd"
  rm -rf "$tmp"
  ok "fd installato"
fi

# ---------- 4. Nerd Font ----------
if [[ $SKIP_FONT == true ]]; then
  skip "Font saltato (--skip-font)"
elif [[ -n "$(ls -A "$FONT_DIR" 2>/dev/null)" && $REFRESH != true ]]; then
  ok "JetBrainsMono Nerd Font già presente"
else
  info "Installazione JetBrainsMono Nerd Font"
  tmp="$(mktemp -d)"
  download "$FONT_URL" "$tmp/font.zip"
  mkdir -p "$FONT_DIR"
  unzip -q -o "$tmp/font.zip" -d "$FONT_DIR"
  rm -rf "$tmp"
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
  ok "Font installato in $FONT_DIR"
fi

# ---------- 5. Config Omarchy ----------
if [[ -d "$HOME/.config/nvim" && $REFRESH != true ]]; then
  skip "Config già presente in ~/.config/nvim (usa --refresh per reinstallarla)"
else
  [[ -d "$CONFIG_SRC" ]] || die "Cartella config non trovata: $CONFIG_SRC"
  [[ $REFRESH == true ]] && backup_path "$HOME/.config/nvim"
  mkdir -p "$HOME/.config"
  cp -a "$CONFIG_SRC" "$HOME/.config/nvim"
  # Se per errore theme.lua è un symlink rotto, lo sostituisce con Tokyo Night
  if [[ -L "$HOME/.config/nvim/lua/plugins/theme.lua" && ! -e "$HOME/.config/nvim/lua/plugins/theme.lua" ]]; then
    rm -f "$HOME/.config/nvim/lua/plugins/theme.lua"
  fi
  if [[ ! -f "$HOME/.config/nvim/lua/plugins/theme.lua" ]]; then
    cat > "$HOME/.config/nvim/lua/plugins/theme.lua" <<'EOF'
return {
	{
		"folke/tokyonight.nvim",
		priority = 1000,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight-night",
		},
	},
}
EOF
  fi
  ok "Config Omarchy copiata in ~/.config/nvim"
fi

# ---------- 6. Cache plugin (dal pacchetto ufficiale) ----------
if [[ $SKIP_DATA == true ]]; then
  skip "Cache plugin saltata (--skip-data): i plugin verranno clonati al primo avvio"
elif [[ -d "$HOME/.local/share/nvim" && $REFRESH != true ]]; then
  skip "Dati Neovim già presenti in ~/.local/share/nvim (usa --refresh per reinstallarli)"
else
  [[ -f "$PKG_TARBALL" ]] || die "Pacchetto non trovato: $PKG_TARBALL"
  info "Estrazione cache plugin dal pacchetto omarchy-nvim (può richiedere qualche secondo)"
  tmp="$(mktemp -d)"
  tar --zstd -xf "$PKG_TARBALL" -C "$tmp"
  src="$tmp/etc/skel/.local/share/nvim"
  [[ -d "$src" ]] || die "Cache non trovata nel pacchetto omarchy-nvim"
  if [[ $REFRESH == true ]]; then
    backup_path "$HOME/.local/share/nvim"
    rm -rf "$HOME/.local/state/nvim" "$HOME/.cache/nvim"
  fi
  mkdir -p "$HOME/.local/share"
  cp -a "$src" "$HOME/.local/share/nvim"
  # Ripristina i working tree git dei plugin pre-clonati (come fa omarchy-nvim-setup)
  for dir in "$HOME/.local/share/nvim"/lazy/*/; do
    if [[ -d "$dir/.git" ]]; then
      git --git-dir="$dir/.git" --work-tree="$dir" restore . 2>/dev/null || true
    fi
  done
  # I binari Mason inclusi nel pacchetto sono x86_64: su ARM vanno rimossi
  # e reinstallati da Mason (vedi step 9).
  if [[ $ARCH != "x86_64" ]]; then
    rm -rf "$HOME/.local/share/nvim/mason/packages/stylua" "$HOME/.local/share/nvim/mason/packages/shfmt"
    info "Binari Mason x86_64 rimossi (verranno reinstallati per $ARCH)"
  fi
  rm -rf "$tmp"
  ok "Cache plugin installata in ~/.local/share/nvim"
fi

# ---------- 7. Alias `n` e PATH ----------
setup_shell_rc() {
  local rc="$1"
  [[ -f "$rc" ]] || touch "$rc"
  if grep -q "alias n='nvim'" "$rc" 2>/dev/null; then
    return 0
  fi
  cat >> "$rc" <<'EOF'

# Omarchy-style: n apre Neovim
if [ -x "$HOME/.local/bin/nvim" ]; then
  export PATH="$HOME/.local/bin:$PATH"
  alias n='nvim'
fi
EOF
  ok "Alias 'n' aggiunto a $rc"
}

setup_shell_rc "$HOME/.zshrc"
setup_shell_rc "$HOME/.bashrc"

# ---------- 8. Neovim come editor predefinito ----------
if [[ -f "$NVIM_DIR/share/applications/nvim.desktop" ]]; then
  mkdir -p "$HOME/.local/share/applications"
  cp -f "$NVIM_DIR/share/applications/nvim.desktop" "$HOME/.local/share/applications/nvim.desktop"
  mkdir -p "$HOME/.local/share/icons/hicolor/128x128/apps"
  cp -f "$NVIM_DIR/share/icons/hicolor/128x128/apps/nvim.png" "$HOME/.local/share/icons/hicolor/128x128/apps/nvim.png" 2>/dev/null || true
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  for mime in text/plain text/english text/x-makefile text/x-c++hdr text/x-c++src text/x-chdr \
              text/x-csrc text/x-java text/x-pascal text/x-tcl text/x-tex \
              application/x-shellscript text/x-c text/x-c++ application/xml text/xml; do
    xdg-mime default nvim.desktop "$mime" 2>/dev/null || true
  done
  ok "Neovim impostato come editor predefinito per i file di testo"
fi

# ---------- 9. Sync plugin ----------
export PATH="$BIN_DIR:$PATH"
info "Sincronizzazione plugin Lazy (primo avvio headless)"
nvim --headless "+Lazy! sync" +qa || {
  echo
  die "La sincronizzazione plugin ha riportato un errore. Riapri un terminale e prova: nvim +Lazy"
}

# Su ARM reinstalla gli strumenti Mason con i binari giusti
if [[ $ARCH != "x86_64" && $SKIP_DATA != true ]]; then
  info "Reinstallo stylua e shfmt per $ARCH via Mason"
  nvim --headless -c "MasonInstall stylua" -c "MasonInstall shfmt" -c qa >/dev/null 2>&1 || \
    info "Mason non ha potuto installare stylua/shfmt: aprili con nvim e lancia :MasonInstall stylua shfmt"
fi

echo
info "Installazione completata!"
echo
echo "  Riapri il terminale (o esegui: source ~/.zshrc) e digita:  n"
echo "  Nel terminale imposta il font:  JetBrainsMono Nerd Font"
echo
