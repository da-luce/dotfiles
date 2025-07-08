# shellcheck shell=bash
# Displays a green or red ● depending on internet connectivity (via ping).

run_segment() {
	if __is_online; then
		echo "●"
		return 0  # Green if successful
	else
		echo "●"
		return 1  # Red if offline
	fi
}

__is_online() {
	ping -q -c 1 -W 1 8.8.8.8 >/dev/null 2>&1
}

# Optional config for future customization
generate_segmentrc() {
	read -r -d '' rccontents <<EORC
# Target to ping for determining online status.
# Default is 8.8.8.8 (Google DNS).
export TMUX_POWERLINE_SEG_CONNECTION_DOT_TARGET="8.8.8.8"
EORC
	echo "$rccontents"
}
