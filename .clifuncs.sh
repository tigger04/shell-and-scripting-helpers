. ~/.qfuncs.sh

[[ "$user_interactive" == "true" ]] || return

yt_get_title() {
	# yt-dlp just get the title and return it to stdout
	yt-dlp --quiet --print title "$1"
}

yt_extract_by_regex() {
	# curl a url and extract all yt links that match regex: numbers from 70 to 120
	# chars long
	curl -s "$1" | grep -oP "$youtube_id_regex" | grep -oP "[a-zA-Z0-9_-]{70,120}"

	# curl a url and extract all yt links that match regex: numbers from 70 to 120
	# chars long
	curl -s "$1" | grep -oP "$youtube_id_regex" | grep -oP "[a-zA-Z0-9_-]{70,120}"

}

tigger_dev_set_git_status_icon() {
	# this can be used in .bashrc to set the git status icon in the prompt
	# without resorting to third party tools etc

	local git_check_remote_timeout=300
	local git_root_dir git_status git_last_fetch git_remote_branch git_branch_current
	git_branch_string=""

	if [[ $_os == Darwin ]]; then
		stat=gstat
	else
		stat=stat
	fi

	if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
		# git_status_icon="🌐"
		# git_status_icon="🛜🌀📶🆗"
		git_status_icon="🌀"
	else
		git_status_icon=""
		return
	fi

	read -r git_root_dir < <(git rev-parse --show-toplevel)
	read -r git_status < <(git status --porcelain)
	read -r git_branch_current < <(git branch --show-current 2>/dev/null)

	if ! [[ ${git_branch_current,,} =~ ^(master|main)$ ]]; then
		git_branch_string="🌲($git_branch_current)"
	fi

	if [ -n "$git_status" ]; then
		git_status_icon="🌟"
		return
	fi

	if ! [ -e "$git_root_dir"/.git/FETCH_HEAD ]; then
		git_status_icon="❓"
		return
	fi

	read -r git_last_fetch < <($stat -c %Y "$git_root_dir"/.git/FETCH_HEAD)
	if [ $((EPOCHSECONDS - git_last_fetch)) -gt $git_check_remote_timeout ]; then
		git fetch >/dev/null 2>&1 &
		disown
		return
	fi

	if ! read -r git_remote_branch < <(git rev-parse --abbrev-ref --symbolic-full-name "@{u}") >/dev/null 2>&1; then
		git_status_icon="🔴"
		return
	fi

	if ! git diff --quiet "$git_remote_branch"; then
		git_status_icon="⏬"
	fi
}

fdw() {
	# find a word or words in sequence (but not necessarily together)
	local query="$*"
	query="${query// /\b.\*\b}"
	query="\b$query\b"

	show_cmd_execute fd "$query"
}

