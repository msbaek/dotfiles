# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the Ghostty terminal emulator configuration directory within a personal dotfiles repository. Ghostty is a modern GPU-accelerated terminal emulator that provides extensive customization options.

## Configuration Files

- `config` - Main Ghostty configuration file with comprehensive settings
- `config.org` - Commented template/documentation showing all available configuration options

## Common Commands

### Configuration Management
```bash
# Reload Ghostty configuration (if running)
ghostty --config-reload

# List available fonts
ghostty +list-fonts

# List available themes
ghostty +list-themes

# List available keybind actions
ghostty +list-actions

# Validate configuration
ghostty --config-file=config --validate
```

### Testing and Development
```bash
# Test configuration with specific file
ghostty --config-file=./config

# Launch with debug logging
ghostty --log-level=debug

# Test specific features
ghostty --window-decoration=false
ghostty --theme="Gruvbox Dark Hard"
```

## Configuration Architecture

### Current Configuration Highlights

- **Font**: Google Sans Code, 16pt with cursor block style
- **Theme**: Gruvbox Dark Hard with custom background opacity (0.95)
- **Keybindings**: tmux-style prefix keys using `cmd+s` as leader
- **Window**: Padding balanced, no decorations, hidden titlebar on macOS
- **Shell Integration**: Enabled with cursor and title features
- **Mouse**: Hidden while typing, 2x scroll multiplier

### Key Configuration Patterns

1. **Leader Key System**: Uses `cmd+s>` prefix for terminal management
   - `cmd+s>r` - Reload config
   - `cmd+s>x` - Close surface
   - `cmd+s>n` - New window
   - `cmd+s>c` - New tab

2. **Split Management**: Comprehensive split navigation and resizing
   - `cmd+d` - New split right
   - `cmd+shift+d` - New split down
   - `cmd+alt+arrow` - Navigate splits
   - `cmd+ctrl+arrow` - Resize splits

3. **Tab Management**: Full tab lifecycle support
   - Tab creation, navigation, and closing
   - Physical number key bindings for direct tab access

### Stow Integration

This configuration is deployed via GNU Stow from the parent dotfiles repository:
```bash
# Deploy from dotfiles root
stow .
```

The configuration files are symlinked to `~/.config/ghostty/` when stow is run.

## Development Workflow

When modifying Ghostty configuration:

1. Edit files in the dotfiles repository
2. Test changes immediately (Ghostty auto-reloads on config changes)
3. Use `cmd+shift+comma` to reload configuration manually if needed
4. Validate syntax with `ghostty --validate` if experiencing issues
5. Commit changes to dotfiles repository

## Important Notes

- Configuration uses macOS-specific features (titlebar styles, Option key handling)
- Some keybindings may conflict with system shortcuts on different platforms
- Font dependencies: Requires Google Sans Code font installation
- Background opacity requires compositing window manager support
- Shell integration works best with zsh/bash and requires proper shell setup

## Troubleshooting

### Common Issues

1. **Font not found**: Install Google Sans Code or change `font-family` setting
2. **Keybindings not working**: Check for conflicts with system shortcuts
3. **Theme not loading**: Verify theme name with `ghostty +list-themes`
4. **Config not reloading**: Use manual reload with `cmd+shift+comma`

### Debug Steps

```bash
# Check configuration validity
ghostty --config-file=config --validate

# Test minimal configuration
ghostty --config-file=/dev/null

# Check available options
ghostty --help
```
