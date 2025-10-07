#!/bin/bash
# system-setup.sh
# Arch-based system configuration script
# Idempotent by design

set -euo pipefail

# Optional: colored output
info() { echo -e "\033[1;34m[INFO] $*\033[0m"; }
warn() { echo -e "\033[1;33m[WARN] $*\033[0m"; }
error() { echo -e "\033[1;31m[ERROR] $*\033[0m"; }

# ---- USER CHOICE: LAPTOP OR DESKTOP ----
echo
info "Do you want to set up a laptop or desktop configuration?"
echo "Type 'laptop' or 'desktop' and press Enter: "
read -r SYSTEM_TYPE

# ---- 1. UPDATE SYSTEM ----
info "Updating system packages..."
sudo pacman -Syu --noconfirm

# ---- 2. REMOVE UNWANTED PACKAGES ----
UNWANTED_PKGS=(
  "1password-cli"
  "1password-beta"
  "docker"
  "docker-compose"
  "docker-buildx"
  "kdenlive"
  "lazydocker"
  "obsidian"
  "signal-desktop"
  "typora"
)

info "Removing unwanted packages (if installed)..."
for pkg in "${UNWANTED_PKGS[@]}"; do
  if pacman -Q "$pkg" &>/dev/null; then
    info "Removing $pkg"
    sudo pacman -Rns --noconfirm "$pkg"
  else
    warn "$pkg is not installed, skipping"
  fi
done

if [[ "$SYSTEM_TYPE" == "laptop" ]]; then
  info "Running laptop-specific configuration..."
  # ---- 3.1. CONFIGURE SYSTEM FILES ----
  info "Applying configuration files..."

  # Array of source and destination pairs
  FILES_TO_COPY=(
    "./config_files/laptop/monitors.conf:$HOME/.config/hypr/monitors.conf"
  )

  for pair in "${FILES_TO_COPY[@]}"; do
    SRC="${pair%%:*}"
    DEST="${pair##*:}"
    if [[ -f "$SRC" ]]; then
      info "Copying $(basename "$SRC") to $DEST"
      cp -f "$SRC" "$DEST"
    else
      warn "$SRC not found, skipping"
    fi
  done

elif [[ "$SYSTEM_TYPE" == "desktop" ]]; then
  info "Running desktop-specific configuration..."
  # ---- 3.2. CONFIGURE SYSTEM FILES ----
  info "Applying configuration files..."

  # Array of source and destination pairs
  FILES_TO_COPY=(
    "./config_files/desktop/monitors.conf:$HOME/.config/hypr/monitors.conf"
  )

  for pair in "${FILES_TO_COPY[@]}"; do
    SRC="${pair%%:*}"
    DEST="${pair##*:}"
    if [[ -f "$SRC" ]]; then
      info "Copying $(basename "$SRC") to $DEST"
      cp -f "$SRC" "$DEST"
    else
      warn "$SRC not found, skipping"
    fi
  done
else
  warn "Unknown system type: $SYSTEM_TYPE"
fi

info "Running host-agnostic configuration..."
# ---- 4. CONFIGURE SYSTEM FILES ----
info "Applying configuration files..."

# Array of source and destination pairs
FILES_TO_COPY=(
  "./config_files/alacritty.toml:$HOME/.config/alacritty/alacritty.toml"
  "./config_files/input.conf:$HOME/.config/hypr/input.conf"
  "./config_files/bindings.conf:$HOME/.config/hypr/bindings.conf"
  "./config_files/looknfeel.conf:$HOME/.config/hypr/looknfeel.conf"
  "./config_files/hyprsunset.conf:$HOME/.config/hypr/hyprsunset.conf"
  "./config_files/config.jsonc:$HOME/.config/waybar/config.jsonc"
  "./config_files/style.css:$HOME/.config/waybar/style.css"
  "./config_files/airpods.sh:/opt/custom_scripts/airpods.sh"
)

for pair in "${FILES_TO_COPY[@]}"; do
  SRC="${pair%%:*}"
  DEST="${pair##*:}"
  if [[ -f "$SRC" ]]; then
    info "Copying $(basename "$SRC") to $DEST"
    sudo install -D "$SRC" "$DEST"
  else
    warn "$SRC not found, skipping"
  fi
done

info "All configuration files were applied"

# --- 4.1. REMOVE .desktop APPLICATIONS ----
info "Applying .desktop files..."

DESKTOP_FILES_TO_COPY=(
  "./config_files/typora.desktop:$HOME/.local/share/applications/typora.desktop"
  "./config_files/WhatsApp.desktop:$HOME/.local/share/applications/WhatsApp.desktop"
  "./config_files/Google Photos.desktop:$HOME/.local/share/applications/Google Photos.desktop"
  "./config_files/Google Messages.desktop:$HOME/.local/share/applications/Google Messages.desktop"
  "./config_files/Google Contacts.desktop:$HOME/.local/share/applications/Google Contacts.desktop"
  "./config_files/Figma.desktop:$HOME/.local/share/applications/Figma.desktop"
  "./config_files/Docker.desktop:$HOME/.local/share/applications/Docker.desktop"
)

for pair in "${DESKTOP_FILES_TO_COPY[@]}"; do
  SRC="${pair%%:*}"
  DEST="${pair##*:}"
  if [[ -f "$SRC" ]]; then
    info "Copying $(basename "$SRC") to $DEST"
    sudo install -D "$SRC" "$DEST"
  else
    warn "$SRC not found, skipping"
  fi
done

info "All .desktop files were applied."

info "Running custom configuration"

info "Setting up password store for git..."
git config --global credential.helper store
info "Store for git has been set up"

info "Installing packages"

info "Installing Tailscale..."
sudo pacman -S --noconfirm tailscale
# Enabling tailscale does not wok immiedietly.
# You have to manually execute following commands after reboot.
# sudo systemctl enable --now tailscaled
# sudo tailscale set --operator="$USER"
info "Tailscale installed."
info "Remember to run 'tailscale up' to connect."

info "All packages were installed"

# ---- 5. DONE ----
info "System update and config complete! You might want to reboot to apply all changes."
