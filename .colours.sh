#!/usr/local/bin/bash

# did a script disable colours? fine, have a boring life :)
[ $disable_colors ] && return

# "normal" variables, should work with older versions of bash<5 :

# style_reset=$colour_reset
not_italic=$'\e[23m'
not_underline=$'\e[24m'
not_bold=$'\e[22m'
underline=$'\e[4m'
italic=$'\e[3m'
bold=$'\e[1m'
bolditalic=$'\e[1m\e[3m'
dim=$'\e[2m'
blink=$'\e[5m' # oh god why does this even exist
invert=$'\e[7m'

strike=$'\e[9m' # problematic

# regular colors
black=$'\e[0;30m'  # black
red=$'\e[0;31m'    # red
green=$'\e[0;32m'  # green
yellow=$'\e[0;33m' # yellow
blue=$'\e[0;34m'   # blue
purple=$'\e[0;35m' # purple
cyan=$'\e[0;36m'   # cyan
white=$'\e[0;37m'  # white

# bold
bblack=$'\e[1;30m'  # black
bred=$'\e[1;31m'    # red
bgreen=$'\e[1;32m'  # green
byellow=$'\e[1;33m' # yellow
bblue=$'\e[1;34m'   # blue
bpurple=$'\e[1;35m' # purple
bcyan=$'\e[1;36m'   # cyan
bwhite=$'\e[1;37m'  # white

# underline
ublack=$'\e[4;30m'  # black
ured=$'\e[4;31m'    # red
ugreen=$'\e[4;32m'  # green
uyellow=$'\e[4;33m' # yellow
ublue=$'\e[4;34m'   # blue
upurple=$'\e[4;35m' # purple
ucyan=$'\e[4;36m'   # cyan
uwhite=$'\e[4;37m'  # white

# background
on_black=$'\e[40m'  # black
on_red=$'\e[41m'    # red
on_green=$'\e[42m'  # green
on_yellow=$'\e[43m' # yellow
on_blue=$'\e[44m'   # blue
on_purple=$'\e[45m' # purple
on_cyan=$'\e[46m'   # cyan
on_white=$'\e[47m'  # white

# high intensity
iblack=$'\e[0;90m'  # black
ired=$'\e[0;91m'    # red
igreen=$'\e[0;92m'  # green
iyellow=$'\e[0;93m' # yellow
iblue=$'\e[0;94m'   # blue
ipurple=$'\e[0;95m' # purple
icyan=$'\e[0;96m'   # cyan
iwhite=$'\e[0;97m'  # white

# bold high intensity
biblack=$'\e[1;90m' # black
grey="$biblack"
bired=$'\e[1;91m'    # red
bigreen=$'\e[1;92m'  # green
biyellow=$'\e[1;93m' # yellow
biblue=$'\e[1;94m'   # blue
bipurple=$'\e[1;95m' # purple
bicyan=$'\e[1;96m'   # cyan
biwhite=$'\e[1;97m'  # white

# high intensity backgrounds
on_iblack=$'\e[0;100m'  # black
on_ired=$'\e[0;101m'    # red
on_igreen=$'\e[0;102m'  # green
on_iyellow=$'\e[0;103m' # yellow
on_iblue=$'\e[0;104m'   # blue
on_ipurple=$'\e[0;105m' # purple
on_icyan=$'\e[0;106m'   # cyan
on_iwhite=$'\e[0;107m'  # white

# reset
ansi_off=$'\e[0m' # text reset
nocolor="$ansi_off"
nocolour="$ansi_off"

