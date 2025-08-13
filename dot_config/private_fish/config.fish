set -gx SHELL fish
set -gx EDITOR vim
if status is-interactive
end

for f in $HOME/.config/fish/custom/*.fish
	source $f
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
