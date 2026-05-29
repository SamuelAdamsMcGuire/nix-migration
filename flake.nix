{
  description = "Datatactics company laptop fleet — NixOS configuration";

  inputs = {
    # Pinned to 25.11 stable. Bump to 26.05 once you've validated on one machine.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        # ---- First fleet host: this ThinkPad ----
        # Add more laptops by copying hosts/<name>/ and adding an entry here.
        samuel-21tb003mge = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/samuel-21tb003mge
            sops-nix.nixosModules.sops
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.samuel = import ./home/samuel;
            }
          ];
        };
      };
    };
}
