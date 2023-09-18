#!/usr/bin/env zsh

# Notes on MQTT rewrite.
# We subscribe to MQTT topic hugin/# using:
# mosquitto_sub -t 'hugin/#' -F '%J'
# which will output received messages in JSON format, one per line.
# Keys we care about:
# .tst -- timestamp, ISO
# .topic
# .payload -- this is going to be a JSON object or perhaps just a string
# Take the "prefix" to be the topic with the leading hugin/ stripped.
# If the payload is just a string, we output:
# [prefix] payload
# If the string is multiline, we output the prefix only on the first line.
# Should probably make it bold or something too.
# If it's a json object, things get more interesting.
# We expect:
# .severity info, warning, error
# .message as above
# .metrics []
#   where each metric is a struct of:
#    name = metric name
#    value = current metric value;
#    limit = limit exceeded, if any;
#    state = warning, error, missing, or ok;
#    info = extinfo
#   limit and info are optional.
# So, without metrics, we can use this to send messages with a given severity
# With metrics, we additionally output the metric info, one per line.

# Set up colour codes
case $HUGIN_COLOUR in
  irc|IRC)
    declare -A SGR=(
      soh ''
      stx ''
      etx $'\x0F'
      bold $'\x02'
      red $'\x0304'
      green $'\x0309'
      yellow $'\x0308'
      purple $'\x0306'
      grey $'\x0314'
    )
    ;;
  ansi|ANSI|vt220|xterm)
    declare -A SGR=(
      soh $'\x1B['
      stx '10m'
      etx $'\x1B[0m'
      bold '1;'
      red '91;'
      green '92;'
      yellow '93;'
      purple '95;'
      grey '90;'
    )
    ;;
  *)
    declare -A SGR=()
    ;;
esac

# Map log levels to colours
SGR[info]=''
SGR[warning]=${SGR[yellow]}
SGR[error]=${SGR[red]}
# and munin severity levels
SGR[OK]=${SGR[green]}
SGR[WARNING]=${SGR[yellow]}
SGR[CRITICAL]=${SGR[red]}
SGR[UNKNOWN]=${SGR[purple]}

function main {
  mosquitto_sub -t "$1" -F '%J' | while read line; do
    local prefix="$(jqr .topic $line | sed s,^hugin/,,)"
    local payload="$(jqo .payload $line)"
    process-message
  done
}

# jqa filter payload => echo payload | jq filter
function jqn { printf '%s\n' "$2" | jq -e "$1" >/dev/null; }  # returns true iff output was non-null
function jqo { jqn $1 $2 && printf '%s\n' "$2" | jq -c "$1"; } # returns objects
function jqr { jqn $1 $2 && printf '%s\n' "$2" | jq -r "$1"; } # returns raw strings

# upvalues: prefix, payload
function process-message {
  # If the payload is a naked string, treat it as an info-level message with
  # no attached metrics.
  if [[ "$(jqr type $payload)" == "string" ]]; then
    local payload="{ \"severity\":\"info\", \"message\":$payload }"
    process-message
    return
  fi
  local severity="$(jqr .severity $payload)"
  local message="$(jqr .message $payload)"
  format-message
  if jqn .metrics $payload; then
    format-metrics
  fi
}

# upvalues: prefix, severity, message
function format-message {
  printf "[%s] %s\n" "$(style "$prefix" bold $severity)" $message
}

function format-metrics {
  jqo '.metrics | .[]' $payload | while read metric; do
    if ! jqn .name $metric; then continue; fi
    local name="$(jqr .name $metric)"
    local value="$(jqr .value $metric)"
    local limits="$(jqr .limits $metric)"
    local info="$(jqr .info $metric)"
    local severity="$(jqr .severity $metric)"
    # printf "name=%s value=%s limits=%s info=%s severity=%s style=%s\n" \
      # "$name" "$value" "$limits" "$info" "$severity" "$(style ... $severity | xxd)"
    #   name value [limits] info
    local head="$(printf "%24s %s" "$name" "${value:-unknown}")"
    printf "%s%s%s\n" \
      "$(style $head $severity)" \
      "$(style "${limits:+ [$limits]}" grey)" \
      "${info:+ ($info)}"
  done
}

# style <text> <modifiers>
function style {
  local start=""
  local text="$1"; shift
  while [[ $1 ]]; do
    start="${start}${SGR[soh]}${SGR[$1]}${SGR[stx]}"
    shift
  done
  printf "%s%s%s" "$start" "$text" "${SGR[etx]}"
}

exec main "$@"
