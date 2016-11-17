self: super:

{
  dosbox-debug = super.dosbox.overrideAttrs (oldAttrs: {
    name = "dosbox-0.74-heavy-debug";
    configureFlags = ["--enable-debug=heavy" "--program-suffix=-debug"];
    buildInputs = oldAttrs.buildInputs ++ [ self.ncurses ];
    desktopItem = self.makeDesktopItem {
      name = "dosbox-debug";
      exec = "dosbox-debug";
      comment = "x86 emulator with internal DOS (debug mode)";
      desktopName = "DOSBox (debug mode)";
      genericName = "DOS emulator";
      categories = "Application;Emulator;";
    };
  });
}
