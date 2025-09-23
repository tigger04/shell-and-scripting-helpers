#shellcheck disable=SC2119,SC2154,SC2034

# HELPER FUNCTIONS

#    this to avoid silly warnings as shellcheck can't handle pointers which
#    are fantastic for bash optimization 🥳

# WTF is this thing:
#    Handy functions, trying to avoid subshells at all costs which slow down
#    execution (these things all add up til one day 😐🔫 trust me)

# Why no ANSI colours? I abandoned these in favour of emojis which still stand
# out visually. ANSI generates too much faff when capturing output to log files
# etc. Yes there are ways but the code becomes needlessly complex, the whole
# point of this thing is KISS after the monstrosity that came before it.

# KEY:
#    for USAGE comments, OPTION is mandatory argument, [OPTION] is optional
#    argument
# e.g.
#    USAGE: some_function [SOME_OPTIONAL_ARGUMENT] SOME_MANDATORY_ARGUMENT

### quick and dirty path fix ###
export PATH=~/bin:~/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:"$PATH"

# regexes
export url_regex='(https?|ftp|file):\/\/[-A-Za-z0-9+&@#\/%?=~_|!:,.;]*[-A-Za-z0-9+&@#\/%=~_|]\b'
export httpregex="$url_regex"
export domain_regex='[a-zA-Z0-9-]{1,63}(\.[a-zA-Z0-9-]{1,63})+'
export youtube_id_regex='\<[a-zA-Z0-9_-]{11}\>'

## other global vars ##

imgext=(gif jpg jpe jpeg png webp heic avif bmp tif tiff)
imgstring() {
   imgstring="\.("
   for ext in "${imgext[@]}"; do
      imgstring+="$ext|"
   done
   imgstring="${imgstring%|})$"
   export imgstring
}

fontext=(otf ttf woff woff2)
vidext=(mkv webm mpg mp2 mpeg mpe mpv ogg mp4 m4p m4v avi wmv mov qt flv swf avchd)
vidext_extra=("${vidext[@]}" part)

### fatal function ###
die() {
   # WTF:
   #    Halts execution if SOME_RISKY_COMMAND fails, allowing a more useful
   #    explanation to be shown to the user
   # USAGE:
   #    SOME_RISKY_COMMAND || die [MESSAGE]

   rc=$?
   local lastwords="💀 $cmd_base died with exit code $rc: $*"
   # printf "💀 %s died with exit code %s: %s\n" "$cmd_base" $rc "$*" >/dev/stderr
   # [ -n "$user_interactive" ] || dialog "$lastwords"
   printf '%s\n' "$lastwords" >/dev/stderr
   exit $rc
}

### bash version check ###

### functions ###

# Q: why bother with the warn, info etc functions at all?
# A: not just for emojis, they go to stderr so they don't mess up outputs
#    if you pipe your scripts. Personally, I frequently forget to output
#    to >2 or /dev/stderr, so these keep things handy and safe.

warn() {
   # USAGE: warn MESSAGE
   echo -e "⚠️ $*" >/dev/stderr
}

errortext() {
   # USAGE: errortext MESSAGE
   # this does not halt execution, just displays an error!
   echo -e "⛔️ $*" >/dev/stderr
}

announce() {
   # USAGE: errortext MESSAGE
   {
      echo -e "📣 $*"
   } >/dev/stderr
}

info() {
   # USAGE: info MESSAGE
   echo -e "🚹 $*" >&2
}

highlight() {
   {
      echo -e "*️⃣ $*"
   } >&2
}

checktext() {
   echo "☑️ $*" >&2
}

ticktext() {
   echo -e "✅ $*" >&2
}

filename() {
   # display filename with icon (no newline!)

   printf "📃 %s\n" "$@"
}

