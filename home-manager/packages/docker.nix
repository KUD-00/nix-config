{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
    docker
    kubernetes
    (lib.hiPrio kubectl)
    kubectx
    kubernetes-helm
    minikube
  ]);
}
