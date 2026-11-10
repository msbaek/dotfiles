export PATH=$HOME/.cargo/bin:$PATH

# Non-login, non-interactive zsh (launchd-started herdr server running `zsh -c` for keys.command)
# gets no Homebrew PATH from .zprofile, so add it here when it is missing.
if [[ -d /opt/homebrew/bin && ":$PATH:" != *":/opt/homebrew/bin:"* ]]; then
  export PATH=/opt/homebrew/bin:/opt/homebrew/sbin:$PATH
fi
