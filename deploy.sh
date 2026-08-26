#!/usr/bin/env bash

# User-level dotfiles bootstrap and deployment.
#
# This script intentionally never uses sudo, apt, chsh, or a global install
# prefix. Applications and their large data live below DATA_DIR; only small
# configuration links are placed below HOME_DIR.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$SCRIPT_DIR"
TARGET_HOME="${HOME:-}"
DATA_DIR=""
HOME_EXPLICIT=0
INTERACTIVE=0
ASSUME_YES=0
INSTALL_MISSING=1
DRY_RUN=0
MIRROR="current"
MIRROR_EXPLICIT=0
GITHUB_BASE="https://github.com"
NPM_REGISTRY_OVERRIDE=""
PYPI_INDEX_OVERRIDE=""
UV_INSTALLER_URL_OVERRIDE=""
CONDA_CHANNEL_OVERRIDE=""
CONDA_INSTALLER_URL_OVERRIDE=""
NODE_MIRROR_OVERRIDE=""
FNM_NODE_VERSION="lts"
NVIM_VERSION="latest"

declare -A PROVIDED_PATHS=()
declare -A APP_PATHS=()

if [[ -t 0 && -t 1 ]]; then
    INTERACTIVE=1
fi

if [[ -t 1 ]]; then
    RED=$'\033[31m'
    YELLOW=$'\033[33m'
    GREEN=$'\033[32m'
    BLUE=$'\033[34m'
    NC=$'\033[0m'
else
    RED=''
    YELLOW=''
    GREEN=''
    BLUE=''
    NC=''
fi

usage() {
    cat <<'EOF'
Usage:
  bash deploy.sh [options]

Path options:
  --home PATH                 Target user's home directory (default: $HOME)
  --data PATH                 Persistent data directory (default: --home)
  --repo PATH                 Dotfiles repository (default: script directory)

Existing application options:
  --zsh-path PATH             Use an existing zsh executable
  --nvim-path PATH            Use an existing nvim executable
  --uv-path PATH              Use an existing uv executable
  --fnm-path PATH              Use an existing fnm executable
  --npm-path PATH             Use an existing npm executable
  --conda-path PATH           Use an existing Conda prefix or conda executable
  --oh-my-zsh-path PATH       Use an existing Oh My Zsh directory

Installation options:
  --mirror NAME               current, official, or custom
  --npm-registry URL          npm registry override
  --pypi-index URL            uv/PyPI index override
  --uv-installer-url URL      uv installer URL override
  --conda-channel URL         Conda channel URL override
  --conda-installer-url URL   Miniconda installer URL override
  --node-mirror URL           fnm's Node distribution mirror override
  --node-version VERSION      Node version managed by fnm or lts (default: lts)
  --github-base URL           GitHub download base (default: https://github.com)
  --nvim-version VERSION      Neovim version or latest (default: latest)
  --no-install                Never download or install missing applications
  --yes, -y                   Accept installation prompts
  --non-interactive           Disable all prompts
  --dry-run                   Show actions without changing files or installing
  --check                     Alias for --dry-run --no-install
  --help, -h                  Show this help

Examples:
  bash deploy.sh
  bash deploy.sh --home /home/starwink --data /data/starwink
  bash deploy.sh --home /home/starwink --data /data/starwink \
    --zsh-path /data/starwink/bin/zsh --no-install
EOF
}

die() {
    printf '%sERROR:%s %s\n' "$RED" "$NC" "$*" >&2
    exit 1
}

warn() {
    printf '%sWARNING:%s %s\n' "$YELLOW" "$NC" "$*" >&2
}

info() {
    printf '%s\n' "$*"
}

success() {
    printf '%s%s%s\n' "$GREEN" "$*" "$NC"
}

require_value() {
    (($# >= 2)) || die "$1 requires a value"
    [[ -n "$2" ]] || die "$1 requires a non-empty value"
}

set_option_value() {
    local option="$1"
    local value="$2"
    case "$option" in
        --home) TARGET_HOME="$value"; HOME_EXPLICIT=1 ;;
        --data) DATA_DIR="$value" ;;
        --repo) REPO_DIR="$value" ;;
        --zsh-path) PROVIDED_PATHS[zsh]="$value" ;;
        --nvim-path) PROVIDED_PATHS[nvim]="$value" ;;
        --uv-path) PROVIDED_PATHS[uv]="$value" ;;
        --fnm-path) PROVIDED_PATHS[fnm]="$value" ;;
        --npm-path) PROVIDED_PATHS[npm]="$value" ;;
        --conda-path) PROVIDED_PATHS[conda]="$value" ;;
        --oh-my-zsh-path) PROVIDED_PATHS[ohmyzsh]="$value" ;;
        --mirror) MIRROR="$value"; MIRROR_EXPLICIT=1 ;;
        --npm-registry) NPM_REGISTRY_OVERRIDE="$value" ;;
        --pypi-index) PYPI_INDEX_OVERRIDE="$value" ;;
        --uv-installer-url) UV_INSTALLER_URL_OVERRIDE="$value" ;;
        --conda-channel) CONDA_CHANNEL_OVERRIDE="$value" ;;
        --conda-installer-url) CONDA_INSTALLER_URL_OVERRIDE="$value" ;;
        --node-mirror) NODE_MIRROR_OVERRIDE="$value" ;;
        --node-version) FNM_NODE_VERSION="$value" ;;
        --github-base) GITHUB_BASE="$value" ;;
        --nvim-version) NVIM_VERSION="$value" ;;
        *) die "unsupported option: $option" ;;
    esac
}

