set -gx SHELL fish
if status is-interactive
end

for f in $HOME/.config/fish/custom/*.fish
	source $f
end
