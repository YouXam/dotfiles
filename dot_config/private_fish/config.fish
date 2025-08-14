set -gx SHELL fish
set -gx EDITOR vim
if status is-interactive
end

for f in $HOME/.config/fish/custom/*.fish
	source $f
end