parse_args() {
    while (($#)); do
        case "$1" in
            --help|-h)
                usage
                exit 0
                ;;
            --yes|-y)
                ASSUME_YES=1
                ;;
            --non-interactive)
                INTERACTIVE=0
                ;;
            --no-install)
                INSTALL_MISSING=0
                ;;
            --dry-run)
                DRY_RUN=1
                ;;
            --check)
                DRY_RUN=1
                INSTALL_MISSING=0
                ;;
            --home|--data|--repo|--zsh-path|--nvim-path|--uv-path|--fnm-path|--npm-path|--conda-path|--oh-my-zsh-path|--mirror|--npm-registry|--pypi-index|--uv-installer-url|--conda-channel|--conda-installer-url|--node-mirror|--node-version|--github-base|--nvim-version)
                require_value "$1" "${2:-}"
                set_option_value "$1" "$2"
                shift
                ;;
            --home=*|--data=*|--repo=*|--zsh-path=*|--nvim-path=*|--uv-path=*|--fnm-path=*|--npm-path=*|--conda-path=*|--oh-my-zsh-path=*|--mirror=*|--npm-registry=*|--pypi-index=*|--uv-installer-url=*|--conda-channel=*|--conda-installer-url=*|--node-mirror=*|--node-version=*|--github-base=*|--nvim-version=*)
                option="${1%%=*}"
                value="${1#*=}"
                require_value "$option" "$value"
                set_option_value "$option" "$value"
                ;;
            --)
                shift
                (($# == 0)) || die "unexpected positional arguments: $*"
                ;;
            -*|*)
                die "unknown option: $1"
                ;;
        esac
        shift
    done
}

validate_absolute_path() {
    local name="$1"
    local value="$2"
    [[ "$value" == /* ]] || die "$name must be an absolute path: $value"
}

make_dir() {
    local directory="$1"
    if ((DRY_RUN)); then
        [[ -d "$directory" ]] || info "[dry-run] mkdir -p $directory"
    else
        mkdir -p -- "$directory"
    fi
}

check_writable_dir() {
    local directory="$1"
    if [[ -e "$directory" && ! -d "$directory" ]]; then
        die "not a directory: $directory"
    fi
    if [[ -d "$directory" && ! -w "$directory" ]]; then
        if ((DRY_RUN)); then
            warn "directory is not writable in this environment: $directory"
        else
            die "directory is not writable: $directory"
        fi
    fi
}

choose_defaults() {
    [[ -n "$TARGET_HOME" ]] || die 'cannot determine target home; pass --home PATH'
    if ((INTERACTIVE && ASSUME_YES == 0 && HOME_EXPLICIT == 0)); then
        printf '%sTarget home [%s]: %s' "$BLUE" "$TARGET_HOME" "$NC"
        local answer=''
        IFS= read -r answer || true
        [[ -z "$answer" ]] || TARGET_HOME="$answer"
    fi
    if [[ -n "$DATA_DIR" ]]; then
        return
    fi
    if ((INTERACTIVE && ASSUME_YES == 0)); then
        printf '%sPersistent data directory [%s]: %s' "$BLUE" "$TARGET_HOME" "$NC"
        local answer=''
        IFS= read -r answer || true
        DATA_DIR="${answer:-$TARGET_HOME}"
    else
        DATA_DIR="$TARGET_HOME"
    fi
}

choose_interactive_settings() {
    if ((INTERACTIVE && ASSUME_YES == 0 && MIRROR_EXPLICIT == 0)); then
        printf '%sDownload source [1] current mirrors, [2] official [default: 1]: %s' "$BLUE" "$NC"
        local answer=''
        IFS= read -r answer || true
        case "$answer" in
            2|official) MIRROR=official ;;
            1|''|current) MIRROR=current ;;
            *) die 'please choose 1 or 2, or use --mirror current|official' ;;
        esac
    fi

    case "$MIRROR" in
        current|official|custom) ;;
        *) die "unsupported mirror profile: $MIRROR" ;;
    esac
}

read_config_value() {
    local file="$1"
    local pattern="$2"
    [[ -r "$file" ]] || return 0
    sed -En "s/${pattern}/\\1/p" "$file" | head -n 1
}

configure_sources() {
    local current_npm current_pypi
    current_npm="$(read_config_value "$REPO_DIR/npm/npmrc" '^registry=([^[:space:]]+).*$')"
    current_pypi="$(read_config_value "$REPO_DIR/uv/uv.toml" '^url = "([^"]+)"$')"

    case "$MIRROR" in
        current)
            NPM_REGISTRY="${current_npm:-https://registry.npmmirror.com/}"
            PYPI_INDEX="${current_pypi:-https://mirrors.nju.edu.cn/pypi/web/simple}"
            NODE_MIRROR="https://npmmirror.com/mirrors/node"
            CONDA_CHANNEL="https://mirrors.nju.edu.cn/anaconda/cloud/conda-forge"
            CONDA_INSTALLER_BASE="https://mirrors.nju.edu.cn/anaconda/miniconda"
            ;;
        official)
            NPM_REGISTRY="https://registry.npmjs.org/"
            PYPI_INDEX="https://pypi.org/simple"
            NODE_MIRROR="https://nodejs.org/dist"
            CONDA_CHANNEL="https://conda.anaconda.org/conda-forge"
            CONDA_INSTALLER_BASE="https://repo.anaconda.com/miniconda"
            ;;
        custom)
            [[ -n "$NPM_REGISTRY_OVERRIDE" ]] || die '--mirror custom requires --npm-registry'
            [[ -n "$PYPI_INDEX_OVERRIDE" ]] || die '--mirror custom requires --pypi-index'
            [[ -n "$UV_INSTALLER_URL_OVERRIDE" ]] || die '--mirror custom requires --uv-installer-url'
            [[ -n "$CONDA_CHANNEL_OVERRIDE" ]] || die '--mirror custom requires --conda-channel'
            [[ -n "$CONDA_INSTALLER_URL_OVERRIDE" ]] || die '--mirror custom requires --conda-installer-url'
            [[ -n "$NODE_MIRROR_OVERRIDE" ]] || die '--mirror custom requires --node-mirror'
            NPM_REGISTRY="$NPM_REGISTRY_OVERRIDE"
            PYPI_INDEX="$PYPI_INDEX_OVERRIDE"
            NODE_MIRROR="$NODE_MIRROR_OVERRIDE"
            CONDA_CHANNEL="$CONDA_CHANNEL_OVERRIDE"
            CONDA_INSTALLER_BASE="${CONDA_INSTALLER_URL_OVERRIDE%/*}"
            ;;
    esac

    [[ -n "$NPM_REGISTRY_OVERRIDE" ]] && NPM_REGISTRY="$NPM_REGISTRY_OVERRIDE"
    [[ -n "$PYPI_INDEX_OVERRIDE" ]] && PYPI_INDEX="$PYPI_INDEX_OVERRIDE"
    [[ -n "$NODE_MIRROR_OVERRIDE" ]] && NODE_MIRROR="$NODE_MIRROR_OVERRIDE"
    [[ -n "$CONDA_CHANNEL_OVERRIDE" ]] && CONDA_CHANNEL="$CONDA_CHANNEL_OVERRIDE"

    export NPM_CONFIG_REGISTRY="$NPM_REGISTRY"
    export UV_INDEX_URL="$PYPI_INDEX"
    export FNM_NODE_DIST_MIRROR="$NODE_MIRROR"
    export DOTFILES_GITHUB_BASE="$GITHUB_BASE"
    export CONDARC="$REPO_DIR/conda/condarc"

    info "source profile: $MIRROR"
    info "  npm:    $NPM_REGISTRY"
    info "  PyPI:   $PYPI_INDEX"
    info "  Node:   $NODE_MIRROR"
    info "  Conda:  $CONDA_CHANNEL"
    info "  Miniconda: $CONDA_INSTALLER_BASE"
}

find_command() {
    command -v "$1" 2>/dev/null || true
}

set_app_path() {
    local app="$1"
    local candidate="$2"
    case "$app" in
        conda)
            if [[ -x "$candidate/bin/conda" ]]; then
                APP_PATHS[conda]="$candidate"
            elif [[ "$candidate" == */bin/conda && -x "$candidate" ]]; then
                APP_PATHS[conda]="${candidate%/bin/conda}"
            else
                return 1
            fi
            ;;
        ohmyzsh)
            [[ -d "$candidate" ]] || return 1
            APP_PATHS[ohmyzsh]="$candidate"
            ;;
        *)
            [[ -x "$candidate" ]] || return 1
            APP_PATHS["$app"]="$candidate"
            ;;
    esac
}

