import ../make-test-python.nix ({ pkgs, ... }: {
  name = "dnscrypt-wrapper";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ rnhmjoj ];
  };

  nodes = {
    server = { lib, ... }:
      { services.dnscrypt-wrapper = with builtins;
          { enable = true;
            address = "192.168.1.1";
            keys.expiration = 5; # days
            keys.checkInterval = 2;  # min
            # The keypair was generated by the command:
            # dnscrypt-wrapper --gen-provider-keypair \
            #  --provider-name=2.dnscrypt-cert.server \
            #  --ext-address=192.168.1.1:5353
            providerKey.public = toFile "public.key" (readFile ./public.key);
            providerKey.secret = toFile "secret.key" (readFile ./secret.key);
          };
        services.tinydns.enable = true;
        services.tinydns.data = ''
          ..:192.168.1.1:a
          +it.works:1.2.3.4
        '';
        networking.firewall.allowedUDPPorts = [ 5353 ];
        networking.firewall.allowedTCPPorts = [ 5353 ];
        networking.interfaces.eth1.ipv4.addresses = lib.mkForce
          [ { address = "192.168.1.1"; prefixLength = 24; } ];
      };

    client = { lib, ... }:
      { services.dnscrypt-proxy2.enable = true;
        services.dnscrypt-proxy2.upstreamDefaults = false;
        services.dnscrypt-proxy2.settings = {
          server_names = [ "server" ];
          static.server.stamp = "sdns://AQAAAAAAAAAAEDE5Mi4xNjguMS4xOjUzNTMgFEHYOv0SCKSuqR5CDYa7-58cCBuXO2_5uTSVU9wNQF0WMi5kbnNjcnlwdC1jZXJ0LnNlcnZlcg";
        };
        networking.nameservers = [ "127.0.0.1" ];
        networking.interfaces.eth1.ipv4.addresses = lib.mkForce
          [ { address = "192.168.1.2"; prefixLength = 24; } ];
      };

  };

  testScript = ''
    start_all()

    with subtest("The server can generate the ephemeral keypair"):
        server.wait_for_unit("dnscrypt-wrapper")
        server.wait_for_file("/var/lib/dnscrypt-wrapper/2.dnscrypt-cert.server.key")
        server.wait_for_file("/var/lib/dnscrypt-wrapper/2.dnscrypt-cert.server.crt")

    with subtest("The client can connect to the server"):
        server.wait_for_unit("tinydns")
        client.wait_for_unit("dnscrypt-proxy2")
        assert "1.2.3.4" in client.succeed(
            "host it.works"
        ), "The IP address of 'it.works' does not match 1.2.3.4"

    with subtest("The server rotates the ephemeral keys"):
        # advance time by a little less than 5 days
        server.succeed("date -s \"$(date --date '4 days 6 hours')\"")
        client.succeed("date -s \"$(date --date '4 days 6 hours')\"")
        server.wait_for_file("/var/lib/dnscrypt-wrapper/oldkeys")

    with subtest("The client can still connect to the server"):
        server.wait_for_unit("dnscrypt-wrapper")
        client.succeed("host it.works")
  '';
})

