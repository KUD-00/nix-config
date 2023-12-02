{ config, pkgs, ... }:

{
  home.file."Developer/scripts/acpi-toggle.sh" = {
    source = ../scripts/acpi-toggle.sh;
    executable = true;
  };
}