qbase() {
   # get basename and dirname of a file without unnecessary subshell
   # usage: qbase PATH [VAR] [VAR_DIR]
   # basename result is in $REPLY or $VAR if specified
   # dirname result is in $REPLY_DIR or $VAR_DIR if specified
   # adapted from the pure bash bible :) no need for additional time-consuming subshells :)

   [ $# -ge 1 ] || return 1 # min 1 and max 1 argument please

   REPLY=${1%"${1##*[!/]}"}
   REPLY=${REPLY##*/}
   REPLY=${REPLY%"${2/"$REPLY"/}"}
   REPLY_DIR=${1%"$REPLY"}

   if [ -n "$2" ]; then
      local -n ptr=${2}
      ptr="$REPLY"
   fi

   if [ -n "$3" ]; then
      local -n ptr=${3}
      ptr="$REPLY_DIR"
   fi

   if [[ "$REPLY" == */* ]]; then
      die "qbase: invalid path\n\$REPLY=$REPLY\n\$1=$1"
   fi

   # printf -v REPLY '%s' "${tmp}"
}

hline() {

   # pretty print a header/title or else just a spacer line
   # USAGE: hline [TITLE]
   # PRINTS:
   # -------------- TITLE --------------
   # (centered, based on column width of the terminal or defaults to 65 if
   #  executed non-interactively in some bg script etc)

   # 🧌 HERE BE DRAGONS, I'M SO SORRY

   local cols tmp_out
   ((cols = COLUMNS > 0 ? COLUMNS - 1 : 65))

   local hline_bullet="${hline:-=}"
   local thinbanner_bullet="${hline:--}"
   local thinbanner_pointer_open="${hline:->} "
   # local thinbanner_pointer_open="> "
   local thinbanner_pointer_close=" ${hline:-<}"
   # local thinbanner_pointer_close=" <"

   local hline_cols=$((cols / ${#hline_bullet}))
   local thinbanner_cols=$((cols / ${#thinbanner_bullet}))

   if [ $# -eq 0 ]; then
      ### hline ###
      printf -v tmp_out "%${hline_cols}s"
      printf '%s' "${tmp_out// /$hline_bullet}"
   else
      ### thinbanner ###
      local displaytext="$*"
      local displayoutput=""

      local displaytext_length=${#displaytext}
      local pointer_open_length=${#thinbanner_pointer_open}
      local pointer_close_length=${#thinbanner_pointer_close}
      local bullet_length=${#thinbanner_bullet}

      local bullets

      bullets=$(((thinbanner_cols - displaytext_length) / 2 - pointer_open_length - pointer_close_length))
      bullets=$((bullets / bullet_length))

      printf -v tmp_out "%${bullets}s"                  # sets to n amount of spaces
      displayoutput+="${tmp_out// /$thinbanner_bullet}" # replace spaces with bullets

      displayoutput+="$thinbanner_pointer_open"
      displayoutput+="$displaytext"
      displayoutput+="$thinbanner_pointer_close"

      local r_bullets_length=$(((${#displayoutput} - thinbanner_cols) / bullet_length))
      printf -v tmp_out "%${r_bullets_length}s" # set n number of spaces
      displayoutput+="${tmp_out// /$thinbanner_bullet}"

      printf '%s' "$displayoutput"
   fi

   echo
}

thinbanner() {
   # wrapper for hline to support my legacy scripts
   hline "$@"
}

qhead() {
   # basically this is 'head' without resorting to external binary and subshell
   # Usage: qhead NUM_LINES FILE
   mapfile -tn "$1" qh_line <"$2"
   printf '%s\n' "${qh_line[@]}"

   #TODO: support STDIN
}

qtail() {
   # basically this is 'tail' without resorting to external binary and subshell
   # Usage: qtail NUM_LINES FILE
   mapfile -tn 0 qt_line <"$2"
   printf '%s\n' "${qt_line[@]: -$1}"

   #TODO: support STDIN
}

uuid() {
   # WTF: quickly generate a UUID (aka GUID)
   # USAGE: uuid [VAR]
   # result in VAR or STDOUT (printed)

   local abit b c theuuid
   local theuuid=""

   c="89ab"

   for ((n = 0; n < 16; ++n)); do
      b="$((RANDOM % 256))"

      case "$n" in
      6)
         printf -v abit '4%x' "$((b % 16))"
         ;;
      8)
         printf -v abit '%c%x' "${c:$RANDOM%${#c}:1}" "$((b % 16))"
         ;;

      3 | 5 | 7 | 9)
         printf -v abit '%02x-' "$b"
         ;;

      *)
         printf -v abit '%02x' "$b"
         ;;
      esac

      theuuid+="$abit"
   done

   if [ $# -eq 0 ]; then
      REPLY="$theuuid"
      echo -n "$theuuid"
   else
      local -n ptr=${1}
      ptr="$theuuid"
   fi
}

trim_quotes() {

   # Usage: trim_quotes VAR_1 VAR_2 .. VAR_n
   # result(s) in VAR_1, VAR_2 .. VAR_n

   while [ $# -gt 0 ]; do
      local -n ptr=${1}
      ptr="${ptr//\"/}"
      shift
   done
}

quote_quotes() {

   # Usage: quote_quotes VAR_1 VAR_2 .. VAR_n
   # result(s) in VAR_1, VAR_2 .. VAR_n

   while [ $# -gt 0 ]; do
      local -n ptr=${1}
      ptr="${ptr//\"/\\\"}"
      shift
   done
}

ok_pause() {

   # What:   Pause execution pending keypress
   # USAGE: ok_pause -[OPTIONAL_TIMEOUT_SECONDS] [OPTIONAL_MESSAGE]
   # this is way over-engineered for the sake of funky dots
   # ok_pause_reply returns the keypress

   local ok_timeout ok_count prompt_message cols remaining_cols total_dots dots

   ok_timeout=0 # default

   long_wait_message=(
      ".    "
      " .   "
      "  .  "
      "   . "
      "    ."
      "   . "
      "  .  "
      " .   "
   )

   if [[ $1 =~ ^-([0-9]+)$ ]]; then
      ok_timeout=${BASH_REMATCH[1]}
      shift
   fi

   if [ $# -eq 0 ]; then
      prompt_message="Press the [ANY] key:"
   else
      prompt_message="$*"
   fi

   echo -n "$prompt_message"

   read -r cols < <(tput cols)
   if ! [[ $cols =~ ^[0-9]+$ ]] || [ $cols -eq 0 ]; then
      cols=60
   fi

   total_dots=$ok_timeout

   remaining_cols=$((cols - ${#prompt_message} - total_dots - 1))
   if [ $remaining_cols -lt 0 ]; then
      echo
      total_dots=$((cols - 1))
   fi

   print_dots() {
      local n=$1

      if [ $ok_timeout -ge $cols ] || [ $ok_timeout -eq 0 ]; then
         # display alternately the contents of long_wait_message
         local index=$((n % ${#long_wait_message[@]}))
         echo -ne "${long_wait_message[$index]}"
         printf '\033[%sD' "${#long_wait_message[0]}"
         return 0
      fi

      local trailing_dots=$((total_dots - n - 1))

      printf -v dots "%${n}s_%${trailing_dots}s"
      dots="${dots// /.}"
      printf '%s' "$dots"

      # got back $total_dots number of characters
      printf '\033[%sD' "$total_dots"
   }

   ok_count=0

   while [ $ok_count -lt $ok_timeout ] || [ $ok_timeout -eq 0 ]; do

      print_dots $((ok_count++))
      unset ok_pause_reply
      read -r -n 1 -t 1 ok_pause_reply || ok_pause_reply="!"

      if [[ "${ok_pause_reply}" != "!" ]]; then
         echo
         return 0
      fi
   done

   echo
   warn timed out
   return 0
}

ok_confirm() {

   # What:   Pause execution pending user confirmation y/N

   # USAGE: ok_confirm [OPTIONAL_TIMEOUT_SECONDS] [OPTIONAL_MESSAGE]
   #        caller must handle response code or execution will proceed
   #        (unless 'set -e' set in script in which case it will abort)

   # this is way over-engineered for the sake of funky dots

   local ok_timeout ok_count prompt_message cols remaining_cols total_dots dots
   ok_timeout=15 # default
   long_wait_message=(
      ".    "
      " .   "
      "  .  "
      "   . "
      "    ."
      "   . "
      "  .  "
      " .   "
   )

   if [[ $1 =~ ^-([0-9]+)$ ]]; then
      ok_timeout=${BASH_REMATCH[1]}
      shift
   fi

   if [ $# -eq 0 ]; then
      prompt_message="Continue (y/N):"
   else
      prompt_message="$* (y/N):"
   fi

   echo -n "$prompt_message"

   read -r cols < <(tput cols)
   if ! [[ $cols =~ ^[0-9]+$ ]] || [ $cols -eq 0 ]; then
      cols=60
   fi

   total_dots=$ok_timeout

   remaining_cols=$((cols - ${#prompt_message} - total_dots - 1))
   if [ $remaining_cols -lt 0 ]; then
      echo
      total_dots=$((cols - 1))
   fi

   print_dots() {
      local n=$1

      if [ $ok_timeout -ge $cols ] || [ $ok_timeout -eq 0 ]; then
         # display alternately the contents of long_wait_message
         local index=$((n % ${#long_wait_message[@]}))
         echo -ne "${long_wait_message[$index]}"
         printf '\033[%sD' "${#long_wait_message[0]}"
         return 0
      fi

      local trailing_dots=$((total_dots - n - 1))

      printf -v dots "%${n}s_%${trailing_dots}s"
      dots="${dots// /.}"
      printf '%s' "$dots"

      # got back $total_dots number of characters
      printf '\033[%sD' "$total_dots"
   }

   ok_count=0

   while [ $ok_count -lt $ok_timeout ] || [ $ok_timeout -eq 0 ]; do

      print_dots $((ok_count++))
      read -r -n 1 -t 1 ok_conf_reply || ok_conf_reply="!"

      if [[ ${ok_conf_reply,,} == y ]]; then
         echo
         return 0
      elif [[ "${ok_conf_reply}" != "!" ]]; then
         echo
         warn Cancelled
         return 1
      fi
   done

   echo
   errortext timed out
   return 1
}

confirm_continue() {

   # WTF: show message to user and request explicit y/N to continue.
   #      Return code is 0 if user confirms, 1 if user cancels, 2 for timeout.

   # USAGE: confirm_continue [TIMEOUT_SECONDS] [MESSAGE]
   # WHERE: TIMOUT in seconds, 0 for no timeout

   local t=0

   if [[ $1 =~ ^-([0-9]+).*$ ]]; then

      local t="${BASH_REMATCH[1]}"

      if [ $t -eq 0 ]; then
         timeout=()
         # ^ no timeout
      else
         timeout=(-t "$t")
      fi
      shift
   fi

   local message="${*:-Continue}"

   {
      echo -n "️❓ $message (y/N):"
   } >/dev/stderr

   read -r -n 1 "${timeout[@]}" || return 2
   echo

   # declare -p timeout REPLY
   # return

   if [[ ${REPLY,,} == y ]]; then
      return 0
   else
      return 1
   fi
}

show_cmd_execute() {
   echo "⚡️ $*" >/dev/stderr
   "$@"
}

show_cmd_execute_oneline() {
   echo -n "⚡️ $*" >/dev/stderr
   "$@" | oneline 2>&1
}

alias scx=show_cmd_execute

confirm_cmd_execute() {

   # WTF: show command to user and request explicit y/N to execute it
   #      calling script must handle response code or execution will proceed,

   # USAGE: confirm_cmd_execute [TIMEOUT_SECONDS] COMMAND

   confirm_continue "$@"
   rc=$?

   if [[ $1 =~ ^-([0-9]+)$ ]]; then
      shift
   fi

   if [ $rc -eq 0 ]; then
      show_cmd_execute "${@}"
   else
      return $rc
   fi
}
alias ccx=confirm_cmd_execute

fullpath() {
   # Get the absolute, normalized path without external commands or subshells
   # usage: fullpath PATH [VAR]
   # result in $REPLY and optionally in VAR if specified

   local mypath="$1"
   local output_var="$2"

   # Handle empty input
   if [[ -z "$mypath" ]]; then
      REPLY=""
      if [[ -n "$output_var" ]]; then
         local -n ptr="$output_var"
         ptr=""
      fi
      return 1
   fi

   local full_path

   # Convert to absolute path if relative
   if [[ "$mypath" == /* ]]; then
      full_path="$mypath"
   else
      full_path="${PWD}/${mypath}"
   fi

   # Normalize path components using pure bash string manipulation
   # Handle multiple slashes first
   while [[ "$full_path" == *"//"* ]]; do
      full_path="${full_path//\/\//\/}"
   done

   # Remove trailing slash unless it's root
   if [[ "$full_path" != "/" && "$full_path" == *"/" ]]; then
      full_path="${full_path%/}"
   fi

   # Handle . and .. components
   local temp_path result_path=""
   local IFS='/'

   # Process each component
   temp_path="$full_path"
   while [[ "$temp_path" == *"/"* ]]; do
      # Get the first component
      local component="${temp_path%%/*}"
      temp_path="${temp_path#*/}"

      # Process component
      case "$component" in
      "" | ".")
         # Skip empty and current directory
         continue
         ;;
      "..")
         # Go up one directory - remove last component from result
         if [[ "$result_path" != "" ]]; then
            result_path="${result_path%/*}"
         fi
         ;;
      *)
         # Add component to result
         result_path="${result_path}/${component}"
         ;;
      esac
   done

   # Handle the last component (no more slashes)
   if [[ -n "$temp_path" ]]; then
      case "$temp_path" in
      "" | ".")
         # Skip
         ;;
      "..")
         # Go up one directory
         if [[ "$result_path" != "" ]]; then
            result_path="${result_path%/*}"
         fi
         ;;
      *)
         # Add component
         result_path="${result_path}/${temp_path}"
         ;;
      esac
   fi

   # Ensure we have at least root
   if [[ -z "$result_path" ]]; then
      result_path="/"
   fi

   # Set results
   REPLY="$result_path"
   if [[ -n "$output_var" ]]; then
      local -n ptr="$output_var"
      ptr="$result_path"
   fi
}

