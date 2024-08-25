{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
    docker
    kubernetes
    kubectl
    kind
    kubectx
    kubernetes-helm
    minikube
  ]);
}