find_existing_app() {
    local app="$1"
    local candidate
    local candidates=()

    case "$app" in
        conda)
            candidates+=(
                "${CONDA_PREFIX:-}"
                "${TARGET_HOME}/miniconda3"
                "${DATA_DIR}/apps/miniconda"
            )
            candidate="$(find_command conda)"
            [[ -n "$candidate" ]] && candidates+=("$candidate")
            ;;
        ohmyzsh)
            candidates+=(
                "${DATA_DIR}/apps/oh-my-zsh"
                "${TARGET_HOME}/.oh-my-zsh"
            )
            ;;
        *)
            candidates+=(
                "${DATA_DIR}/bin/$app"
                "${DATA_DIR}/.local/bin/$app"
                "${TARGET_HOME}/.local/bin/$app"
            )
            candidate="$(find_command "$app")"
            [[ -n "$candidate" ]] && candidates+=("$candidate")
            ;;
    esac

    for candidate in "${candidates[@]}"; do
        [[ -n "$candidate" ]] || continue
        if set_app_path "$app" "$candidate"; then
            return 0
        fi
    done
    return 1
}

prompt_existing_path() {
    local app="$1"
    ((INTERACTIVE && ASSUME_YES == 0)) || return 1
    printf '%s%s is missing. Enter an existing path, or press Enter to install it under %s: %s' "$BLUE" "$app" "$DATA_DIR" "$NC"
    local candidate=''
    IFS= read -r candidate || true
    [[ -n "$candidate" ]] || return 1
    set_app_path "$app" "$candidate" || die "invalid $app path: $candidate"
    success "using supplied $app: ${APP_PATHS[$app]}"
    return 0
}

