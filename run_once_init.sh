#!/usr/bin/env bash
set -e

# Workspace initialization script with proxy and environment setup
PROFILE="$HOME/.profile"

# Color definitions for highlighting
RED='\e[31m'
YELLOW='\e[33m'
GRAY='\e[90m'
GREEN='\e[32m'
CYAN='\e[36m'
RESET='\e[0m'
BLUE='\e[34m'

# Utility: colored echo
color_echo() {
  local color="$1"; shift
  echo -e "${color}$*${RESET}"
}

# Utility: prompt user and run a function if confirmed
ask_and_run() {
  local prompt="$1"
  local func="$2"
  local ans
  echo -e -n "$CYAN$prompt$RESET [${GREEN}y$RESET/${RED}N$RESET]: "
  read ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    "$func"
  fi
}

run_with_privilege() {
  if [[ $(id -u) -eq 0 ]]; then
    "$@"
  else
    if command -v sudo >/dev/null 2>&1; then
      sudo "$@"
    else
      color_echo "$YELLOW" "Warning: not running as root and sudo not available."
      color_echo "$YELLOW" "Command '$*' may fail without privileges."
      read -p "Press ENTER to continue anyway or Ctrl-C to abort..."
      "$@"
    fi
  fi
}

# Write proxy exports to ~/.profile
save_proxy_profile() {
  color_echo "$GRAY" "Updating $PROFILE with proxy settings..."
  for var in http_proxy https_proxy all_proxy; do
    if grep -q "^export $var=" "$PROFILE" 2>/dev/null; then
      sed -i "s|^export $var=.*|export $var=$proxy_url|" "$PROFILE"
    else
      echo "export $var=$proxy_url" >> "$PROFILE"
    fi
  done
  if grep -q "^export no_proxy=" "$PROFILE" 2>/dev/null; then
    sed -i "s|^export no_proxy=.*|export no_proxy=localhost,127.0.0.1,10.0.0.0/8|" "$PROFILE"
  else
    echo "export no_proxy=localhost,127.0.0.1,10.0.0.0/8" >> "$PROFILE"
  fi
  save_proxy=true
}

# Check and configure proxy in ~/.profile
configure_profile_proxy() {
  local all_set=true
  for var in http_proxy https_proxy all_proxy; do
    if ! grep -qx "export $var=$proxy_url" "$PROFILE" 2>/dev/null; then
      all_set=false
    fi
  done
  if ! grep -qx "export no_proxy=localhost,127.0.0.1,10.0.0.0/8" "$PROFILE" 2>/dev/null; then
    all_set=false
  fi

  if $all_set; then
    color_echo "$GRAY" "Proxy already present in $PROFILE. Skipping."
    save_proxy=true
  else
    ask_and_run "Save proxy settings to $PROFILE?" save_proxy_profile
  fi
}

# Function to configure APT proxy settings
configure_apt_proxy() {
  color_echo "$GRAY" "Writing APT proxy settings to $APT_CONF..."
  printf "%s\n" "${PROXY_LINES[@]}" | run_with_privilege tee "$APT_CONF" > /dev/null
}

# 1. Determine initial proxy setting based on environment
if [[ -n "$http_proxy" && -n "$https_proxy" && -n "$all_proxy" ]]; then
  proxy_url="$http_proxy"
  color_echo "$GRAY" "Detected existing proxy settings; using proxy: $proxy_url"
else
  default_proxy="${http_proxy:-${https_proxy:-$all_proxy}}"
  if [[ -n "$default_proxy" ]]; then
    read -p "Enter proxy URL (default: $default_proxy, leave blank to use default): " proxy_url
    proxy_url="${proxy_url:-$default_proxy}"
  else
    read -p "Enter proxy URL (e.g. http://proxy:port), or leave blank to skip proxy: " proxy_url
  fi
fi

# 2. Configure if proxy_url is set
if [[ -n "$proxy_url" ]]; then
  color_echo "$GRAY" "Configuring proxy environment variables..."
  export http_proxy="$proxy_url"
  export https_proxy="$proxy_url"
  export all_proxy="$proxy_url"
  export no_proxy="localhost,127.0.0.1,10.0.0.0/8"

  # Save to ~/.profile
  configure_profile_proxy

  # APT proxy configuration
  if [[ "$save_proxy" == true ]] && command -v apt >/dev/null; then
    APT_CONF="/etc/apt/apt.conf.d/95proxy"
    PROXY_LINES=(
      "Acquire::http::Proxy \"$proxy_url\";"
      "Acquire::https::Proxy \"$proxy_url\";"
    )
    configured=true

    if [[ -f "$APT_CONF" ]]; then
      for line in "${PROXY_LINES[@]}"; do
        if ! grep -Fxq "$line" "$APT_CONF"; then
          configured=false
          break
        fi
      done
    else
      configured=false
    fi

    if $configured; then
      color_echo "$GRAY" "APT proxy already configured in $APT_CONF. Skipping."
    else
      ask_and_run "Configure APT to use this proxy?" configure_apt_proxy
    fi
  fi
fi

# 3. Environment setup functions

OS=linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  if [[ -f /etc/debian_version ]]; then
    OS=debian
  else
    color_echo "$RED" "Unsupported Linux distribution."
  fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
  OS=mac
else
  color_echo "$RED" "Unsupported OS: $OSTYPE"
  exit 1
fi

fish_init() {
  if [[ $OS == "debian" ]]; then
    apt install -y software-properties-common
    if ! apt-add-repository -L | grep -q "fish-shell/release-4"; then
      apt-add-repository ppa:fish-shell/release-4
      apt update
    fi
    apt install -y fish
  elif [[ $OS == "mac" ]]; then
    brew install fish
  fi
  fish -c "tide configure"
  if ! cat /etc/shells | grep -q fish; then
    echo `which fish` | run_with_privilege tee -a /etc/shells
  fi
  chsh -s `which fish`
}

debian_init() {
  color_echo "$BLUE" "Running Debian initialization..."
  chmod 1777 /tmp
  apt update
  apt install -y tmux vim wget
  if ! command -v fish >/dev/null; then
    ask_and_run "Install fish shell?" fish_init
  fi
  color_echo "$GREEN" "Debian setup complete."
}

mac_init() {
  color_echo "$BLUE" "Running macOS initialization..."
  color_echo "$RED" "macOS setup is not yet implemented."
}

if [[ "$OS" == "debian" ]]; then
  debian_init
elif [[ "$OS" == "mac" ]]; then
  mac_init
fi

git config --global user.name "YouXam"
git config --global user.email "youxam@outlook.com"