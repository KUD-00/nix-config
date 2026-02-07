# NixOS GitHub Self-hosted Runners 配置指南

## 1. 获取 GitHub Token

创建 GitHub Personal Access Token (PAT)：

1. 进入 GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. 权限要求：
   - 仓库级别：`administration:write`
   - 组织级别：`organization_self_hosted_runners:write`

## 2. 使用 sops-nix 管理 Token

### 添加 sops secret

```bash
sops secrets/secrets.yaml
```

添加内容：

```yaml
github-runner-token: ghp_xxxxxxxxxxxxxx
```

## 3. NixOS 配置

在 `lain-configuration.nix` 中添加：

```nix
{ inputs, config, pkgs, ... }:

{
  # GitHub Runner Token (通过 sops-nix)
  sops.secrets.github-runner-token = {
    # token 格式：直接是 token 字符串，无换行符
  };

  # GitHub Self-hosted Runner 配置
  services.github-runners = {
    lain-runner = {
      enable = true;
      name = "lain-runner";

      # 仓库或组织 URL
      url = "https://github.com/用户名/仓库名";
      # 或组织级别: url = "https://github.com/组织名";

      # Token 文件路径
      tokenFile = config.sops.secrets.github-runner-token.path;

      # 额外标签
      extraLabels = [ "nixos" "x86_64-linux" "cuda" ];

      # runner 可以访问的额外工具
      extraPackages = with pkgs; [
        docker
        git
        nodejs
      ];

      # 每次运行完一个 job 后注销（安全选项）
      ephemeral = false;

      # 替换同名的 runner
      replace = true;
    };

    # 可以添加更多 runner
    # lain-runner-2 = { ... };
  };
}
```

## 4. 配置选项说明

| 选项 | 说明 |
|------|------|
| `enable` | 启用 runner |
| `name` | Runner 名称 |
| `url` | GitHub 仓库或组织 URL |
| `tokenFile` | Token 文件路径（每行一个 token，无换行） |
| `extraLabels` | 额外标签，用于 `runs-on` |
| `extraPackages` | 添加到 runner PATH 的包 |
| `ephemeral` | 每个 job 后注销（需要 PAT） |
| `replace` | 替换同名 runner |
| `runnerGroup` | Runner 组（组织级别） |
| `nodeRuntimes` | Node.js 版本 (默认 `["node20", "node24"]`) |

## 5. 部署与验证

```bash
# 部署配置
sudo nixos-rebuild switch --flake .#Lain

# 检查服务状态
systemctl status github-runner-lain-runner

# 查看日志
journalctl -u github-runner-lain-runner -f
```

## 6. GitHub Actions 使用示例

### 仅使用 self-hosted runner

```yaml
jobs:
  build:
    runs-on: [self-hosted, nixos, x86_64-linux]
    steps:
      - uses: actions/checkout@v4
      - run: nix build .#
```

### 带 Fallback 的配置（推荐）

如果 self-hosted runner 离线，自动 fallback 到 GitHub-hosted runner：

```yaml
jobs:
  build:
    runs-on: ${{ github.repository_owner == 'your-username' && 'self-hosted' || 'ubuntu-latest' }}
    steps:
      - uses: actions/checkout@v4
      - run: echo "Running on available runner"
```

### 使用 matrix 实现 Fallback

```yaml
jobs:
  build:
    strategy:
      matrix:
        runner: [self-hosted, ubuntu-latest]
      fail-fast: false
    runs-on: ${{ matrix.runner }}
    continue-on-error: ${{ matrix.runner == 'self-hosted' }}
    steps:
      - uses: actions/checkout@v4
      - run: echo "Building..."
```

## 7. Fallback 行为说明

**重要**: GitHub 不会自动 fallback！

- 如果指定 `runs-on: self-hosted`，且 runner 离线，job 会一直等待（最多排队等待，不会自动切换）
- 要实现 fallback，必须在 workflow 中显式配置（见上方示例）
- 建议为关键 CI 流程配置 fallback 机制

## 参考资料

- [NixOS GitHub Runner Options](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/continuous-integration/github-runner/options.nix)
- [github-nix-ci](https://github.com/juspay/github-nix-ci)
- [GitHub Self-hosted Runners 文档](https://docs.github.com/en/actions/hosting-your-own-runners)