confirm_install() {
    local app="$1"
    ((INSTALL_MISSING)) || return 1
    ((ASSUME_YES)) && return 0
    ((INTERACTIVE)) || return 0
    printf '%sInstall %s into %s? [Y/n]: %s' "$BLUE" "$app" "$DATA_DIR" "$NC"
    local answer=''
    IFS= read -r answer || true
    [[ -z "$answer" || "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

download_file() {
    local url="$1"
    local output="$2"
    make_dir "$(dirname -- "$output")"
    info "downloading $url"
    if command -v curl >/dev/null 2>&1; then
        curl --fail --location --retry 3 --connect-timeout 20 --output "$output" "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget --https-only --tries=3 --timeout=20 --output-document="$output" "$url"
    else
        die 'curl or wget is required for user-level installation'
    fi
}

temporary_directory() {
    command -v mktemp >/dev/null 2>&1 || die 'mktemp is required for installation'
    mktemp -d "${TMPDIR:-/tmp}/dotfiles-deploy.XXXXXX"
}

install_uv() {
    local target="$DATA_DIR/bin/uv"
    if ((DRY_RUN)); then
        info "[dry-run] install uv into $DATA_DIR/bin"
        APP_PATHS[uv]="$target"
        return 0
    fi
    local tmp
    tmp="$(temporary_directory)"
    local installer_url="${UV_INSTALLER_URL_OVERRIDE:-https://astral.sh/uv/install.sh}"
    download_file "$installer_url" "$tmp/install.sh"
    UV_INSTALL_DIR="$DATA_DIR/bin" UV_NO_MODIFY_PATH=1 sh "$tmp/install.sh"
    [[ -x "$target" ]] || die "uv installation did not create $target"
    APP_PATHS[uv]="$target"
    rm -rf -- "$tmp"
}

linux_archive_arch() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s' x86_64 ;;
        aarch64|arm64) printf '%s' arm64 ;;
        *) die "unsupported Linux architecture: $(uname -m)" ;;
    esac
}

fnm_release_asset() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s' fnm-linux ;;
        aarch64|arm64) printf '%s' fnm-arm64 ;;
        arm|armv7|armv7l) printf '%s' fnm-arm32 ;;
        *) die "unsupported Linux architecture for fnm: $(uname -m)" ;;
    esac
}

linux_conda_arch() {
    case "$(uname -m)" in
        x86_64|amd64) printf '%s' x86_64 ;;
        aarch64|arm64) printf '%s' aarch64 ;;
        *) die "unsupported Linux architecture for Miniconda: $(uname -m)" ;;
    esac
}

install_nvim() {
    local arch archive url target_root target
    arch="$(linux_archive_arch)"
    archive="nvim-linux-${arch}.tar.gz"
    if [[ "$NVIM_VERSION" == latest ]]; then
        url="${GITHUB_BASE%/}/neovim/neovim/releases/latest/download/${archive}"
        target_root="$DATA_DIR/apps/nvim-${arch}"
    else
        local version="$NVIM_VERSION"
        [[ "$version" == v* ]] || version="v$version"
        url="${GITHUB_BASE%/}/neovim/neovim/releases/download/${version}/${archive}"
        target_root="$DATA_DIR/apps/nvim-${version}-${arch}"
    fi
    target="$target_root/bin/nvim"
    if ((DRY_RUN)); then
        info "[dry-run] install nvim from $url into $target_root"
        APP_PATHS[nvim]="$DATA_DIR/bin/nvim"
        return 0
    fi
    local tmp extracted
    tmp="$(temporary_directory)"
    download_file "$url" "$tmp/$archive"
    tar -xzf "$tmp/$archive" -C "$tmp"
    extracted="$tmp/nvim-linux-${arch}"
    [[ -x "$extracted/bin/nvim" ]] || die "nvim archive has unexpected layout"
    [[ ! -e "$target_root" ]] || die "nvim target already exists: $target_root"
    make_dir "$DATA_DIR/apps"
    mv -- "$extracted" "$target_root"
    ln -s -- "$target" "$DATA_DIR/bin/nvim"
    APP_PATHS[nvim]="$DATA_DIR/bin/nvim"
    rm -rf -- "$tmp"
}

install_fnm() {
    local asset archive url target extracted
    asset="$(fnm_release_asset)"
    archive="${asset}.zip"
    url="${GITHUB_BASE%/}/Schniz/fnm/releases/latest/download/${archive}"
    target="$DATA_DIR/bin/fnm"
    if ((DRY_RUN)); then
        info "[dry-run] install fnm from $url into $target"
        APP_PATHS[fnm]="$target"
        return 0
    fi

    local unzip_bin
    unzip_bin="$(find_command unzip)"
    [[ -n "$unzip_bin" ]] || die 'fnm installation requires unzip; install unzip or pass --fnm-path PATH'
    [[ ! -e "$target" && ! -L "$target" ]] || die "fnm target already exists but is not usable: $target"

    local tmp
    tmp="$(temporary_directory)"
    download_file "$url" "$tmp/$archive"
    make_dir "$tmp/extracted"
    "$unzip_bin" -q "$tmp/$archive" -d "$tmp/extracted"
    if [[ -x "$tmp/extracted/fnm" ]]; then
        extracted="$tmp/extracted/fnm"
    elif [[ -x "$tmp/extracted/$asset/fnm" ]]; then
        extracted="$tmp/extracted/$asset/fnm"
    else
        die 'fnm archive has unexpected layout'
    fi
    make_dir "$DATA_DIR/bin"
    mv -- "$extracted" "$target"
    chmod 755 "$target"
    APP_PATHS[fnm]="$target"
    rm -rf -- "$tmp"
}

