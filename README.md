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
- Shared PATH, Cargo and optional fnm setup
- Shared package/model mirrors are configured here
- Machine-specific proxy, Conda runtime and CUDA settings live in `*.local.*`

### func.zsh / func.bash
- Shared function modules are loaded before optional machine-specific modules
- `star_proxy <server>` → Creates SSH reverse tunnel for proxy forwarding

### alias.zsh / alias.bash
- `ll`, `la`, `l` → ls variants with color
- `proxy_off` → Unset all proxy variables
- Machine-specific aliases such as EasyConnect, md2pdf, cc-switch and llama live in `alias.local.*`

### secrets.zsh / secrets.bash
- `MINERU_TOKEN` → OpenXLab API token

### prompt.bash (bash only)
- Custom colored prompt (P10k handles this for zsh)

## Deployment

```bash
cd ~/.dotfiles
bash deploy.sh
```

The deploy script:
1. Backs up existing files (`.bak`)
2. Removes old symlinks
3. Creates new symlinks from `~/.dotfiles/<module>` to `~/.<module>`
4. Handles SSH config permissions (700 for ~/.ssh, 600 for config)
5. Skips secrets files (must be created manually)

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
