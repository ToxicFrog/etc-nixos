{ config, pkgs, lib, secrets, unstable, ... }:

{
  services.crossfire-server = {
    enable = true;
    openFirewall = true;
    configFiles = {
      settings = ''
        # Reduce stats with depletion on death rather than editing the character sheet.
        stat_loss_on_death false
        # Penalize newbies less and experienced players more.
        balanced_stat_loss true
        # Persist temp maps across runs.
        #recycle_tmp_maps true
        # Show HP bars for damaged entities.
        always_show_hp damaged
        # Recover dirty maps after server restart
        recycle_tmp_maps true
      '';
      news = ''
        %Welcome to the ancilla crossfire server!
        This server runs CF trunk, sometimes with local bugfixes. It also has a long map reset time (1 week).
        It is still under construction and created characters will often be [u]deleted without warning[/u] while the server is still being set up. Don't get too attached!

        %Current test items
        None, but my daughter is adding a lot of maps.
      '';
      dm_file = secrets.auth.crossfire.dmfile;
    };
  };
  systemd.services.crossfire-server.environment = {
    # Readonly game data like maps, archetypes, and attack messages.
    CROSSFIRE_LIBDIR = "/ancilla/projects/crossfire";
    # Read-write server state.
    CROSSFIRE_LOCALDIR = "/var/lib/crossfire";
    # Temporary maps.
    CROSSFIRE_TMPDIR = "/var/lib/crossfire/tmp";
    # libxcrypt removed support for the hash crossfire-server uses, but for now
    # we can work around it thus, until we get a fix upstreamed.
    # Don't try this in public :)
    CF_DEBUG_BYPASS_LOGIN = "true";
  };
}