setup_fnm_environment() {
    local fnm_bin="${APP_PATHS[fnm]}"
    export FNM_DIR="$DATA_DIR/.local/share/fnm"
    export FNM_NODE_DIST_MIRROR="$NODE_MIRROR"
    eval "$(FNM_DIR="$FNM_DIR" FNM_NODE_DIST_MIRROR="$FNM_NODE_DIST_MIRROR" \
        "$fnm_bin" env --use-on-cd --shell bash)"
}

ensure_fnm_node() {
    local fnm_bin="${APP_PATHS[fnm]}"
    local node_bin npm_bin version

    if ((DRY_RUN)); then
        info "[dry-run] use fnm under $DATA_DIR/.local/share/fnm to install Node $FNM_NODE_VERSION"
        APP_PATHS[npm]="$DATA_DIR/bin/npm"
        return 0
    fi

    setup_fnm_environment
    node_bin="$(find_command node)"
    npm_bin="$(find_command npm)"
    if [[ -z "$node_bin" || -z "$npm_bin" ]]; then
        if [[ "$FNM_NODE_VERSION" == lts ]]; then
            info 'installing Node LTS through fnm'
            FNM_DIR="$FNM_DIR" FNM_NODE_DIST_MIRROR="$FNM_NODE_DIST_MIRROR" \
                "$fnm_bin" install --lts --use
            FNM_DIR="$FNM_DIR" FNM_NODE_DIST_MIRROR="$FNM_NODE_DIST_MIRROR" \
                "$fnm_bin" default lts-latest >/dev/null 2>&1 || true
        else
            version="$FNM_NODE_VERSION"
            FNM_DIR="$FNM_DIR" FNM_NODE_DIST_MIRROR="$FNM_NODE_DIST_MIRROR" \
                "$fnm_bin" install "$version" --use
            FNM_DIR="$FNM_DIR" FNM_NODE_DIST_MIRROR="$FNM_NODE_DIST_MIRROR" \
                "$fnm_bin" default "$version" >/dev/null 2>&1 || true
        fi
        setup_fnm_environment
    fi

    node_bin="$(find_command node)"
    npm_bin="$(find_command npm)"
    [[ -x "$node_bin" ]] || die 'fnm did not provide a usable node executable'
    [[ -x "$npm_bin" ]] || die 'fnm did not provide a usable npm executable'
    APP_PATHS[node]="$node_bin"
    APP_PATHS[npm]="$npm_bin"
}

install_npm() {
    [[ -n "${APP_PATHS[fnm]-}" ]] || die 'npm installation requires a usable fnm installation'
    ensure_fnm_node
}

install_miniconda() {
    local arch installer_url target="$DATA_DIR/apps/miniconda"
    arch="$(linux_conda_arch)"
    installer_url="${CONDA_INSTALLER_URL_OVERRIDE:-${CONDA_INSTALLER_BASE}/Miniconda3-latest-Linux-${arch}.sh}"
    if ((DRY_RUN)); then
        info "[dry-run] install Miniconda from $installer_url into $target"
        APP_PATHS[conda]="$target"
        return 0
    fi
    [[ ! -e "$target" ]] || die "Conda target already exists but is not usable: $target"
    local tmp
    tmp="$(temporary_directory)"
    download_file "$installer_url" "$tmp/miniconda.sh"
    bash "$tmp/miniconda.sh" -b -p "$target"
    [[ -x "$target/bin/conda" ]] || die "Miniconda installation did not create $target/bin/conda"
    APP_PATHS[conda]="$target"
    rm -rf -- "$tmp"
}

install_zsh() {
    local target="$DATA_DIR/apps/zsh-env"
    if ((DRY_RUN)); then
        info "[dry-run] install zsh into $target using user-level Conda"
        APP_PATHS[zsh]="$target/bin/zsh"
        return 0
    fi
    local conda_bin="${APP_PATHS[conda]}/bin/conda"
    [[ -x "$conda_bin" ]] || die 'zsh is missing and a usable user-level Conda installation was not found'
    [[ ! -e "$target" ]] || die "zsh target already exists but is not usable: $target"
    make_dir "$DATA_DIR/apps"
    make_dir "$DATA_DIR/.cache/conda/pkgs"
    make_dir "$DATA_DIR/.local/share/conda/envs"
    CONDA_PKGS_DIRS="$DATA_DIR/.cache/conda/pkgs" \
    CONDA_ENVS_PATH="$DATA_DIR/.local/share/conda/envs" \
        "$conda_bin" create --yes --prefix "$target" --override-channels --channel "$CONDA_CHANNEL" zsh
    [[ -x "$target/bin/zsh" ]] || die "Conda zsh installation did not create $target/bin/zsh"
    APP_PATHS[zsh]="$target/bin/zsh"
}

install_archive_directory() {
    local url="$1"
    local target="$2"
    local archive_name="$3"
    local extracted_name="$4"
    if ((DRY_RUN)); then
        info "[dry-run] install archive $url into $target"
        return 0
    fi
    [[ ! -e "$target" ]] || return 0
    local tmp
    tmp="$(temporary_directory)"
    download_file "$url" "$tmp/$archive_name"
    tar -xzf "$tmp/$archive_name" -C "$tmp"
    [[ -d "$tmp/$extracted_name" ]] || die "archive has unexpected layout: $url"
    make_dir "$(dirname -- "$target")"
    mv -- "$tmp/$extracted_name" "$target"
    rm -rf -- "$tmp"
}