q_path() {
   deprecated 5
   fullpath "$@"
}

nicepath() {
   # usage: nicepath PATH [VAR]
   # result in $REPLY and VAR if specified
   local nice_path ugly_path
   # read -r ugly_path < <(realpath "$1")
   fullpath "$1" ugly_path

   if [[ "$ugly_path" == "$HOME"* ]] || [[ "$ugly_path" == "$HOME" ]]; then
      printf -v nice_path '%s' "~${ugly_path#"$HOME"}"
   else
      printf -v nice_path '%s' "$ugly_path"
   fi

   if [ -n "$2" ]; then
      local -n ptr=${2}
      ptr="$nice_path"
   else
      REPLY="$nice_path"
   fi
}

deprecated() {

   case $1 in
   1)
      warn "${FUNCNAME[1]} deprecated"
      declare -p FUNCNAME BASH_SOURCE
      return 0
      ;;
   5)
      warn "${FUNCNAME[1]} is flagged for future deprecation"
      return 0
      ;;
   *)
      warn "${FUNCNAME[1]} deprecated permanently: $*"

      if [ $SHLVL -le 1 ]; then
         pause this shell will quit
      fi
      exit 101 # calling 'die' seems to cause an infinite loop on maybe_rm
      ;;
   esac 1>/dev/stderr
}

