{
  inputs = {
    mise.url = "git+https://github.com/josiah14/mise.git";
    nixpkgs.follows = "mise/nixpkgs";
  };

  outputs = { self, mise, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages =
          mise.lib.${system}.mercury-22-01-8
          ++ mise.lib.${system}.bats-1-12-0;

        shellHook = ''
          export CINNABAR_DEV_PATH="$PATH"
          export CINNABAR_USER_ZDOTDIR="$HOME"
          export ZDOTDIR="${./dev-shell/zsh}"
        '';
      };
    };
}
