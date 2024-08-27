{ config, lib, pkgs, ... }:

{
  home.packages = (with pkgs; [
      go
      protobuf
      protoc-gen-go
      protoc-gen-connect-go
      grpcurl
  ]);
}
