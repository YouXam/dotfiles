set -gx SHELL fish
if status is-interactive
	for f in $HOME/.config/fish/custom/*.fish
        	source $f
    	end
end

if test -x /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv)
end

