self: super:

{
  dosage = super.dosage.overrideAttrs (oldAttrs: {
    postPatch = ''
      sed -E -i '
        /START AUTOUPDATE/ {
          a cls("TheLittleTrashmaid", "challenge/the-little-trashmaid", 162918),
          a cls("MyDragonGirlfriend", "challenge/my-dragon-girlfriend", 300138),
          a cls("CrowTime", "challenge/crow-time", 693372),
          a cls("MonstersAndGirls", "challenge/monsters-and-girls", 773948),
          a cls("ItStemsFromLove", "challenge/it-stems-from-love-gl", 258375),
          a cls("KissItGoodbye", "challenge/kiss-it-goodbye", 443703),
          a cls("CircuitsAndVeins", "challenge/circuits-and-veins", 98905),
          a cls("Flowerpot", "challenge/flowerpot", 51856),
        }
      ' dosagelib/plugins/webtoons.py
    '';
  });
}
