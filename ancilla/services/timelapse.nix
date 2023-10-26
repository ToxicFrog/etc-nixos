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
    startAt = "01:02:00";
    script = ''
      set -e
      cd /ancilla/media/photos/timelapse
      ${pkgs.rsync}/bin/rsync -rPhaSHAX -e ${pkgs.openssh}/bin/ssh --remove-source-files pi@timelapse:snapshots/ garden/
      ${pkgs.openssh}/bin/ssh pi@timelapse find snapshots -type d -empty -delete
      if [[ -f garden/$(date '+%Y/%m/%d/00.00.00').jpeg ]]; then
        touch garden/latest
      else
        >&2 echo "timelapse error -- no snapshot for midnight found in latest update"
        exit 1
      fi
      chown -R rebecca:users garden
      # need to figure out the closure for this -- exiftool and ffmpeg at least
      #sudo -u rebecca ./build
    '';
  };
}
