# herdr-automatic-rename shell hook (2026-11-08): renames the herdr tab as soon as a command starts.
# Plugin: herdr plugin install qu8n/herdr-automatic-rename. No-op outside herdr or when the plugin is absent.
for _f in ${HOME}/.config/herdr/plugins/github-installations/herdr-automatic-rename-*/*/checkout/shell/hook.zsh(N) \
          ${HOME}/.config/herdr/plugins/github/herdr-automatic-rename-*/shell/hook.zsh(N); do
  source $_f; break
done
unset _f
