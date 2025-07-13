function h;
	set -gx https_proxy http://localhost:7890
	set -gx http_proxy http://localhost:7890
	eval $argv
end
