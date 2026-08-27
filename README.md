# Personal Dotfiles

This repository contains my personal macOS dotfiles configuration using GNU Stow for symlink management.

## Features

- **Multi-terminal Support**: WezTerm, Ghostty, Alacritty configurations
- **Window Management**: AeroSpace, Yabai, Rectangle, Hammerspoon
- **Custom Status Bar**: SketchyBar with modular plugins
- **Shell Configuration**: ZSH with Oh-My-Zsh and Powerlevel10k
- **Development Tools**: Git, tmux, Vim/Neovim, various CLI tools
- **Input Customization**: Karabiner-Elements with language switching

## Quick Setup

### 1. Prerequisites

Ensure you have the following installed:

```bash
# Install Homebrew if not already installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Git and Stow
brew install git stow
```

### 2. Clone Repository

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

### 3. Install Dependencies

```bash
brew bundle --file=Brewfile
```

### 4. Set Up Environment Variables

```bash
# Copy and edit API keys (if needed)
cp .env.ktown4u.example .env.ktown4u
# Edit .env.ktown4u with your actual API keys

# Copy and edit Git configuration
cp .gitconfig.user.example .gitconfig.user
# Edit .gitconfig.user with your Git user info
```

### 5. Set Up SSH Configuration (Optional)

```bash
# Add contents to your SSH config
cat .ssh-config.example >> ~/.ssh/config
# Edit ~/.ssh/config with your server information
```

### 6. Deploy Dotfiles

`--no-folding` is mandatory — see [Stow Conflicts](#stow-conflicts) for why.

```bash
stow --no-folding -t ~ .
```

### 7. Point Neovim at the Tracked Config

The LazyVim configuration is tracked in this repo as `.config/lazy-nvim`. Neovim
reads `~/.config/nvim`, so link the two:

```bash
ln -s ~/dotfiles/.config/lazy-nvim ~/.config/nvim
```

## Structure

### Core Configuration Files

- **Shell**: `.zshrc`, `.zprofile`, `.zshenv`
- **Terminal**: `.wezterm.lua`, `.config/ghostty/`, `.config/alacritty/`
- **Editor**: `.vimrc`, `.ideavimrc`, `.config/zed/`
- **Window Manager**: `.config/aerospace/`, `.hammerspoon/`
- **Status Bar**: `.config/sketchybar/`
- **Input**: `.config/karabiner/`
- **Git**: `.gitconfig`, `.gitconfig.user`

### Environment Variables

Sensitive information is stored in `.env.*` files (not tracked in Git):

- **`.env.ktown4u`**: Company-related API keys and settings
- **Templates**: `*.example` files show the expected format

## Security

This repository is designed to be safely shared publicly:

- ✅ **No sensitive data** in tracked files
- ✅ **Template files** provided for easy setup
- ✅ **Environment variables** properly separated
- ✅ **SSH and Git configs** excluded from tracking

## Maintenance

### Update Brewfile
```bash
brew bundle dump --force
```

### Check for missing packages
```bash
brew bundle cleanup --force
```

### Update dotfiles
```bash
cd ~/dotfiles
git pull
stow --no-folding -t ~ .
```

## Troubleshooting

### Missing API Keys
If you see warnings about missing environment variables:
1. Check if `.env.ktown4u` exists
2. Compare with `.env.ktown4u.example`
3. Restart terminal after changes

### SSH Connection Issues
1. Check `~/.ssh/config` configuration
2. Ensure key permissions: `chmod 600 ~/.ssh/your_key`
3. Verify server information

### Stow Conflicts
If stow reports conflicts:
```bash
stow --adopt --no-folding -t ~ .  # Adopt existing files
```

An app may rewrite its config as a real file between `stow -D` and the next
`stow`, which then conflicts. Diff it against the repo copy first; if identical,
delete it and re-stow.

### Never Stow Without `--no-folding`

Without it Stow folds a directory missing from `~` into a single symlink
(`~/.config -> ~/dotfiles/.config`), making the home path and the repository the
same object. `rm -rf ~/.config/<anything>` then deletes tracked files from the
repo, and `rm -rf ~/dotfiles` destroys gitignored assets that only exist locally
(`~/.config/nvim`, `~/.config/gh/hosts.yml`). To undo a folded deployment, run
both commands together — the home symlinks are absent in between:

```bash
stow -D -t ~ . && stow --no-folding -t ~ .
```

## Usage with dotfiles-private

This repository works together with a private companion repository for sensitive data.

### New Machine Setup

```bash
# 1. Clone public dotfiles
git clone https://github.com/msbaek/dotfiles ~/dotfiles
cd ~/dotfiles && stow --no-folding -t ~ .
brew bundle

# 2. Clone private dotfiles (optional - for personal machines)
git clone git@github.com:msbaek/dotfiles-private ~/dotfiles-private
# .gitconfig.user only — stowing the whole package collides with ~/.claude,
# and .zshrc sources the .env.* files by absolute path already.
ln -s ~/dotfiles-private/.gitconfig.user ~/.gitconfig.user
```

### Graceful Degradation

The public dotfiles work standalone. Private repo adds credentials:

| File | Behavior without private repo |
|------|-------------------------------|
| `.gitconfig.user` | Git `[include]` ignores missing files |
| `.claude/claude_desktop_config.json` | Claude Desktop uses default settings |
| `.env.ktown4u` | Already conditional: `[[ -f ]] && source` |

## License

Feel free to use any part of these configurations for your own setup.