ensure_zsh_stack() {
    local omz_dir="${APP_PATHS[ohmyzsh]-}"
    if [[ -z "$omz_dir" ]]; then
        if [[ -d "$DATA_DIR/apps/oh-my-zsh" ]]; then
            omz_dir="$DATA_DIR/apps/oh-my-zsh"
        elif [[ -d "$TARGET_HOME/.oh-my-zsh" ]]; then
            omz_dir="$TARGET_HOME/.oh-my-zsh"
        else
            omz_dir="$DATA_DIR/apps/oh-my-zsh"
        fi
    fi
    APP_PATHS[ohmyzsh]="$omz_dir"
    if [[ ! -d "$omz_dir" ]]; then
        confirm_install oh-my-zsh || die 'Oh My Zsh is missing; pass --oh-my-zsh-path PATH or allow installation'
        install_archive_directory \
            "${GITHUB_BASE%/}/ohmyzsh/ohmyzsh/archive/refs/heads/master.tar.gz" \
            "$omz_dir" \
            ohmyzsh.tar.gz \
            ohmyzsh-master
    fi

    local custom="$omz_dir/custom"
    local p10k="$custom/themes/powerlevel10k"
    local autosuggestions="$custom/plugins/zsh-autosuggestions"
    local syntax_highlighting="$custom/plugins/zsh-syntax-highlighting"

    if [[ ! -d "$p10k" ]]; then
        confirm_install powerlevel10k || die 'Powerlevel10k is missing; allow installation to continue'
        install_archive_directory \
            "${GITHUB_BASE%/}/romkatv/powerlevel10k/archive/refs/heads/master.tar.gz" \
            "$p10k" \
            powerlevel10k.tar.gz \
            powerlevel10k-master
    fi
    if [[ ! -d "$autosuggestions" ]]; then
        confirm_install zsh-autosuggestions || die 'zsh-autosuggestions is missing; allow installation to continue'
        install_archive_directory \
            "${GITHUB_BASE%/}/zsh-users/zsh-autosuggestions/archive/refs/heads/master.tar.gz" \
            "$autosuggestions" \
            zsh-autosuggestions.tar.gz \
            zsh-autosuggestions-master
    fi
    if [[ ! -d "$syntax_highlighting" ]]; then
        confirm_install zsh-syntax-highlighting || die 'zsh-syntax-highlighting is missing; allow installation to continue'
        install_archive_directory \
            "${GITHUB_BASE%/}/zsh-users/zsh-syntax-highlighting/archive/refs/heads/master.tar.gz" \
            "$syntax_highlighting" \
            zsh-syntax-highlighting.tar.gz \
            zsh-syntax-highlighting-master
    fi
}

resolve_or_install() {
    local app="$1"
    local explicit="${PROVIDED_PATHS[$app]-}"

    if [[ -n "$explicit" ]]; then
        set_app_path "$app" "$explicit" || die "invalid $app path: $explicit"
        success "using supplied $app: ${APP_PATHS[$app]}"
        return 0
    fi
    if find_existing_app "$app"; then
        success "found $app: ${APP_PATHS[$app]}"
        return 0
    fi
    prompt_existing_path "$app" && return 0
    if ! confirm_install "$app"; then
        die "$app is missing; pass --${app}-path PATH, choose an existing path interactively, or allow installation"
    fi

    case "$app" in
        conda) install_miniconda ;;
        zsh) install_zsh ;;
        uv) install_uv ;;
        nvim) install_nvim ;;
        fnm) install_fnm ;;
        npm) install_npm ;;
        *) die "no installer is defined for $app" ;;
    esac
    ((DRY_RUN)) || success "installed $app: ${APP_PATHS[$app]}"
}

check_dependencies() {
    local missing=0 app omz_dir lazy_root

    configure_sources
    for app in conda zsh uv nvim fnm npm; do
        if [[ -n "${PROVIDED_PATHS[$app]-}" ]]; then
            if set_app_path "$app" "${PROVIDED_PATHS[$app]}"; then
                success "using supplied $app: ${APP_PATHS[$app]}"
            else
                warn "invalid $app path: ${PROVIDED_PATHS[$app]}"
                missing=1
            fi
        elif find_existing_app "$app"; then
            success "found $app: ${APP_PATHS[$app]}"
        else
            warn "missing $app"
            missing=1
        fi
    done

    if [[ -n "${PROVIDED_PATHS[ohmyzsh]-}" ]]; then
        omz_dir="${PROVIDED_PATHS[ohmyzsh]}"
    elif [[ -d "$DATA_DIR/apps/oh-my-zsh" ]]; then
        omz_dir="$DATA_DIR/apps/oh-my-zsh"
    elif [[ -d "$TARGET_HOME/.oh-my-zsh" ]]; then
        omz_dir="$TARGET_HOME/.oh-my-zsh"
    else
        omz_dir=''
    fi
    if [[ -z "$omz_dir" || ! -d "$omz_dir" ]]; then
        warn 'missing oh-my-zsh'
        missing=1
    else
        for app in \
            "$omz_dir/custom/themes/powerlevel10k" \
            "$omz_dir/custom/plugins/zsh-autosuggestions" \
            "$omz_dir/custom/plugins/zsh-syntax-highlighting"; do
            if [[ -d "$app" ]]; then
                success "found zsh component: $app"
            else
                warn "missing zsh component: $app"
                missing=1
            fi
        done
    fi

    lazy_root="$DATA_DIR/.local/share/nvim/lazy"
    if [[ -d "$lazy_root/lazy.nvim" && -d "$lazy_root/LazyVim" ]]; then
        success "found LazyVim: $lazy_root"
    else
        warn "missing LazyVim: $lazy_root"
        missing=1
    fi

    if ((missing)); then
        warn 'dependency check failed; no files or applications were changed'
        return 1
    fi
    success 'dependency check passed; no files or applications were changed'
}

