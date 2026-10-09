# claude-code-proxy 开机启动（Rocky Linux 8 / Ubuntu 24.04）

这两个安装入口共用 `install-claude-code-proxy-common.sh`、`claude-code-proxy.service.in` 和 `claude-code-proxy-launcher.sh`，复制时须保留本目录下的五个文件。`install-claude-code-proxy-common.sh` 是共用的实际安装逻辑：校验系统和参数、生成并备份 systemd 配置、设置出站代理、启用开机启动并重启服务。Rocky 和 Ubuntu 的两个短脚本只负责选择对应系统，然后调用它；**不要单独运行 common 脚本**。安装脚本不会安装代理程序或执行 Codex 登录；不要在非目标机器运行。

## 准备

1. 先按 [项目说明](https://github.com/raine/claude-code-proxy)安装 `claude-code-proxy`，默认可执行文件为 `/home/server/.local/bin/claude-code-proxy`。**Rocky Linux 8 的系统 glibc 是 2.28，项目目前发布的 Linux GNU 预编译包可能要求更高版本；安装前务必先运行 `claude-code-proxy --version`。** 如果出现 `GLIBC_2.29` 等缺失错误，不能使用这个预编译包，也不要替换系统 glibc。请在 Rocky 8 本机从 [官方源码](https://github.com/raine/claude-code-proxy)编译（需要支持 Rust 2024 edition 的 Rust 1.85 或更新版本）：

   ```bash
   sudo dnf install -y git gcc make curl ca-certificates
   # 按 https://rustup.rs/ 安装当前 stable Rust，确认 rustc --version 不低于 1.85
   git clone --branch v0.1.44 --depth 1 https://github.com/raine/claude-code-proxy.git
   cd claude-code-proxy
   cargo build --release --locked
   install -d "$HOME/.local/bin"
   if [ -e "$HOME/.local/bin/claude-code-proxy" ]; then
     cp -p "$HOME/.local/bin/claude-code-proxy" "$HOME/.local/bin/claude-code-proxy.bak-$(date +%Y%m%d%H%M%S)"
   fi
   install -m 755 target/release/claude-code-proxy "$HOME/.local/bin/claude-code-proxy"
   "$HOME/.local/bin/claude-code-proxy" --version
   ```

   上例以 v0.1.44 为例；如果使用其他版本，请用相应的官方 tag 并确认构建成功。**以上命令须以计划运行服务的非 root 用户执行**；缺少 Rust 时先安装 Rust 再运行 `cargo`。安装脚本也会在修改 systemd 配置前检查 `--version` 能否在目标机器运行。
2. 以准备运行服务的 Linux 用户完成登录。默认服务用户是 `server`：

   ```bash
   sudo -u server -H /home/server/.local/bin/claude-code-proxy codex auth login
   sudo -u server -H /home/server/.local/bin/claude-code-proxy codex auth status
   ```

3. 确认目标主机能访问出站 HTTP 代理。默认代理地址为之前的固定地址 **`http://10.220.69.222:1088`**。交互式安装时也可以选择自动获取默认网关 IP 并使用端口 **`8889`**，或输入自定义代理 URL。安装脚本会为 systemd 服务设置 `HTTP_PROXY` 和 `HTTPS_PROXY`，以及默认的 `NO_PROXY=localhost,127.0.0.1,server.teleport.zetyun.cn`。systemd 服务不会继承交互式 shell 中的代理变量。

## 安装或覆盖更新

先停止任何在终端手动运行的 `claude-code-proxy serve`，避免其占用 `127.0.0.1:18765`。在目标 Linux 主机进入这四个文件所在目录，运行对应系统的脚本：

```bash
# Rocky Linux 8
sudo ./install-claude-code-proxy-rocky8.sh

# Ubuntu 24.04
sudo ./install-claude-code-proxy-ubuntu2404.sh
```

不带参数时，默认用户为 `server`，路径为 `/home/server/.local/bin/claude-code-proxy`，出站代理为 `http://10.220.69.222:1088`。在交互式终端可按提示修改用户、程序路径和代理地址；选择自动模式后，服务每次启动都会执行 `ip route show | grep -i default | awk '{ print $3 }'` 获取网关 IP，并使用端口 `8889`。要非交互式使用自动模式或其他地址，依次传入**用户、程序绝对路径、`auto` 或无凭据代理 URL**：

```bash
sudo ./install-claude-code-proxy-rocky8.sh server /home/server/.local/bin/claude-code-proxy http://proxy.example.com:1088
# 自动获取默认网关 IP，使用 8889 端口
sudo ./install-claude-code-proxy-rocky8.sh server /home/server/.local/bin/claude-code-proxy auto
```

如果仅更换用户，默认程序路径会相应变为 `/home/<用户名>/.local/bin/claude-code-proxy`。要调整 `NO_PROXY`，可在启动脚本时设置 `CCP_NO_PROXY`，例如：

```bash
sudo env CCP_NO_PROXY=localhost,127.0.0.1,internal.example.com ./install-claude-code-proxy-rocky8.sh
```

脚本**可以重复运行**：已有 unit 和脚本管理的 drop-in 会先分别备份，再覆盖安装；备份路径会打印在输出中。更新后执行 `daemon-reload`、启用服务、重启服务并检查其保持运行。脚本不会删除用户自己建立的其他 drop-in；新的 `zz-claude-code-proxy-managed.conf` 会覆盖旧版说明文档创建的 `override.conf`、`20-no-monitor.conf` 和 `30-network-proxy.conf` 中相同的项目，使指定的用户、HOME、二进制和代理地址真正生效。若还存在字母顺序更靠后的自定义 drop-in，请用 `systemctl cat claude-code-proxy` 检查最终配置。出现错误时，先看日志；备份不会自动恢复。

Rocky 8 安装入口会在启动服务前处理 SELinux：如果 SELinux 已启用，为指定的代理程序执行 `semanage fcontext -a -t bin_t` 和 `restorecon -v`，避免普通用户文件标签导致 systemd 报 `203/EXEC`。规则支持重复安装，也适用于自定义程序路径；SELinux 已禁用时跳过。若缺少 `semanage`，先执行 `sudo dnf install -y policycoreutils-python-utils`，再重新运行安装脚本。

服务采用启动器调用 `claude-code-proxy serve --no-monitor`，由 systemd 管理、在失败时重启。默认模式下启动器每次运行都会重新读取默认路由，因此执行 `sudo systemctl start claude-code-proxy` 或 `restart` 后会使用最新 IP。网络代理地址会保存在可读的 unit 中；**不要把用户名或密码写入代理 URL**。需要带凭据的代理时，请另外使用访问受限的环境文件，不要通过此脚本传递密码。

## 常用管理命令

```bash
sudo systemctl status claude-code-proxy
sudo journalctl -u claude-code-proxy -b --no-pager
sudo systemctl restart claude-code-proxy
sudo systemctl stop claude-code-proxy
sudo systemctl disable --now claude-code-proxy
```

`stop` 只停止当前服务，开机启动仍然保留；`disable --now` 会立即停止服务，并取消开机启动。若要重新启用并立即启动，运行 `sudo systemctl enable --now claude-code-proxy`。

## 验证

```bash
sudo systemctl status claude-code-proxy --no-pager
systemctl show claude-code-proxy -p MainPID -p ExecStart -p WorkingDirectory -p DropInPaths --no-pager
ss -ltnp '( sport = :18765 )'
curl -fsS http://127.0.0.1:18765/v1/models >/dev/null && echo '本地代理可访问'
```

`MainPID` 应非零，且与监听端口的进程相同。`/v1/models` 返回成功**只验证本地连接**，不能证明 Codex 上游可用。若要做一条真实请求（会使用 Codex 模型额度），可手动执行：

```bash
curl -fsS --max-time 120 http://127.0.0.1:18765/v1/messages \
  -H 'content-type: application/json' \
  -H 'anthropic-version: 2023-06-01' \
  -H 'x-api-key: unused' \
  --data '{"model":"gpt-6-sol","max_tokens":128,"messages":[{"role":"user","content":"Reply with only OK."}]}'
```

看到响应包含 `"stop_reason":"end_turn"` 和 `OK` 表示请求已走通上游。服务启动失败时运行 `sudo journalctl -u claude-code-proxy -b -n 80 --no-pager`；如果报端口被占用，先退出手动启动的代理，再重启服务。代理默认只监听 `127.0.0.1:18765`，不能从另一台机器直接访问；需要跨机访问时请规划安全的 SSH 隧道，勿直接把无认证代理公开到网络。