fd1() {
	# find using fd query with max depth=1
	local find_query=()
	local exec_query=()

	while [ $# -gt 0 ]; do
		if [[ "$1" == "-x" ]]; then
			exec_query+=("$@")
			break
		else
			find_query+=("$1")
			shift
		fi
	done

	if [ ${#find_query} -eq 0 ]; then
		find_query=(".")
	fi

	local fd_combined_query=("${find_query[@]}" -d1 "${exec_query[@]}")

	# declare -p fd_combined_query
	show_cmd_execute fd "${fd_combined_query[@]}"

	# show_cmd_execute fd "$@" --max-depth=1
}

### shell quick functions ###

aliasd() {
	local aliasfile="$HOME/.aliases.sh"

	timestamp timestamp

	regex="^([^=]+)[[:space:]]*=[[:space:]]*([^=]+)$"
	if [[ $* =~ $regex ]]; then
		new_alias_key="${BASH_REMATCH[1]}"
		# shellcheck disable=SC2016
		new_alias_value="${BASH_REMATCH[2]/$HOME/'$HOME'}"
	else
		new_alias_dir="$PWD"
		pwd_base="$(basename "$PWD")"
		# shellcheck disable=SC2016
		new_alias_value="cd \"${new_alias_dir/$HOME/'$HOME'}\""

		if [ -n "$1" ]; then
			new_alias_key="$1"
		else
			new_alias_key="$pwd_base"
		fi

	fi

	echo >>"$aliasfile"
	echo -e "alias $new_alias_key='$new_alias_value' # via aliasd $timestamp" >>"$aliasfile"
	thinbanner "$aliasfile"
	tail "$aliasfile"
	hline
	warn "sourcing $aliasfile"
	# shellcheck disable=SC1090
	. "$aliasfile"
}

aliasdf() {
	# search aliases
	alias -p | mygrep "$*"
}

mkcd() {
	if [[ $# -ne 1 ]]; then
		echo incorrect number of args provided >&2
	else
		if [ -d "$1" ]; then
			warn "$1 already exists!"
			info "don't worry ... I will let you away with it 🙃"
		else
			mkdir -pv "$1"
		fi
		cd "$1" || echo something went terribly wrong >&2
	fi
}

trash() {
	# just wraps the trash command

	read -r trash_cmd < <(which trash)
	info "⚡ trash $*"
	"$trash_cmd" -v "$@"
}

rgg() {
	if  [[ $1 =~ ^-([0-9]+)$ ]]; then
		depth=${BASH_REMATCH[1]}
		shift
	else
		depth=1
	fi

	rg "$@" --max-depth=$depth
}
alias rg1='rgg -1'

rgw() {
	rg "$@" -w
}

rw() {
	rg "$@" -w --max-depth=1
}

# in your .bashrc/.zshrc/*rc
alias bathelp='bat --plain --language=help'
help() {
	{
		"$@" --help 2>&1 | bathelp
		echo
		hline TLDR
		tldr "$1"
	} 2>&1 | bathelp
}

h() {
	# just does a cd $HOME if no args
	# otherwise it wraps the help function above

	if [ $# -eq 0 ]; then
		cd ~ || return $?
	else
		help "$@"
	fi
}

cdlast() {
	# Get the last command from history
	last_command=${HISTCMD}

	# Extract the last argument (assumes no spaces in filename)
	last_arg=${last_command##* }

	# Check if last_arg is a file and change directory if it exists
	if [[ -f "$last_arg" ]]; then
		cd "$last_arg"
	else
		echo " '$last_arg' is not a file or doesn't exist."
	fi
}

code() {
	# wraps the code (VSCode) cli command
	# so that `code` with no args will open the current directory in VSCode

	local code
	read -r code < <(which code)

	if [ $# -eq 0 ]; then
		$code .
	else
		$code "$@"
	fi
}
alias c=code

### git aliases ###
alias status='git status'
alias s='git status'
alias checkout='git checkout'
alias clone='git clone'
alias push='git push'
alias fetch='git fetch'
# NB 'add' is a script in ~/bin

commit() {
	local fallback_commit_message="$USER@$HOSTNAME:cli"
	fallback_commit_message="${*:-$fallback_commit_message}"

	show_cmd_execute git commit -am "$fallback_commit_message"
}

# alias pull='git pull'
pull() {
	local git_parent_module
	read -r git_parent_module < <(git rev-parse --show-superproject-working-tree)

	if [ -n "$git_parent_module" ]; then
		warn "You are in a submodule, you should pull from the parent repo"
		return
		# pushd "$git_parent_module" || return
		# show_cmd_execute git pull --recurse-submodules
		# popd || return
	else
		show_cmd_execute git pull origin master --recurse-submodules
      show_cmd_execute git submodule update --remote
	fi
}

###

visswitch() {
	case "$VISUAL" in
	nvim)
		export VISUAL=code--wait
		export VISUAL_NOWAIT=code
		;;
	code | code--wait)
		export VISUAL=nvim
		export VISUAL_NOWAIT=$VISUAL
		;;
	*)
		export VISUAL=code--wait
		;;
	esac
	declare -p VISUAL VISUAL_NOWAIT
}

hiya() {
	# test function to interrogate how BASH_SOURCE works
	declare -p BASH_SOURCE
	echo hiya
}

fdkcp() {
	# this function copies files matching a pattern to a datestamped [maybe new]
	# directory under ~/scratch/[DATESTAMP]

	local pattern="$1"
	datestamp -q
	target_dir=~/scratch/$DATESTAMP

	if [ $# -eq 0 ] || [[ $1 =~ ^--?h(elp)?$ ]]; then
		echo "Usage: fdkx [PATTERN]"
		echo "WTF: copy matching files to ~/scratch/$DATESTAMP"
		return 0
	fi

	mkdir -pv "$target_dir" || return 1

	fd "$pattern" ~/desk/ |
		while read -r dk_file; do

			read -r dk_nice < <(basename "$dk_file")

			if [[ $dk_nice =~ ^20[0-9]{2}-[01][0-9]-[0-3][0-9]-[0-9]+\.[0-9]{2}- ]]; then
				warn "$dk_nice: skipping"
			else
				if \cp -vn "$dk_file" "$target_dir"; then
					filename "$dk_nice"
				else
					errortext "$dk_nice: fail"
					continue
				fi
			fi
		done

	nicepath "$target_dir"
	info "target: $REPLY"
}

fdk() {
	# find files in ~/desk/ matching the given pattern
	fd "$@" ~/desk/
}

dll() {
	pushd ~/Downloads >/dev/null || return 1
	ls -l
	popd >/dev/null || return 1
}

pandoc() {
    if [[ $* =~ \<--?d(efaults)?\> ]]; then
        # If user explicitly specifies --defaults, don't interfere
        show_cmd_execute command pandoc "$@"
    else
        # Otherwise, use our common defaults
        show_cmd_execute command pandoc --defaults=defaults "$@"
    fi
}