write_shell_assignment() {
    local name="$1"
    local value="$2"
    printf 'export %s=%q\n' "$name" "$value"
}

backup_existing() {
    local path="$1"
    [[ -e "$path" || -L "$path" ]] || return 0
    local stamp backup index=0
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="${path}.bak.${stamp}"
    while [[ -e "$backup" || -L "$backup" ]]; do
        index=$((index + 1))
        backup="${path}.bak.${stamp}.${index}"
    done
    mv -- "$path" "$backup"
    info "backed up $path -> $backup"
}

write_paths_file() {
    local paths_dir="$TARGET_HOME/.config/dotfiles"
    local paths_file="$paths_dir/paths.env"
    if ((DRY_RUN)); then
        info "[dry-run] write $paths_file"
        return 0
    fi
    make_dir "$paths_dir"
    backup_existing "$paths_file"
    local temporary="$paths_file.tmp.$$"
    {
        printf '# Generated by dotfiles deploy.sh. Machine-local; do not commit.\n'
        write_shell_assignment DOTFILES_HOME "$TARGET_HOME"
        write_shell_assignment DOTFILES_DATA "$DATA_DIR"
        write_shell_assignment DOTFILES_REPO "$REPO_DIR"
        write_shell_assignment DOTFILES_BIN "$DATA_DIR/bin"
        write_shell_assignment DOTFILES_OH_MY_ZSH_DIR "${APP_PATHS[ohmyzsh]:-$DATA_DIR/apps/oh-my-zsh}"
        write_shell_assignment DOTFILES_CONDA_DIR "${APP_PATHS[conda]:-$DATA_DIR/apps/miniconda}"
        write_shell_assignment DOTFILES_ZSH_BIN "${APP_PATHS[zsh]:-$DATA_DIR/apps/zsh-env/bin/zsh}"
        write_shell_assignment DOTFILES_NVIM_BIN "${APP_PATHS[nvim]:-$DATA_DIR/bin/nvim}"
        write_shell_assignment DOTFILES_UV_BIN "${APP_PATHS[uv]:-$DATA_DIR/bin/uv}"
        write_shell_assignment DOTFILES_FNM_BIN "${APP_PATHS[fnm]:-$DATA_DIR/bin/fnm}"
        write_shell_assignment DOTFILES_NPM_BIN "${APP_PATHS[npm]:-$DATA_DIR/bin/npm}"
        write_shell_assignment XDG_CONFIG_HOME "$TARGET_HOME/.config"
        write_shell_assignment XDG_DATA_HOME "$DATA_DIR/.local/share"
        write_shell_assignment XDG_STATE_HOME "$DATA_DIR/.local/state"
        write_shell_assignment XDG_CACHE_HOME "$DATA_DIR/.cache"
        write_shell_assignment NPM_CONFIG_USERCONFIG "$TARGET_HOME/.npmrc"
        write_shell_assignment NPM_CONFIG_PREFIX "$DATA_DIR/.local/npm"
        write_shell_assignment NPM_CONFIG_CACHE "$DATA_DIR/.cache/npm"
        write_shell_assignment UV_CACHE_DIR "$DATA_DIR/.cache/uv"
        write_shell_assignment UV_TOOL_DIR "$DATA_DIR/.local/share/uv/tools"
        write_shell_assignment UV_PYTHON_INSTALL_DIR "$DATA_DIR/.local/share/uv/python"
        write_shell_assignment UV_INDEX_URL "$PYPI_INDEX"
        write_shell_assignment NPM_CONFIG_REGISTRY "$NPM_REGISTRY"
        write_shell_assignment FNM_DIR "$DATA_DIR/.local/share/fnm"
        write_shell_assignment FNM_NODE_DIST_MIRROR "$NODE_MIRROR"
        write_shell_assignment CONDA_CHANNEL "$CONDA_CHANNEL"
        write_shell_assignment DOTFILES_GITHUB_BASE "$GITHUB_BASE"
        write_shell_assignment CONDA_PKGS_DIRS "$DATA_DIR/.cache/conda/pkgs"
        write_shell_assignment CONDA_ENVS_PATH "$DATA_DIR/.local/share/conda/envs"
        printf 'export PATH=%q:$PATH\n' "$DATA_DIR/bin"
        printf 'export PATH=%q:$PATH\n' "$DATA_DIR/.local/bin"
        printf 'export PATH=%q:$PATH\n' "$DATA_DIR/.local/npm/bin"
        printf 'export PATH=%q:$PATH\n' "${APP_PATHS[conda]}/bin"
    } > "$temporary"
    chmod 600 "$temporary"
    mv -- "$temporary" "$paths_file"
    success "wrote machine paths: $paths_file"
}

