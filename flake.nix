{
  inputs = {
    mise.url = "git+https://github.com/josiah14/mise.git";
  };

  outputs = { self, mise }:
    let
      system = "x86_64-linux";
    in
    {
      devShells.${system}.default = mise.devShells.${system}.mercury-22-01-8;
    };
}
