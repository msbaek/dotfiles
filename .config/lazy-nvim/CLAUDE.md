# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a LazyVim configuration directory for Neovim. It's a customized setup based on the LazyVim starter template with extensive Korean language support, Obsidian integration, and markdown-focused workflows.

## Common Commands

### Development and Formatting
```bash
# Format Lua files using StyLua
stylua .

# Check LazyVim health and configuration
:checkhealth
:Lazy

# Mason package management
:Mason                    # Open Mason UI
:MasonInstall <package>   # Install specific package
:MasonUpdate             # Update all packages
```

### LazyVim Operations
```bash
# Plugin management
:Lazy sync               # Update and sync all plugins
:Lazy clean              # Remove unused plugins
:Lazy profile            # Performance profiling

# Configuration reload
:source %               # Reload current file
:Telescope find_files   # Find configuration files quickly
```

## Architecture and Structure

### Core Configuration Flow
- **Entry Point**: `init.lua` - Bootstraps lazy.nvim and loads core configurations
- **Plugin System**: `lua/config/lazy.lua` - Main plugin setup with LazyVim integration
- **Base Configuration**: `lua/config/` directory contains:
  - `options.lua` - Editor options and custom winbar configuration
  - `keymaps.lua` - Extensive custom keybindings (Korean input, markdown workflows)
  - `autocmds.lua` - Custom autocommands
  - `colors.lua` - Color scheme utilities
  - `highlights.lua` - Custom highlight definitions

### Plugin Architecture
- **Plugins Directory**: `lua/plugins/` - Individual plugin configurations
- **Colorschemes**: `lua/plugins/colorschemes/` - Separate color scheme configs
- **LazyVim Extras**: Pre-configured language support for Go, Python, TypeScript, Docker, etc.

### Key Integrations
- **Obsidian.nvim**: Comprehensive Obsidian vault integration with Korean support
- **Markdown Ecosystem**:
  - `render-markdown.lua` - Enhanced markdown rendering
  - `img-clip.lua` - Image clipboard integration
  - `markdown-preview.lua` - Live preview capabilities
- **Language Servers**: Mason-managed LSPs for multiple languages
- **Tmux Integration**: `vim-tmux-navigator.lua` for seamless pane navigation

### Korean Language Features
- **Multi-language spelling**: English, Korean, and Spanish spell checking
- **Input method integration**: Karabiner-compatible keybindings
- **Obsidian vault support**: Korean markdown files with proper encoding

### Custom Workflow Features
- **Winbar Enhancement**: Shows hostname, buffer count, and full file path
- **Daily Note System**: Automated daily note creation with date formatting
- **TOC Management**: Automated markdown table of contents generation
- **Image Handling**: Clipboard to markdown image workflow
- **Fold Management**: Multi-level markdown heading folding system

### Important Configuration Notes
- **Python Virtual Environment**: Configured for Neovim python support at `~/.venvs/neovim/bin/python`
- **Spell Files**: Custom spell files in `spell/` directory for multiple languages
- **Concealment**: Set to level 2 for Obsidian compatibility
- **Auto-save**: Enabled through custom plugin configuration
- **Session Management**: Enhanced with `localoptions` for spell language persistence

### File Organization Patterns
- Plugin files ending with `.old` are disabled configurations
- Colorscheme plugins are separated into their own subdirectory
- Snippet definitions in `snippets/` directory for multiple languages
- Custom CSS files for markdown preview styling

This configuration is heavily customized for markdown writing, Korean language support, and Obsidian vault management workflows.