timestamp() {
   # WTF:
   #    assign timestamp to VAR if specified, otherwise echo it to STDOUT.
   #    Timestamp assigned to TIMESTAMP in either case
   # USAGE:
   #    timestamp [-q] [VAR]
   # OPTION:
   #    -q:  do not echo, just assign

   local my_timestamp
   #shellcheck disable=SC2034
   printf -v my_timestamp '%(%F_%H:%M:%S)T' -1
   local quiet=false

   if [[ "$1" == "-q" ]]; then
      quiet=true
      shift
   fi

   # shellcheck disable=SC2034
   TIMESTAMP="$my_timestamp"

   if [ $# -gt 0 ]; then
      local -n ptr=${1}
      ptr="$my_timestamp"
   fi

   $quiet || echo "$my_timestamp"
}

datestamp() {
   # WTF:
   #    assign timestamp to VAR if specified, otherwise echo it to STDOUT.
   #    Timestamp assigned to TIMESTAMP in either case
   # USAGE:
   #    timestamp [-q] [VAR]
   # OPTION:
   #    -q:  do not echo, just assign

   #shellcheck disable=SC2034
   printf -v DATESTAMP '%(%F)T' -1

   if [[ "$1" == "-q" ]]; then
      : # do nothing
   elif [ $# -gt 0 ]; then
      local -n ptr=${1}
      ptr="$DATESTAMP"
   else
      echo "$DATESTAMP"
   fi
}

if [[ $_os == Darwin ]]; then
   grep() {
      command -v ggrep >/dev/null 2>&1 ||
         die "GNU Grep required (brew install grep)"
      command ggrep "$@"
   }
fi
alias ggrep=grep

path_stem_ext() {
   # usage: path_stem PATH [stem_var] [ext_var]
   # result in $REPLY_STEM and $REPLY_EXT and $stem_var, $ext_var if specified

   local base
   qbase "$1" base

   # if [[ $full_path =~ ^([^\/]+/)*(.*)\.([a-zA-Z0-9]{1,6})$ ]]; then
   if [[ $base =~ ^(.+)\.([^\.]+)$ ]]; then
      REPLY_STEM="${BASH_REMATCH[1]}"
      REPLY_EXT="${BASH_REMATCH[2]}"
   else
      REPLY_STEM="$base"
      REPLY_EXT=""
   fi

   if [ -n "$2" ]; then
      local -n stem_ptr=${2}
      stem_ptr="$REPLY_STEM"
   fi

   if [ -n "$3" ]; then
      local -n ext_ptr=${3}
      ext_ptr="$REPLY_EXT"
   fi
}

caller() {

   # usage: caller [CALLER_VAR]
   # result in $REPLY and $CALLER_VAR if specified

   if [ -n "$1" ]; then
      local -n caller_var=${1}
   else
      local caller_var
   fi

   caller_var=$(ps -o command= $PPID)
   REPLY="$caller_var"
}

sanitize() {
   # usage: sanitize STRING [TARGET_VAR]
   # result in $REPLY or $TARGET_VAR if specified

   REPLY="${1//[^[:alnum:]]/_}"

   if [ -n "$2" ]; then
      local -n ptr=${2}
      ptr="$REPLY"
   else
      echo "$REPLY"
   fi
}

qpager() {
   local qpager=less

   if command -v bat >/dev/null 2>&1; then
      qpager=bat
   fi

   "$qpager"
}

qln() {
   local qln=ln

   if command -v gln >/dev/null 2>&1; then
      qln=gln
   fi

   "$qln" "$@"
}

open() {
   if [[ $_os == Darwin ]]; then
      command open "$@"
   else
      command xdg-open "$@"
   fi
}

maybe() {
   # USAGE: maybe [COMMAND]
   # this function conditionally executes a command based on the debug flag
   if [ -z "$debug" ] || [[ "$debug" == "false" ]]; then
      "$@"
   else
      echo "⭕️ $*"
   fi
}

blockchart() {

   # USAGE: blockchart [-v VAR] [-r] [NUMBER] [MAX] [BLOCKS]
   #
   # WHERE:
   #    -v VAR: assign result to environment variable VAR (otherwise echo it)
   #    -r:     reverse the color scheme
   #    NUMBER: the number to represent
   #    MAX:    the maximum number on the scale
   #    BLOCKS: the number of blocks to display for representation (default: 10)
   #
   # outputs to REPLY environment variable

   set -e

   REPLY=""

   [ $# -gt 0 ]

   if [[ "$1" == "-v" ]]; then
      local block_echo_flag=false
      shift
      local -n block_display=$1
      shift
   else
      local block_echo_flag=true
      local block_display
   fi

   if [[ "$1" == "-r" ]]; then
      bc_scheme=('🟩' '🟧' '🟥')
      shift
   else
      bc_scheme=('🟥' '🟨' '🟩')
   fi

   local -i bc_metric_unadulterated=$(($1 + 0))

   local bc_empty='\U2B1B'

   local bc_precision=1000
   local bc_metric_precision=$((bc_metric_unadulterated * bc_precision))
   local bc_max=${2:-100}
   local bc_maxblocks=${3:-10}

   # checks
   [ $bc_metric_unadulterated -le $bc_max ] || exit 1
   [ $bc_metric_unadulterated -ge 0 ] || exit 1

   local bc_offset=$((bc_precision * bc_max / bc_maxblocks / 2))
   local bc_metric=$((bc_metric_precision + bc_offset)) # for rounding

   local bc_limits=($((0 * bc_max / 100))
      $((33 * bc_max / 100))
      $((66 * bc_max / 100))
   )

   local bc_block_count=$((bc_metric * bc_maxblocks / bc_max / bc_precision))
   [ $bc_maxblocks -eq 1 ] && bc_block_count=1
   # unsure ^^
   local bc_block_count_empty=$((bc_maxblocks - bc_block_count))

   local -i bc_index=0
   local bc_color="${bc_scheme[0]}"

   while [ $bc_index -lt ${#bc_limits[@]} ]; do
      if [ $bc_metric_unadulterated -ge ${bc_limits[$bc_index]} ]; then
         bc_color="${bc_scheme[$bc_index]}"
      fi
      bc_index+=1
   done

   while [ $((bc_block_count--)) -gt 0 ]; do
      block_display+="$bc_color"
   done

   while [ $((bc_block_count_empty--)) -gt 0 ]; do
      block_display+="$bc_empty"
   done

   if $block_echo_flag; then
      echo -ne "$block_display"
   fi
}

debugg() {
   if [ -n "$debug" ] && [[ "$debug" != "false" ]]; then
      echo "🐞 $*"
   fi
}

random_hex() {

   # usage: random_hex [VAR]
   #        result in VAR or REPLY

   local random_hex=$((RANDOM % 16))

   case $random_hex in
   10)
      random_hex=a
      ;;
   11)
      random_hex=b
      ;;
   12)
      random_hex=c
      ;;
   13)
      random_hex=d
      ;;
   14)
      random_hex=e
      ;;
   15)
      random_hex=f
      ;;
   *) ;;
   esac

   # generate a random hex digit and set it to RANDOM_HEX

   if [ $# -eq 0 ]; then
      REPLY="$random_hex"
   else
      local -n ptr=${1}
      ptr="$random_hex"
   fi
}

