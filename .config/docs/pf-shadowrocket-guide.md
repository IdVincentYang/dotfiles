# 在 macOS 上用 pf 转发 Shadowrocket 代理给局域网

本文档记录了如何在 macOS 上使用 `pf`（Packet Filter）将 Shadowrocket 打开的本地代理端口分享给同一个局域网中的其他设备。每个阶段都包含**目的、操作步骤、预期结果、验证方法**以及**常见错误与修复办法**，方便排查。

## 前置条件
- **目的**：确保系统满足执行步骤的基本要求。
- **操作**：
  - 使用具有管理员权限的账户登录，终端中确认 `sudo` 可用：`sudo -v`。
  - Shadowrocket 已安装并能在本机访问被墙站点，且启用了「Settings → Proxy → Proxy Share」，设置 `Proxy Type` 为支持 HTTPS CONNECT（推荐 Mixed/SOCKS5），端口示例为 `1082`。
  - 确认 Shadowrocket 绑定的监听地址为 `127.0.0.1` 或 `198.18.0.3`，这决定了我们必须依赖 `pf` 做转发。
- **预期结果**：本机通过 `curl -x http://127.0.0.1:1082 https://www.google.com -v` 可以成功访问 Google。
- **验证**：同上命令返回 200/302，即表示代理本身可用。
- **常见错误/修复**：
  - Curl 卡住：Shadowrocket 规则把站点走了 DIRECT → 将模式切到 Proxy 或 Global。
  - 返回 407：检查 Shadowrocket 是否设置了身份验证，必要时在客户端提供账号密码。

## 步骤 0：按照 Shadowrocket 界面设置共享参数
- **目的**：确保 Shadowrocket 的共享端口配置完整，让 `pf` 转发的流量能被其监听并走代理节点。
- **操作**：
  1. 打开 Shadowrocket → `Settings → Proxy → Proxy Share`。
  2. 在 `Proxy Share` 页面将 `Enable Share` 切换为 `On`。
  3. `Proxy Address` 按界面提供的两个选项选择：
     - `127.0.0.1`：仅绑定回环地址；需要结合本文的 `pf` 方案把局域网请求转到本地。
     - `198.18.0.3`：Shadowrocket 虚拟网卡地址，可被局域网直接访问；若计划直接公布此地址，可不依赖 `pf`。
  4. `Proxy Port` 设置为准备共享的端口（示例 `1082`，需与 `pf` 规则保持一致）。
  5. `Proxy Type` 按需选择（界面可见 `HTTP` / `SOCKS5` / 其它类型）。若希望处理 HTTPS，建议选 `HTTP` 搭配 `Compatibility Mode On`，或直接选择 `Mixed/SOCKS5`。
  6. `Compatibility Mode` 保持 `On`。
  7. `Proxy Chain`（界面显示为 `Enable Chain`）保持 `Off`，除非确实要做级联。
  8. 返回 `Settings → Proxy`，在 `Proxy Share` 部分确认 `IP` 字段已显示可被局域网访问的地址（如 `192.168.61.207`）。
- **预期结果**：Shadowrocket 在所选 `Proxy Address`/`Proxy Port` 上监听，并接受 HTTP/HTTPS 请求。
- **验证**：
  - 本机执行 `curl -x http://127.0.0.1:1082 https://www.google.com -v`（或对应的 `Proxy Address`），应能访问。
  - `lsof -iTCP:1082 -sTCP:LISTEN` 可看到 `PacketTunnel` 进程处于监听状态。
  - Shadowrocket → `Logs` 会记录来自共享端口的请求。
- **常见错误/修复**：
  - `Enable Share` 忘记打开：局域网设备连接会直接被拒绝。
  - `Proxy Type` 仅为 `HTTP` 且 `Compatibility Mode Off`：HTTPS CONNECT 会失败 → 打开 `Compatibility Mode` 或换成支持 CONNECT 的类型。
  - `Proxy Address` 选 `127.0.0.1` 却让局域网直连：需要结合 `pf` 按本文配置 `en6` 转发；若想绕过 `pf`，应改选 `198.18.0.3` 并直接发布该地址。

## 步骤 1：确认局域网接口和 IP
- **目的**：找到 Shadowrocket 虚拟网卡对应的接口（示例为 `en6`，IP `192.168.60.253`），以便在 `pf` 中使用正确的网卡名称和地址。
- **操作**：
  - `networksetup -listallhardwareports` 或 `ifconfig en0`, `ifconfig en6` 等命令查看接口与 IP 的对应关系。
  - 记录局域网客户端所在网段（示例 `192.168.60.0/24`）。
- **预期结果**：知道“局域网机器访问哪个 IP 才能找到这台 Mac”。
- **验证**：`ifconfig en6` 输出中包含 `inet 192.168.60.253 netmask 0xffffff00` 且 `status: active`。
- **常见错误/修复**：
  - 找错接口：抓包 `sudo tcpdump -i <interface> port 1082`，无流量则说明接口不对。
  - 接口 inactive：确保 Shadowrocket/VPN 已启动，否则 `en6` 不会出现。

