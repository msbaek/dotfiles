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

```bash
stow .
```

### 7. Install LazyVim (Optional)

```bash
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf .config/nvim/.git
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
stow .
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
stow --adopt .  # Adopt existing files
```

## Usage with dotfiles-private

This repository works together with a private companion repository for sensitive data.

### New Machine Setup

```bash
# 1. Clone public dotfiles
git clone https://github.com/msbaek/dotfiles ~/dotfiles
cd ~/dotfiles && stow .
brew bundle

# 2. Clone private dotfiles (optional - for personal machines)
git clone git@github.com:msbaek/dotfiles-private ~/dotfiles-private
cd ~/dotfiles-private && stow .
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
