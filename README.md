# Dotfiles

My shell configuration managed via Git with symbolic links for easy deployment across machines.

**Note**: This repo excludes secrets files. Copy from `*.example.zsh` / `*.example.bash` and fill in actual values.

## Architecture

```
.dotfiles/               # Git repository root
├── deploy.sh            # Deployment script (creates symlinks)
├── mirrors.sh           # Configure and verify download mirrors (see Mirrors)
├── README.md            # This file
├── .gitignore
│
├── zsh/                 # Zsh (Oh My Zsh) configuration
│   ├── zshrc            # Main entry point (~/.zshrc ->)
│   ├── p10k.zsh         # Powerlevel10k configuration (~/.p10k.zsh ->)
│   └── modules/         # Modular components
│       ├── exports.zsh  # Shared environment variables
│       ├── exports.local.zsh # Machine-specific environment variables (local only)
│       ├── secrets.zsh  # Sensitive tokens (gitignored)
│       ├── func.zsh     # Shared custom functions
│       ├── func.local.zsh # Machine-specific functions (local only)
│       ├── alias.zsh    # Shared command aliases
│       └── alias.local.zsh # Machine-specific command aliases (local only)
│
├── nvim/                # Neovim configuration (~/.config/nvim ->)
│   ├── init.lua         # Neovim entry point
│   ├── lua/              # Lua configuration and plugins
│   └── lazy-lock.json    # Plugin lockfile
│
├── uv/                  # uv configuration (~/.config/uv/uv.toml ->)
│   └── uv.toml           # Python package index configuration
├── pip/                 # pip configuration (~/.config/pip/pip.conf ->)
│   └── pip.conf          # Python package index configuration
├── npm/                 # npm and yarn configuration
│   ├── npmrc             # Node package registry configuration (~/.npmrc ->)
│   └── yarnrc            # Yarn registry configuration (~/.yarnrc ->)
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

The `*.local.zsh` and `*.local.bash` files are machine-local files. They are
ignored by Git and are never linked or copied by `deploy.sh`. The public
`zsh/zshrc` only loads them when the generated machine-local paths file sets
`DOTFILES_LOCAL_PROFILE=repo`.

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

### uv / pip / npm / yarn
- `uv/uv.toml` is linked to `~/.config/uv/uv.toml`
- `pip/pip.conf` is linked to `~/.config/pip/pip.conf`
- `npm/npmrc` is linked to `~/.npmrc`, `npm/yarnrc` to `~/.yarnrc`

## Mirrors

`mirrors.sh` owns every download source: `uv/uv.toml`, `pip/pip.conf`,
`npm/npmrc`, `npm/yarnrc`, `conda/condarc` and the `>>> mirrors >>>` block of
both export modules. It never writes outside the repository, so deploy.sh links
the result into `$HOME`.

```bash
bash mirrors.sh status                    # what the repository configures now
bash mirrors.sh probe --quick             # fetch a small artifact per source
bash mirrors.sh probe                     # plus git remotes, a brew bottle and a uv Python
bash mirrors.sh apply --dry-run           # show the diff of a profile change
bash mirrors.sh apply                     # `current` profile (mirrors, default)
bash mirrors.sh apply --mirror official   # upstream sources, export block emptied
```

Profiles are `current`, `official` and `custom`. Any URL can also be overridden
per call: `--npm-registry`, `--pypi-index`, `--node-mirror`, `--conda-channel`,
`--conda-default-channel` (repeatable), `--uv-python-mirror`,
`--brew-bottle-domain`, `--brew-api-domain`, `--brew-git-remote`,
`--brew-core-git-remote`, `--brew-cask-git-remote`, `--hf-endpoint`. `apply` is
idempotent, and applying a profile twice leaves every file byte-identical.

### One shot on a machine without the dotfiles

`--home` writes into a user directory instead of the repository, so a machine
that already has fnm, uv, conda, brew and a Hugging Face client only needs one
command:

```bash
bash mirrors.sh apply --home "$HOME"
bash mirrors.sh status --home "$HOME"     # what landed
```

That is the whole mirror setup: `.config/uv/uv.toml`, `.config/pip/pip.conf`,
`.npmrc`, `.yarnrc`, `.condarc`, plus the `>>> mirrors >>>` block in the shell
files that actually get read, because they differ per invocation:

| file | read by |
|------|---------|
| `.zshrc` | interactive zsh (`zsh -lic`) |
| `.zshenv` | every zsh, including the non-interactive one sshd starts |
| `.bashrc` | interactive bash (`bash -ic`) |
| `.bash_profile`, `.bash_login` or `.profile` | login bash and dash (`bash -lc`) |

The login file is only touched when it does not already source `.bashrc`, so
nothing is duplicated. New blocks are inserted after the shell file's leading
comments rather than appended at the end: a `.bashrc` that returns early for
non-interactive shells (the usual Ubuntu guard) never reaches a block below it,
which would leave `bash -lc` without the mirrors. An existing rc file keeps its
content, a symlinked one is left alone (the dotfiles own it then, and the block
belongs in the export modules), and a shell family whose rc file is a symlink
gets no extra files. Config files take effect immediately; the exports need a
new shell. One gap is unavoidable: `ssh host 'cmd'` where the login shell is
bash runs a non-interactive, non-login bash that reads no rc file at all - use
`ssh host 'bash -lc cmd'` or run the command from a login shell.

Over SSH, without copying the script across first:

```bash
ssh server 'bash -s apply --home "$HOME"' < mirrors.sh
```

Installer downloads are deliberately not mirrored: `astral.sh/uv/install.sh`
and `fnm.vercel.app/install` are reachable as-is, and nobody mirrors
`astral-sh/uv` releases (NJU's `github-release` carries only
`python-build-standalone`). Miniconda, however, is mirrored at
`https://mirror.nju.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh`.

Notes that are easy to get wrong:

- `UV_PYTHON_INSTALL_MIRROR` has to live in the shell environment: uv silently
  ignores a `python-install-mirror` key in `uv.toml`.
- The NJU github-release mirror has no `/releases/download` segment:
  `https://mirror.nju.edu.cn/github-release/astral-sh/python-build-standalone`.
- USTC's bottle host answers 403 to a bare `curl/...` user agent, so anything
  other than brew has to identify itself.
- `conda/condarc` points `defaults` at mirrors through `default_channels`;
  without that, every repodata refresh pulls ~159 MB from repo.anaconda.com.
  Upstream `pkgs/free` is frozen at Python <= 3.6 and is not listed.

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

The managed links are limited to Conda, Git, fnm/Node/npm/yarn, Neovim, SSH,
pip, uv, Vim and Zsh. Machine-local modules are intentionally outside deploy's
scope.
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