## 步骤 2：编辑 `/etc/pf.conf`
- **目的**：把端口转发及允许规则直接写入系统主配置，避免依赖额外文件。
- **操作**：
 1. 备份：`sudo cp /etc/pf.conf /etc/pf.conf.backup.$(date +%Y%m%d%H%M%S)`。
 2. 在 `rdr-anchor "com.apple/*"` 后、`anchor "com.apple/*"` 之前插入：
    ```
    rdr pass on en6 inet proto tcp from 192.168.60.0/24 to 192.168.60.253 port 1082 -> 127.0.0.1 port 1082
    ```
 3. 在文件末尾或其它过滤段添加：
    ```
    pass in on en6 proto tcp from 192.168.60.0/24 to 192.168.60.253 port 1082 keep state
    pass out all keep state
    ```
- **预期结果**：`/etc/pf.conf` 内联包含了局域网转发所需的 `rdr` 与 `pass` 规则。
- **验证**：`sudo pfctl -nf /etc/pf.conf` 显示无错误。
- **常见错误/修复**：
  - “Rules must be in order ...” → 确保 `rdr` 行位于 `anchor "com.apple/*"` 之前。
  - “syntax error” → 重新检查是否遗漏 `proto tcp` 或端口写法。

## 步骤 3：加载并启用 `pf`
- **目的**：让新规则立即生效并在当前会话中启用 `pf`。
- **操作**：
  - `sudo pfctl -f /etc/pf.conf`
  - `sudo pfctl -e`（若已启用会提示 `pf already enabled`）
- **预期结果**：`pfctl` 成功加载配置，状态为 Enabled。
- **验证**：
  - `sudo pfctl -s nat` 能看到 `rdr pass on en6 ...` 条目。
  - `sudo pfctl -s info | grep Status` 显示 `Enabled`。
- **常见错误/修复**：
  - `pfctl: pf already enabled` → 只是提示，无需处理。
  - `No ALTQ support in kernel` → macOS 默认无 ALTQ，可忽略。

## 步骤 4：局域网测试
- **目的**：确保其他设备可以通过 Mac 的共享端口访问互联网。
- **操作**：
  - 在客户端设置 `http_proxy`、`https_proxy` 或浏览器代理为 `http://192.168.60.253:1082`。
  - 运行 `curl -x http://192.168.60.253:1082 https://www.google.com -v`。
- **预期结果**：客户端能访问 Google 等被墙站点，说明流量经由 Shadowrocket。
- **验证**：
  - 命令返回 HTML 或 200/302。
  - 在 Mac 上 `sudo tcpdump -i en6 port 1082` 可看到 `CONNECT` 请求，Shadowrocket 日志也会出现对应 IP。
- **常见错误/修复**：
  - `curl` 超时：客户端和 Mac 不在同一网段或代理地址写成 `192.168.61.xxx` → 改用 `192.168.60.253`。
  - 仍访问不了：Shadowrocket “Proxy Type” 未支持 CONNECT → 改成 Mixed/SOCKS5 或 HTTP(CONNECT)。

## 步骤 5：配置自启动（可选）
- **目的**：系统重启后自动加载 `pf` 规则，并启用防火墙。
- **操作**：
  1. 在 `~/com.shadowrocket.pfctl.plist` 写入：
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
     <dict>
       <key>Label</key>
       <string>com.shadowrocket.pfctl</string>
       <key>ProgramArguments</key>
       <array>
         <string>/bin/sh</string>
         <string>-c</string>
         <string>pfctl -f /etc/pf.conf && pfctl -e</string>
       </array>
       <key>RunAtLoad</key>
       <true/>
       <key>StandardErrorPath</key>
       <string>/var/log/pfctl-launchd.err</string>
       <key>StandardOutPath</key>
       <string>/var/log/pfctl-launchd.out</string>
     </dict>
     </plist>
     ```
  2. 移动到 `/Library/LaunchDaemons/` 并设置权限：
     ```
     sudo mv ~/com.shadowrocket.pfctl.plist /Library/LaunchDaemons/
     sudo chown root:wheel /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
     sudo chmod 644 /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
     sudo launchctl load /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
     ```
- **预期结果**：开机后自动运行 `pfctl -f` 和 `pfctl -e`。
- **验证**：重启后执行 `sudo pfctl -s info`，应显示 `Status: Enabled`；`log show --predicate 'process == "pfctl"' --last 5m` 可查看启动日志。
- **常见错误/修复**：
  - `launchctl: Permission denied` → 确保 plist 放在 `/Library/LaunchDaemons` 并归属 `root:wheel`。
  - 日志提示找不到 `/etc/pf.conf` → 文件路径写错或权限不足，修复后 `launchctl unload` 再 `load`。

## 维护与回滚
- **修改端口或网段**：直接编辑 `/etc/pf.conf` 中的 `rdr/pass` 行，调整端口/子网后运行 `sudo pfctl -f /etc/pf.conf`。
- **临时停用**：`sudo pfctl -d` 会禁用 `pf`（直到下次 `pfctl -e` 或重启由 launchd 重新加载）。
- **回滚到原始配置**：`sudo cp /etc/pf.conf.backup.<timestamp> /etc/pf.conf && sudo pfctl -f /etc/pf.conf && sudo pfctl -d`。
- **常见日志位置**：`/var/log/pfctl-launchd.out`、`/var/log/pfctl-launchd.err`、`log show --predicate 'process == "pfctl"' --last 5m`。

通过以上步骤即可稳定地把 Shadowrocket 的本地代理端口分享给局域网电脑，同时保证配置在系统重启后可自动恢复。
