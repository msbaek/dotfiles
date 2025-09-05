# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal dotfiles repository containing macOS system configurations and development environment setup files. The repository uses GNU Stow for symlink management to deploy dotfiles to the home directory.

## Common Commands

### Installation and Setup
```bash
# Install dependencies via Homebrew
brew bundle --file=Brewfile

# Deploy dotfiles using GNU Stow
stow .

# Install LazyVim (if needed)
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf .config/nvim/.git
```

### Package Management
```bash
# Update Brewfile with currently installed packages
brew bundle dump --force

# Install packages from Brewfile
brew bundle install

# Check which packages are not in Brewfile
brew bundle cleanup --force
```

## Architecture and Structure

### Core Components

- **Shell Configuration**: `.zshrc`, `.zprofile`, `.zshenv` - ZSH shell setup with Oh-My-Zsh and Powerlevel10k
- **Terminal Emulators**:
  - `.wezterm.lua` - WezTerm terminal configuration
  - `.config/ghostty/` - Ghostty terminal settings
  - `.config/alacritty/` - Alacritty terminal configuration
- **Editors**:
  - `.vimrc`, `.vimrc.after` - Vim configuration
  - `.ideavimrc` - IntelliJ Vim plugin settings
  - `.config/zed/` - Zed editor configuration
- **Window Management**:
  - `.config/aerospace/` - AeroSpace tiling window manager
  - `.config/yabai/`, `.config/skhd/` - Yabai and SKHD for window management
  - `.hammerspoon/` - Hammerspoon automation scripts
  - `RectangleConfig.json` - Rectangle window manager settings
- **Status Bar**: `.config/sketchybar/` - Custom macOS status bar with plugins and themes
- **Input Management**: `.config/karabiner/` - Karabiner-Elements key remapping
- **Development Tools**:
  - `.gitconfig`, `.gitconfig.user` - Git configuration
  - `.tmux.conf` - tmux terminal multiplexer settings
  - `Brewfile` - Homebrew package definitions

### Configuration Directory Structure

- `.config/` - XDG-compliant application configurations
- `.claude/` - Claude AI assistant configurations and agents
- `.serena/` - Serena language server configurations
- `Library/` - macOS application support files

### Key Features

- **Multi-terminal Support**: Configurations for WezTerm, Ghostty, Alacritty, and Kitty
- **Tiling Window Management**: Multiple options (AeroSpace, Yabai, Rectangle, Hammerspoon)
- **Custom Status Bar**: SketchyBar with modular plugins for system monitoring
- **Input Customization**: Karabiner for key remapping with language switching support
- **Development Environment**: Comprehensive setup for multiple languages and tools

### Stow Integration

The repository is designed to work with GNU Stow, which creates symlinks from the repository to the appropriate locations in the home directory. Files and directories in the root are symlinked to `~/` when running `stow .`.

## Development Workflow

When making changes to configurations:
1. Edit files in the dotfiles repository
2. Test changes in the target environment
3. Use `stow .` to deploy changes (Stow handles existing symlinks gracefully)
4. Update Brewfile if new packages are added
5. Consider compatibility across different macOS versions

## Important Notes

- This repository contains personal configurations and may need adaptation for other users
- Some configurations depend on specific fonts (Meslo Nerd Font, SF Pro) and applications installed via Brewfile
- Karabiner configuration includes Korean/English language switching keybindings
- SketchyBar configuration is modular with separate plugin files for different system monitors
- Some symlinks point to external directories (like `.hammerspoon` and other app-specific configs)
