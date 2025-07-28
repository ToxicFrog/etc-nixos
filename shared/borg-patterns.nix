rec {
  common = [
    "R boot"
    "R etc/nixos"
    "R home"
    "R root"
    "R var/cache/locatedb"
    "R var/lib"

    # Exclude caches that aren't properly tagged as such.
    "! var/lib/**/proc/"
    "! **/.cache/"
    "! **/__pycache__/"

    # Chrome and Firefox caches
    "! **/CacheStorage/"
    "! **/cache2/"
    "! **/startupCache/"
    "! **/Code Cache/"
    "! **/ScriptCache/"

    # Core dumps
    "- **/core"
    "- **/core.*"

    # Homedir stuff that tends to be too bulky
    "! home/*/Videos/"
    "! home/*/Music/"
    "! home/*/Pictures/"
    "! home/*/Comics/"
    "! home/*/Games/"

    # Homedir scratch/cache data
    "! home/*/tmp/"
    "! home/*/.cache/"
    "! home/*/.local/share/Trash/"
    "! **/tmp/"
    "! **/Temp/"
    "! **/temp/"
    "! **/.Trash-*/"

    # Bulky gaming stuff
    "! home/*/.local/share/Steam/"
    "! home/*/.local/share/lutris/"
    "! home/*/.config/heroic/tools/"
    "! home/*/Heroic/"
  ];

  dreamhost = [
    "R ."
    "! logs/"
  ];

  ancilla = [
    "R srv"
    "R ancilla"
    "R ancilla/media/music/beets.db"
    "R ancilla/media/music/beets.db-journal"
    "R ancilla/media/music/genres.yaml"

    "! ancilla/media"
    "! ancilla/installs"
    "! ancilla/torrents/buffer"
    "! ancilla/torrents/complete"
    "! ancilla/torrents/new"
  ] ++ common;

  ancilla-comics = [
    "R ancilla/media/comics"
    "! ancilla/media/comics/WIP"
  ];
  ancilla-music = [
    "R ancilla/media/music"
    "! ancilla/media/music/.srv"
  ];
  ancilla-photos = [
    "R ancilla/media/photos"
    "! ancilla/media/photos/links"
  ];

  durandal = common;
  "funkyhorror" = dreamhost;
  "GRABR.ca" = dreamhost;
  "godbehere.ca" = dreamhost;
  thoth = common;
  pladix = common;
}
