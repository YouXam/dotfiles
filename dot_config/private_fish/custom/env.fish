if test -x /opt/homebrew/bin/brew
	eval (/opt/homebrew/bin/brew shellenv)
end
if which zoxide > /dev/null
	zoxide init fish | source
end
fish_add_path /usr/local/bin
