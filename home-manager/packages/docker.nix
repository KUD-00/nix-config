{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
    docker
    kubernetes
    kubectl
    kubectx
    kubernetes-helm
    minikube
  ]);
}
