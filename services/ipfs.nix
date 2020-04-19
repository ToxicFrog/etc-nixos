# IPFS node configuration.

{ config, pkgs, ... }:

{
  environment.variables = {
    IPFS_PATH = "/srv/ipfs/";
  };
  services.ipfs = {
    dataDir = "/srv/ipfs";
    defaultMode = "offline";  # Run HTTP API but don't link to other nodes.
    enable = false;
    enableGC = true;
    gatewayAddress = "/ip4/127.0.0.1/tcp/8558";
    # extraFlags = ["--enable-namesys-pubsub"];
  };
  # TODO: generate swarm key in /srv/ipfs/swarm.key
  # has format: "/key/swarm/psk/1.0.0/\n/base16/\n%s", <32-byte random key>
  # optionally also set LIBP2P_FORCE_PNET=1 environment variable
  # see https://github.com/ipfs/go-ipfs/blob/master/docs/experimental-features.md#private-networks
  # current is hexification of "ancilla.ancilla.ca ipfs swarm 00"
  # TODO: set up two ipfs daemons, one private for generating file shares, one
  # public for accessing/seeding the global IPFS swarm
}
