# Hugin IRC message relay for Munin.
# Used for alert delivery by Munin and other alerting things like smartd.
# You can use it like sendmail, although it ignores all command line flags.

{ config, pkgs, lib, ... }:

let
  server = "nsvm.ancilla.ca";
  nick = "hugin";
  name = "ancilla notification daemon";
  user = "munin";
  group = "munin";
in {
  systemd.services.hugin = {
    description = "IRC backend for Munin notifications";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target" "local-fs.target"];
    script = ''
      ${pkgs.ii}/bin/ii \
        -i hugin \
        -s ${server} \
        -n ${nick} \
        -f "${name}"
    '';
    postStop = ''
      ${pkgs.coreutils}/bin/rm -rf hugin
    '';
    serviceConfig = {
      User = "${user}";
      Group = "${group}";
      WorkingDirectory = "~";
      Restart = "always";
      RestartSec = 5;
    };
  };

  environment.systemPackages = [
    # Usage: cat message | hugin user-or-channel headers...
    # The headers, if present, will be prepended to the message, before even
    # the INCOMING MESSAGE banner. You can use this to notify specific
    # users, add a timestamp, etc.
    # TODO: add Munin postprocessor to make the output prettier?
    (pkgs.writeScriptBin "hugin" ''
      #!${pkgs.zsh}/bin/zsh

      set -e
      [[ -e ~${user}/hugin/${server}/in ]] || exit 1

      # If not already running under lock, re-execute self with lock acquired
      [[ $FLOCKER != "$0" ]] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@"

      while [[ $1 == -* ]]; do shift; done
      user=$1; shift

      [[ -d ~${user}/hugin/${server}/$user ]] || {
        # Join the channel if not already in it.
        echo "/j $user" > ~${user}/hugin/${server}/in
      }

      function emit {
        # Gross hack here: ii doesn't properly read the input until the
        # fifo is closed. So if we send it the entire message at once it
        # ends up losing most of it.
        local fmt="$1"; shift
        echo "EMIT /PRIVMSG $user :$fmt $@" >&2
        printf "/PRIVMSG $user :$fmt\n" "$@" > ~${user}/hugin/${server}/in
        echo "EMIT DONE" >&2
        sleep 1
      }

      function emit- {
        echo "ERROR" >&2
      }

      function emit-CRIT {
        emit '\x034\x02%16s %s\x02 \x0314[%s]\x15' "$label" "$value" "$limit"
        [[ $extinfo ]] && emit '    (%s)' "$extinfo"
      }

      function emit-WARN {
        emit '\x037\x02%16s %s\x02 \x0314[%s]\x15' "$label" "$value" "$limit"
        [[ $extinfo ]] && emit '    (%s)' "$extinfo"
      }

      function emit-FOK {
        emit '\x033\x02%16s %s\x02\x15' "$label" "$value"
        [[ $extinfo ]] && emit '    (%s)' "$extinfo"
      }

      while [[ $1 ]]; do
        echo "PREFIX $1" >&2
        emit "%s" "$1"; shift
      done
      export IFS=$'\t'
      while [[ ! $host ]]; do
        read host graph
        echo "READ '$host' '$graph'" >&2
      done
      emit "=== %s :: %s ===" "$host" "$graph"
      while read level label value limit extinfo; do
        level="$(echo "$level" | tr -d ' ')"
        echo "LINE '$level' '$label' '$value' '$limit' '$extinfo'" >&2
        emit-$level || echo 'FAIL' >&2
      done
      emit '=== END ==='
    '')
  ];
}