# point of no return!
# only the reasonable versions of bash can have nice things
if ! [ ${#BASH_VERSINFO[0]} -ge 5 ]; then
   return
fi
# we let old shells politely out the door

declare -A blockmoji

blockmoji[red]='🟥'
blockmoji[green]='🟩'
blockmoji[blue]='🟦'
blockmoji[orange]='🟧'
blockmoji[yellow]='🟨'
blockmoji[purple]='🟪'
blockmoji[brown]='🟫'
blockmoji[black]='⬛'
blockmoji[white]='⬜'
blockmoji[Darwin]='🍏'
blockmoji[Linux]='🐧'

# some of this stuff is only legacy for my old scripts anyway

declare -A ansi

# NOTE: using this in a prompt/readline situation where calculating the number of
#       chars is important it may be best to escape with \e and like so:
#
#       ansi[not_italic]=$'\e\e[23m'

ansi[not_italic]=$'\e[23m'
ansi[not_underline]=$'\e[24m'
ansi[not_bold]=$'\e[22m'
ansi[underline]=$'\e[4m'
ansi[italic]=$'\e[3m'
ansi[bold]=$'\e[1m'
ansi[bolditalic]=$'\e[1m\e[3m'
ansi[dim]=$'\e[2m'
ansi[strike]=$'\e9m'

# regular colors
ansi[black]=$'\e[0;30m'  # black
ansi[red]=$'\e[0;31m'    # red
ansi[green]=$'\e[0;32m'  # green
ansi[yellow]=$'\e[0;33m' # yellow
ansi[blue]=$'\e[0;34m'   # blue
ansi[purple]=$'\e[0;35m' # purple
ansi[cyan]=$'\e[0;36m'   # cyan
ansi[white]=$'\e[0;37m'  # white

# bold
ansi[bblack]=$'\e[1;30m'  # black
ansi[bred]=$'\e[1;31m'    # red
ansi[bgreen]=$'\e[1;32m'  # green
ansi[byellow]=$'\e[1;33m' # yellow
ansi[bblue]=$'\e[1;34m'   # blue
ansi[bpurple]=$'\e[1;35m' # purple
ansi[bcyan]=$'\e[1;36m'   # cyan
ansi[bwhite]=$'\e[1;37m'  # white

# underline
ansi[ublack]=$'\e[4;30m'  # black
ansi[ured]=$'\e[4;31m'    # red
ansi[ugreen]=$'\e[4;32m'  # green
ansi[uyellow]=$'\e[4;33m' # yellow
ansi[ublue]=$'\e[4;34m'   # blue
ansi[upurple]=$'\e[4;35m' # purple
ansi[ucyan]=$'\e[4;36m'   # cyan
ansi[uwhite]=$'\e[4;37m'  # white

# background
ansi[on_black]=$'\e[40m'  # black
ansi[on_red]=$'\e[41m'    # red
ansi[on_green]=$'\e[42m'  # green
ansi[on_yellow]=$'\e[43m' # yellow
ansi[on_blue]=$'\e[44m'   # blue
ansi[on_purple]=$'\e[45m' # purple
ansi[on_cyan]=$'\e[46m'   # cyan
ansi[on_white]=$'\e[47m'  # white

# high intensity
ansi[iblack]=$'\e[0;90m'  # black
ansi[ired]=$'\e[0;91m'    # red
ansi[igreen]=$'\e[0;92m'  # green
ansi[iyellow]=$'\e[0;93m' # yellow
ansi[iblue]=$'\e[0;94m'   # blue
ansi[ipurple]=$'\e[0;95m' # purple
ansi[icyan]=$'\e[0;96m'   # cyan
ansi[iwhite]=$'\e[0;97m'  # white

# bold high intensity
ansi[biblack]=$'\e[1;90m'  # black
ansi[bired]=$'\e[1;91m'    # red
ansi[bigreen]=$'\e[1;92m'  # green
ansi[biyellow]=$'\e[1;93m' # yellow
ansi[biblue]=$'\e[1;94m'   # blue
ansi[bipurple]=$'\e[1;95m' # purple
ansi[bicyan]=$'\e[1;96m'   # cyan
ansi[biwhite]=$'\e[1;97m'  # white

# high intensity backgrounds
ansi[on_iblack]=$'\e[0;100m'  # black
ansi[on_ired]=$'\e[0;101m'    # red
ansi[on_igreen]=$'\e[0;102m'  # green
ansi[on_iyellow]=$'\e[0;103m' # yellow
ansi[on_iblue]=$'\e[0;104m'   # blue
ansi[on_ipurple]=$'\e[0;105m' # purple
ansi[on_icyan]=$'\e[0;106m'   # cyan
ansi[on_iwhite]=$'\e[0;107m'  # white

# reset
ansi[off]=$'\e[0m' # text reset
