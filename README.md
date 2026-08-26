# Dotfiles

My shell configuration managed via Git with symbolic links for easy deployment across machines.

**Note**: This repo excludes secrets files. Copy from `*.example.zsh` / `*.example.bash` and fill in actual values.

## Architecture

```
.dotfiles/               # Git repository root
├── deploy.sh            # Deployment script (creates symlinks)
├── README.md            # This file
├── .gitignore
│
├── zsh/                 # Zsh (Oh My Zsh) configuration
│   ├── zshrc            # Main entry point (~/.zshrc ->)
│   ├── p10k.zsh         # Powerlevel10k configuration (~/.p10k.zsh ->)
│   └── modules/         # Modular components
│       ├── exports.zsh  # Shared environment variables
│       ├── exports.local.zsh # Machine-specific environment variables
│       ├── secrets.zsh  # Sensitive tokens (gitignored)
│       ├── func.zsh     # Shared custom functions
│       ├── func.local.zsh # Machine-specific functions
│       ├── alias.zsh    # Shared command aliases
│       └── alias.local.zsh # Machine-specific command aliases
│
├── nvim/                # Neovim configuration (~/.config/nvim ->)
│   ├── init.lua         # Neovim entry point
│   ├── lua/              # Lua configuration and plugins
│   └── lazy-lock.json    # Plugin lockfile
│
├── uv/                  # uv configuration (~/.config/uv/uv.toml ->)
│   └── uv.toml           # Python package index configuration
├── npm/                 # npm configuration (~/.npmrc ->)
│   └── npmrc             # Node package registry configuration
├── apt/                 # Current machine apt source snapshot (not auto-linked)
│   └── sources.list.d/   # Ubuntu, Docker, GitHub CLI and CUDA sources
│
├── bash/                # Bash configuration (legacy, still maintained)
│   ├── bashrc           # Main entry point (~/.bashrc ->)
│   └── modules/
│       ├── exports.bash
│       ├── secrets.bash
│       ├── func.bash
│       ├── alias.bash
│       └── prompt.bash
│
├── git/gitconfig        # ~/.gitconfig ->
├── ssh/config           # ~/.ssh/config ->
├── vim/vimrc            # ~/.vimrc ->
├── conda/condarc        # ~/.condarc ->
└── profile              # ~/.profile ->
```

## Module Details

### exports.zsh / exports.bash
- Shared PATH, Cargo, fnm and package/model mirrors
- The Zsh machine-specific proxy, CUDA and Conda settings remain outside deploy's scope

### func.zsh / func.bash
- Shared function modules are loaded before optional machine-specific modules
- `star_proxy <server>` → Creates SSH reverse tunnel for proxy forwarding

### alias.zsh / alias.bash
- `ll`, `la`, `l` → ls variants with color
- `proxy_off` → Unset all proxy variables
- Machine-specific Zsh aliases such as EasyConnect, md2pdf, cc-switch and llama live in `alias.local.zsh`

### secrets.zsh / secrets.bash
- `MINERU_TOKEN` → OpenXLab API token

### prompt.bash (bash only)
- Custom colored prompt (P10k handles this for zsh)

### Neovim
- The complete `~/.config/nvim` directory is managed by the `nvim/` symlink
- LazyVim configuration and plugin lockfile are kept together in the repository

### uv / npm
- `uv/uv.toml` is linked to `~/.config/uv/uv.toml`
- `npm/npmrc` is linked to `~/.npmrc`

### apt
- Active apt source files are kept as a snapshot under `apt/sources.list.d/`
- They are not linked by `deploy.sh` because apt configuration is system-owned and distribution-specific

## Deployment

```bash
cd ~/.dotfiles
bash deploy.sh
```

`deploy.sh` supports both interactive use and direct command-line parameters. It only
writes below the selected home and data directories and never uses `sudo`, `apt`,
`chsh` or a system-wide prefix.

The managed links are limited to Conda, Git, fnm/Node/npm, Neovim, SSH, uv, Vim
and Zsh.
Bash, `.profile`, apt sources and repository machine-specific modules are outside
deploy's scope.

For a server with a small home directory, use:

```bash
bash deploy.sh --home /home/starwink --data /data/starwink
```

The home directory stores symlinks and small configuration files. The data directory
stores user-installed applications, fnm-managed Node versions, Conda
packages/environments, uv cache/tools/Python, npm global packages and Neovim plugin
data. Passing the same path for both is supported.

The required applications are `zsh`, `nvim`, `uv`, `fnm`, npm and Miniconda.
Existing executables are detected first. Missing applications are installed under
`--data`; alternatively, pass an existing path such as:

```bash
bash deploy.sh --home /home/starwink --data /data/starwink \
  --zsh-path /data/starwink/bin/zsh \
  --nvim-path /data/starwink/bin/nvim \
  --uv-path /data/starwink/bin/uv \
  --fnm-path /data/starwink/bin/fnm \
  --conda-path /data/starwink/apps/miniconda \
  --no-install
```

When npm is missing, deploy uses fnm to install the selected Node version (LTS by
default), so Node and npm remain inside `--data` and no system-wide Node/npm is
installed. Use `--node-version VERSION` and `--node-mirror URL` to override the
fnm-managed Node version and download source. Installing fnm itself requires an
existing `unzip` command; deploy does not install system packages or use sudo.

Useful modes:

```bash
bash deploy.sh --check --home /home/starwink --data /data/starwink
bash deploy.sh --dry-run --home /home/starwink --data /data/starwink
bash deploy.sh --yes --non-interactive --home /home/starwink --data /data/starwink
```

Use `--mirror current`, `--mirror official` or `--mirror custom` plus the URL
overrides to choose download sources before installation. The deploy script does
not load or modify any repository machine-specific module. Existing destination
files are timestamp-backed up before symlinking.

## Secret Management

Secrets files are gitignored. After cloning the repo:

```bash
# For zsh
cp zsh/modules/secrets.example.zsh zsh/modules/secrets.zsh
vim zsh/modules/secrets.zsh  # Fill in actual values

# For bash
cp bash/modules/secrets.example.bash bash/modules/secrets.bash
vim bash/modules/secrets.bash  # Fill in actual values
```

## Key Differences: Bash vs Zsh

| Feature | Bash | Zsh (OMZ) |
|---------|------|-----------|
| Prompt | Custom prompt.bash | Powerlevel10k |
| Git completion | Basic | OMZ git plugin (rich) |
| Theme | Plain | powerlevel10k |
| Auto-suggestions | ❌ | zsh-autosuggestions |
| Syntax highlighting | ❌ | zsh-syntax-highlighting |
| `z` directory jumper | ❌ | z plugin |

## Shell Priority

Zsh is the primary shell. Bash is kept for:
- Compatibility with scripts that require bash
- Fallback in case zsh has issues

Both share the same conceptual structure (exports → secrets → func → alias).

## Environment

- OS: WSL2 (Ubuntu)
- Terminal: Windows Terminal
- Theme: Powerlevel10k (instant prompt enabled)
- Plugins: git, z, zsh-autosuggestions, zsh-syntax-highlighting
- Package Manager: Conda (Miniconda), fnm, Cargo
