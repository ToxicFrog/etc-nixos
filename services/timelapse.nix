# Ancilla services not large enough to need their own file.

{ config, pkgs, lib, ... }:

{
  # timelapse capture
  systemd.services.timelapse-garden = {
    description = "Capture a timelapse frame from the garden camera.";
    after = ["network.target" "local-fs.target"];
    wantedBy = ["multi-user.target"];
    # every 5 minutes; at ~100kb/image (-j80) that works out to about 10GB/year
    # 15GB/year at -j90 (~150kb/image)
    startAt = "*:00/5:00";
    script = ''
      set -e
      cd /ancilla/media/photos/timelapse
      # Use . rather than : here so that bast et al can see it if they want
      out="garden/$(date '+%Y/%m/%d/%H.%M.00').jpeg"
      mkdir -p "$(dirname "$out")"
      set +e
      ${pkgs.openssh}/bin/ssh pi@timelapse ./snapshot > "$out.tmp"
      set -e
      if [[ -s "$out.tmp" ]]; then
        mv "$out.tmp" "$out"
        touch garden/latest
      else
        rm "$out.tmp"
        >&2 echo "capture error -- camera produced zero-length file"
        exit 1
      fi
      chown -R rebecca:users garden
    '';
  };
}