get_current_mac_address() {
   # usage: get_current_mac_address [VAR]
   # result in VAR or REPLY

   read REPLY < <(ifconfig en0 ether | grep -Eo '([a-f0-9]{2}:){5}[a-f0-9]{2}')

   if [ $# -gt 0 ]; then
      local -n ptr=${1}
      ptr="$REPLY"
   fi
}

oneline() {
   while read -r oneline_line; do
      cols=$((COLUMNS - 1))
      echo -ne "${biblack}${oneline_line:0:$cols}${ansi_off}\r"
   done
   echo
}

nowrap() {
   # this function outputs text but truncates if it exceeds the terminal width
   # usage: pipe to this to prevent wrapping
   # e.g. ls -l | nowrap
   if [ -z "$COLUMNS" ]; then
      read -r COLUMNS < <(tput cols)
   fi

   maxcols=$((COLUMNS - 1))

   while read -r nowrap_line; do
      echo -e "${nowrap_line:0:$maxcols}"
   done
}

lsd_maybe() {
   # run lsd if it is installed else ls

   if command -v lsd >/dev/null 2>&1; then
      command lsd "$@"
   else
      command ls "$@"
   fi
}

is_my_git_repo() {
   # this function checks if a git repo belongs to me

   if ! [ -d "$1" ]; then
      return 3
   fi

   if [ -z "$github_username" ]; then
      read -r github_username < <(gh api user --jq .login)
   fi

   if [ -d "$1" ] && [ -f "$1/.git/config" ] && grep -q -E "\<$github_username\>" "$1/.git/config" >/dev/null 2>&1; then
      return 0
   else
      return 1
   fi
}

color_timestamps() {
   # this function colors timestamps in the output DEPRECATED

   deprecated 5

   # local date_color=$'\e[0;92m' # bright green
   # local time_color=$'\e[42m'   # reverse green
   # local reset_color=$'\e[0m'

   while read -r print_color_line; do

      # # line contains date
      # if [[ $print_color_line =~ ^(.*)\<((19|20)[0-9]{2}-[01][0-9]-[0123][0-9])\>(.*)$ ]]; then
      #    print_color_line="${BASH_REMATCH[1]}${date_color}${BASH_REMATCH[2]}${reset_color}${BASH_REMATCH[4]}"
      # fi

      # # line contains time
      # if [[ $print_color_line =~ ^(.*)\<([012][0-9]:[0-5][0-9])\>(.*)$ ]]; then
      #    print_color_line="${BASH_REMATCH[1]}${print_color_line_color}${BASH_REMATCH[2]}${reset_color}${BASH_REMATCH[3]}"
      # fi

      echo "$print_color_line"
      shift

   done

}

bat() {
   # this function wraps the bat command - and falls back to cat
   if command -v bat >/dev/null 2>&1; then
      command bat "$@"
   else
      warn "bat not found, using cat"
      command cat "$@"
   fi
}

gdate() {
   # this function wraps the gdate command - and falls back to date (linux vs darwin/macos safe fallback)
   if [[ $_os == Darwin ]]; then
      command gdate "$@"
   else
      command date "$@"
   fi
}

azonly() {
   # Reads STDIN replacing all non-az characters with REPL_CHAR
   # usage: azonly [REPL_CHAR] [TEXT]
   # reads STDIN unless TEXT provided
   # output to STDOUT

   local repl="${1:-_}"
   local az_pattern='[a-zA-Z0-9\._-]'
   local azonly_line

   az_sanitize() {
      while read -r azonly_line; do

         local strlen=${#azonly_line}
         local encoded=""
         local pos c o

         for ((pos = 0; pos < strlen; pos++)); do

            c=${azonly_line:$pos:1}

            #shellcheck disable=SC2254
            case "$c" in

            $az_pattern)
               o="${c}"
               ;;
            *)
               printf -v o '%s' "$repl"
               ;;
            esac

            encoded+="${o}"

         done

         echo "${encoded}"
      done
   }

   if [ -n "$2" ]; then
      shift
      echo "$*" | az_sanitize
   else
      az_sanitize
   fi
}

