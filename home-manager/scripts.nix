{ config, pkgs, ... }:

{
  home.file."Developer/scripts/acpi-toggle.sh" = {
    source = ../scripts/acpi-toggle.sh;
    executable = true;
  };

  home.file."Developer/scripts/codex-accounts.sh" = {
    source = ../scripts/codex-accounts.sh;
    executable = true;
  };
}
