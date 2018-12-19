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
  # users.users = [{
  #   name = "hugin";
  #   description = "Hugin alert sender";
  #   group = "munin";
  #   uid = config.ids.uids.hugin;
  #   home = "/var/lib/hugin";
  #   isSystemUser = true;
  # }];

  # users.groups = [{
  #   name = "munin";
  #   gid = config.ids.gids.munin;
  # }];

  systemd.services.munin-irc-notify = {
    description = "IRC backend for Munin notifications";
    # path = with pkgs; [ ii coreutils ];
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

      while [[ $1 == -* ]]; do shift; done
      user=$1; shift

      [[ -d ~${user}/hugin/${server}/$user ]] || {
        # Join the channel if not already in it.
        echo "/j $user" > ~${user}/hugin/${server}/in
      }

      userdir=$(echo $user | tr A-Z a-z)
      {
        while [[ $1 ]]; do
          echo "$1"; shift
        done
        while read line; do
          echo "$line"
        done
      } | ${pkgs.gnused}/bin/sed -E "s,^$, ,; s,^,/PRIVMSG $user :," \
        | ${pkgs.pv}/bin/pv -q -L 8 -l -C \
        | while IFS="" read -r line; do
            # Gross hack here: ii doesn't properly read the input until the
            # fifo is closed. So if we send it the entire message at once it
            # ends up losing most of it.
            printf "%s\n" "$line" > ~${user}/hugin/${server}/in
          done
    '')
  ];
}
