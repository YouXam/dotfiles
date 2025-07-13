set -gx SHELL fish
if status is-interactive
	source ~/.config/fish/custom/*.fish
end

if test -x /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv)
end