simple_string_replace() {
   # usage: simple_string_replace SEARCH REPLACE [SEARCH] [REPLACE] ...
   #        reads STDIN outputs to STDOUT
   #        replaces all instances of SEARCH with REPLACE
   #        SEARCH and REPLACE can be specified multiple times

   local search_replace=("$@")

   while read -r simple_string_replace_line; do

      local simple_string_replace_result="$simple_string_replace_line"

      for ((i = 0; i < ${#search_replace[@]}; i += 2)); do
         simple_string_replace_result="${simple_string_replace_result//${search_replace[$i]}/${search_replace[$i + 1]}}"
      done

      echo "$simple_string_replace_result"

   done

}

### aliases to functions ###
# alias qbasename=qbase
# alias qbase=qbasename

### quick variables ###

# basename of the running script for scripts to be able to use quickly
fullpath "$0" cmd_src
qbase "$cmd_src" cmd_base cmd_dir
export cmd_base cmd_dir

# set debug flag
if [[ "$1" == "-d" ]]; then
   debug=true
   shift
fi

# are quick functions loaded? this so scripts can check quickly
export qf_loaded=true

is_interactive() {
   case $- in
   *i*) return 0 ;; # Interactive shell
   *) return 1 ;;   # Non-interactive (called from script)
   esac
}

is_image() {
   for ext in "${imgext[@]}"; do
      if [[ "$1" == *.$ext ]]; then
         return 0
      fi
   done
   return 1
}

rm_if() {
   # remove file, if it exists

   local rm_if_verbose=true
   if [[ "$1" == "-q" ]]; then
      rm_if_verbose=false
      shift
   fi

   while [ $# -gt 0 ]; do
      if [ -e "$1" ]; then
         if trash "$1" >/dev/null 2>&1; then
            if $rm_if_verbose; then
               info trashed "$1"
            fi
         fi
      fi
      shift
   done 2>&1
}

mv_bak_if() {
   # Move a file to a .bak, if it exists, stamping it with an index if the .bak file already exists
   local file="$1"
   local bak_file="$file.bak"
   local index=1

   while [[ -e "$bak_file" ]]; do
      index=$((index + 1))
      bak_file="${file%.bak}.$index.bak"
   done

   if [ -e "$bak_file" ]; then
      die "This should never happen: $bak_file already exists"
   fi

   if [ -e "$file" ]; then
      warn "$file -> $bak_file"
      mv -f "$file" "$bak_file"
      REPLY="$bak_file"
   else
      unset REPLY
   fi
}

mv_bak() {
   if [ -e "$1" ]; then
      mv_bak_if "$1"
   else
      warn "[mv_bak] file not found: $1"
      return 1
   fi
}

clean_up_plain_text() {
   # usage: command_outputs_to_stdin | clean_up_plaintext
   #        (outputs to STDOUT)
   # or:    clean_up_plaintext [-i] FILENAME
   #        (cleans up text in a file, inline, with a backup of the original
   #        in FILENAME.txt)
   # -i:    if specified, no backup is created

   # I have over-engineered this ... facepalm, but it works

   local options=(
      -e 's/<[^>]*>//g'
      -e 's/!\[[^]]*\](\([^)]*\))//g'
      -e 's/!([^)]*)//g'
      -e 's/\[\([^]]*\)\](\([^)]*\))/\1/g'
      -e 's/{[^}]*}//g'
      -e '/^:::/d'
      -e 's/\\//g'
      -e 's/\[\]//g'
      -e 's/\[/*/g'
      -e 's/\]/*/g'
      -e 's/\n\n/[============]/g'
      -e 's/\n//g'
      -e 's/\[============\]/\n\n/g'
   )

   local clean_up_text_backup=true

   if [ $# -gt 0 ]; then
      # we are modifying a file
      if [[ "$1" == "-i" ]]; then
         clean_up_text_backup=false
         shift
      fi
      mv_bak "$1"
      show_cmd_execute gsed "${options[@]}" <"$REPLY" >"$1"

      if ! $clean_up_text_backup; then
         rm -f "$REPLY"
      fi
   else
      show_cmd_execute gsed "${options[@]}"
   fi
}

format_commas() {
   # usage: format_commas NUMBER [VAR]
   # puts result in VAR if specified, otherwise outputs to STDOUT
   # e.g. format_commas 1234567890 -> 1,234,567,890
   local num="$1"
   local int dec
   int="${num%%.*}"
   dec="${num#*.}"
   local result=""
   while [[ $int =~ ^([0-9]+)([0-9]{3})$ ]]; do
      int="${BASH_REMATCH[1]}"
      result=","${BASH_REMATCH[2]}$result
   done
   if [[ "$num" == *.* ]]; then
      REPLY="$int$result.$dec"
   else
      REPLY="$int$result"
   fi

   if [ -n "$2" ]; then # pointer
      local -n ptr=${2}
      ptr="$REPLY"
   else
      echo "$REPLY"
   fi
}

if ! [ ${BASH_VERSINFO[0]} -ge 5 ]; then
   echo "⛔️ bash version found: $BASH_VERSION, requires bash 5+"
   # beep
   tput bel
   ok_confirm "I don't want to kill your terminal, here's your chance to Ctrl+C"
   exit 1
fi

# What OS are we on? (Linux or Darwin mainly)
[ -n "$_os" ] || read -r _os < <(uname)
declare -x _os

# for scripts running across macos and linux
# if darwin, set gcp to the binary for gcp, if linux set it to cp
if [[ $_os == Darwin ]]; then
   read -r cp < <(which gcp)
   read -r ln < <(which gln)
   read -r rm < <(which grm)
   read -r mv < <(which gmv)
   _os_font_dir=~/Library/Fonts
else
   read -r cp < <(which cp)
   read -r ln < <(which ln)
   read -r rm < <(which rm)
   read -r mv < <(which mv)
   _os_font_dir=~/.local/share/fonts
fi

format_manpage() {
   # formates output like a manpage and pipes to less
   # usage: command --help | format_manpage | less -R
   #
   # Should handle cases where ANSI already in input

   local line
   local in_section=false
   local prev_line=""

   # Check if we have an interactive terminal using tput and not piped
   # The [ -t 1 ] test checks if file descriptor 1 (stdout) is connected to a terminal i.e. >&1
   local use_colors=false
   if tput colors >/dev/null 2>&1 && [ "$(tput colors)" -gt 0 ] && [ -t 1 ]; then
      use_colors=true
      # Define colors like a manpage
      local bold underline reset dim cyan yellow green red
      bold=$(tput bold)
      underline=$(tput smul)
      reset=$(tput sgr0)
      dim=$(tput dim)
      cyan=$(tput setaf 6)
      yellow=$(tput setaf 3)
      green=$(tput setaf 2)
      red=$(tput setaf 1)
   else
      local bold="" underline="" reset="" dim="" cyan="" yellow="" green="" red=""
   fi

   while IFS= read -r line; do
      # Strip ANSI escape sequences for processing
      local clean_line="${line//$'\033'\[[0-9;]*m/}"

      # Skip empty lines at start
      if [[ -z "$clean_line" && -z "$prev_line" ]]; then
         continue
      fi

      # Detect section headers (lines that are all caps, or start with uppercase and contain colons)
      if [[ "$clean_line" =~ ^[[:space:]]*[A-Z][A-Z[:space:]]*:?[[:space:]]*$ ]] ||
         [[ "$clean_line" =~ ^[[:space:]]*[A-Z][A-Z[:space:]_-]*[[:space:]]*$ && ${#clean_line} -gt 3 ]]; then

         # Add extra spacing before section headers (except first)
         if [[ -n "$prev_line" ]]; then
            echo
         fi

         if $use_colors; then
            # Make section headers bold cyan like classic manpages
            printf '%s%s%s%s\n' "$bold" "$cyan" "$clean_line" "$reset"
         else
            # Make section headers bold by adding them twice with backspaces (traditional method)
            printf '%s\b%s\n' "$clean_line" "$clean_line"
         fi
         in_section=true

      # Handle option lines (lines starting with - or --)
      elif [[ "$clean_line" =~ ^[[:space:]]*(-+[a-zA-Z0-9-]+) ]]; then
         # Make option names bold
         local option="${BASH_REMATCH[1]}"
         local rest="${clean_line#*"$option"}"

         if $use_colors; then
            # Options in bold yellow
            printf '%s%s%s%s%s\n' "$bold" "$yellow" "$option" "$reset" "$rest"
         else
            printf '%s\b%s%s\n' "$option" "$option" "$rest"
         fi

      # Handle file paths and URLs (including ~ paths)
      elif [[ "$clean_line" =~ (~/[a-zA-Z0-9._/-]*|/[a-zA-Z0-9._/-]+|https?://[a-zA-Z0-9._/-]+) ]]; then
         if $use_colors; then
            # Highlight paths and URLs in green
            local highlighted_line="$line"
            local path_match="${BASH_REMATCH[0]}"
            highlighted_line="${highlighted_line//$path_match/${green}$path_match${reset}}"
            echo "$highlighted_line"
         else
            echo "$line"
         fi

      # Handle quoted text
      elif [[ "$clean_line" =~ \"[^\"]+\" ]]; then
         if $use_colors; then
            # Highlight quoted strings in dim
            local highlighted_line="$line"
            local quote_match="${BASH_REMATCH[0]}"
            highlighted_line="${highlighted_line//$quote_match/${dim}$quote_match${reset}}"
            echo "$highlighted_line"
         else
            echo "$line"
         fi

      # Regular content lines
      else
         echo "$line"
      fi

      prev_line="$clean_line"
   done
}