link_one() {
    local source="$1"
    local destination="$2"
    [[ -e "$source" || -L "$source" ]] || die "source does not exist: $source"
    local parent
    parent="$(dirname -- "$destination")"
    if ((DRY_RUN)); then
        info "[dry-run] link $source -> $destination"
        return 0
    fi
    make_dir "$parent"
    if [[ -L "$destination" ]] && [[ "$(readlink -f "$destination" 2>/dev/null || true)" == "$(readlink -f "$source")" ]]; then
        info "already linked: $destination"
        return 0
    fi
    backup_existing "$destination"
    ln -s -- "$source" "$destination"
    success "linked $source -> $destination"
}

deploy_links() {
    declare -A links=(
        ["zsh/zshrc"]="$TARGET_HOME/.zshrc"
        ["zsh/p10k.zsh"]="$TARGET_HOME/.p10k.zsh"
        ["nvim"]="$TARGET_HOME/.config/nvim"
        ["uv/uv.toml"]="$TARGET_HOME/.config/uv/uv.toml"
        ["npm/npmrc"]="$TARGET_HOME/.npmrc"
        ["git/gitconfig"]="$TARGET_HOME/.gitconfig"
        ["ssh/config"]="$TARGET_HOME/.ssh/config"
        ["conda/condarc"]="$TARGET_HOME/.condarc"
        ["vim/vimrc"]="$TARGET_HOME/.vimrc"
    )

    local source destination
    for source in "${!links[@]}"; do
        destination="${links[$source]}"
        [[ -e "$REPO_DIR/$source" || -L "$REPO_DIR/$source" ]] || {
            warn "source does not exist, skipped: $REPO_DIR/$source"
            continue
        }
        if [[ "$destination" == "$TARGET_HOME/.ssh/config" ]]; then
            if ((DRY_RUN == 0)); then
                make_dir "$TARGET_HOME/.ssh"
                chmod 700 "$TARGET_HOME/.ssh"
                chmod 600 "$REPO_DIR/$source"
            fi
        fi
        if [[ "$destination" == "$TARGET_HOME/.npmrc" && DRY_RUN -eq 0 ]]; then
            chmod 600 "$REPO_DIR/$source"
        fi
        link_one "$REPO_DIR/$source" "$destination"
    done
}

ensure_lazyvim() {
    local lazy_root="$DATA_DIR/.local/share/nvim/lazy"
    local lazy_nvim="$lazy_root/lazy.nvim"
    local lazyvim="$lazy_root/LazyVim"
    if [[ -d "$lazy_nvim" && -d "$lazyvim" ]]; then
        success "LazyVim already installed: $lazy_root"
        return 0
    fi
    if ((DRY_RUN)); then
        info "[dry-run] bootstrap lazy.nvim and LazyVim under $lazy_root"
        return 0
    fi
    ((INSTALL_MISSING)) || die 'LazyVim is missing; remove --no-install or install it manually'
    local nvim_bin="${APP_PATHS[nvim]}"
    [[ -x "$nvim_bin" ]] || die "nvim is not executable: $nvim_bin"
    make_dir "$DATA_DIR/.local/share/nvim"
    make_dir "$DATA_DIR/.local/state/nvim"
    make_dir "$DATA_DIR/.cache/nvim"
    info 'bootstrapping LazyVim plugins with headless Neovim'
    HOME="$TARGET_HOME" \
    XDG_CONFIG_HOME="$TARGET_HOME/.config" \
    XDG_DATA_HOME="$DATA_DIR/.local/share" \
    XDG_STATE_HOME="$DATA_DIR/.local/state" \
    XDG_CACHE_HOME="$DATA_DIR/.cache" \
    "$nvim_bin" --headless '+Lazy! sync' '+qa'
    [[ -d "$lazy_nvim" && -d "$lazyvim" ]] || die 'LazyVim bootstrap did not create expected plugin directories'
}

main() {
    parse_args "$@"
    choose_defaults
    validate_absolute_path HOME_DIR "$TARGET_HOME"
    validate_absolute_path DATA_DIR "$DATA_DIR"
    validate_absolute_path REPO_DIR "$REPO_DIR"
    [[ -d "$REPO_DIR" ]] || die "repository does not exist: $REPO_DIR"
    choose_interactive_settings

    check_writable_dir "$TARGET_HOME"
    check_writable_dir "$DATA_DIR"
    if [[ ! -d "$TARGET_HOME" ]]; then make_dir "$TARGET_HOME"; fi
    if [[ ! -d "$DATA_DIR" ]]; then make_dir "$DATA_DIR"; fi
    make_dir "$DATA_DIR/bin"
    make_dir "$DATA_DIR/apps"

    if ((DRY_RUN && INSTALL_MISSING == 0)); then
        check_dependencies || exit 1
        return 0
    fi

    configure_sources

    # Conda is resolved first because it is the no-sudo fallback for zsh.
    resolve_or_install conda
    resolve_or_install zsh
    resolve_or_install uv
    resolve_or_install nvim
    resolve_or_install fnm
    resolve_or_install npm
    ensure_zsh_stack

    write_paths_file
    deploy_links
    ensure_lazyvim

    if ((DRY_RUN)); then
        success 'dry-run complete; no files or applications were changed'
    else
        success 'deployment complete'
        info "home: $TARGET_HOME"
        info "data: $DATA_DIR"
        info 'No sudo, apt, chsh, or global installation was used.'
        if [[ "$APP_PATHS[zsh]" != /usr/* && "$APP_PATHS[zsh]" != /bin/* ]]; then
            warn "default shell was not changed; start it explicitly with: $APP_PATHS[zsh] -l"
        fi
    fi
}

main "$@"
