## My dotfiles

This directory contains the dotfiles for my system

## Requirements

Ensure you have the following installed on your system

## Git

`brew install git`

## LayVim

```sh
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf .config/nvim/.git
```

## Stow

`brew install stow`

## Installation

First, check out the dotfiles repo in your $HOME directory using git

`git clone git@github.com/msbaek/dotfiles.git ~/dotfiles` `$ cd dotfiles`

then use GNU stow to create symlinks `$ stow .`
