# macOS pf 转发 Shadowrocket 给局域网

目标：优先使用 Shadowrocket 自带的 `Proxy Share`。只有当原生共享入口在客户端不可用，或 Shadowrocket 选择的共享 IP 不是客户端要使用的入口时，才用 macOS `pf` 把一个客户端可达的 Mac 地址转发到本机 loopback 代理。

## 变量

| 变量 | 含义 |
| --- | --- |
| `<PROXY_SHARE_IP>` | Shadowrocket `Proxy Share` 页面显示的 `IP` |
| `<PORT>` | Shadowrocket `Proxy Share` 页面显示的 `Port` |
| `<LAN_IF>` | 准备用作 pf 入口的 Mac 网络接口 |
| `<LAN_IP>` | `<LAN_IF>` 上客户端可访问的 Mac IP |

参考文件：

| 文件 | 用途 |
| --- | --- |
| `~/.config/docs/pf-shadowrocket-references/pf.conf` | 本机已验证的 `/etc/pf.conf` 参考配置；迁移到别的机器前必须检查接口名 |
| `~/.config/docs/pf-shadowrocket-references/com.shadowrocket.pfctl.plist` | 开机启动 `pfctl` 的 LaunchDaemon |

## 判断流程

1. 先测试 Shadowrocket 原生 `Proxy Share`。
2. 如果 `<PROXY_SHARE_IP>:<PORT>` 在客户端可用，直接使用它，不需要 `pf`。
3. 如果原生共享不可用，但 Mac 本机 `127.0.0.1:<PORT>` 可用，再测试 `pf` 绕过。
4. 如果启用了 `pf`，它会接管匹配接口上的 `<PORT>` 入站流量；要重新测试原生 Proxy Share，需要先停用 `pf`。
5. 换网络、换接口、插拔网卡后，重新跑 `nc` / `curl` 验证，不只看 UI 显示或 `ping`。

## 1. 测试原生 Proxy Share

Shadowrocket：

| 项 | 值 |
| --- | --- |
| `Enable Share` | `On` |
| `Proxy Port` | `<PORT>` |
| `Proxy Type` | `HTTP` |
| `Compatibility Mode` | 优先 `On`；若本机和客户端测试都成功，`Off` 也可用 |

记录 `Proxy Share` 页面显示的 `<PROXY_SHARE_IP>:<PORT>`。UI 显示的 IP 只表示 Shadowrocket 选择了这个共享入口，不代表客户端一定能连通。

客户端测试：

```bash
# 只测 TCP 端口
nc -vz -w 3 <PROXY_SHARE_IP> <PORT>

# 测 HTTP 代理
curl -x http://<PROXY_SHARE_IP>:<PORT> https://www.google.com -v --connect-timeout 5
```

成功输出：

```text
Connection to <PROXY_SHARE_IP> <PORT> port [tcp/*] succeeded!
< HTTP/1.1 200 Connection established
< HTTP/2 200
```

如果这里成功，停止；不需要 `pf`。

## 2. 准备 pf 绕过

如果原生 Proxy Share 失败，把 Shadowrocket 的 `Proxy Address` 改为：

```text
127.0.0.1 / Loopback HTTP Proxy Server
```

Mac 本机验证 loopback 代理：

```bash
curl -x http://127.0.0.1:<PORT> https://www.google.com -v --connect-timeout 5
lsof -nP -iTCP:<PORT> -sTCP:LISTEN
```

期望输出：

```text
< HTTP/1.1 200 Connection established
< HTTP/2 200
```

如果 `127.0.0.1:<PORT>` 不可用，先修 Shadowrocket；不要继续配 `pf`。

## 3. 选择 pf 入口

找出 Mac 上客户端可访问的接口和 IP：

```bash
# 在 Mac 上查看局域网接口和 IP
ifconfig | grep -E "^[a-z0-9]+:|inet "
```

选择客户端准备连接的 Mac 入口地址 `<LAN_IP>`，并记录它所在接口 `<LAN_IF>`。

`<LAN_IP>` 可以等于 `<PROXY_SHARE_IP>`。原生 Proxy Share 在这个 IP 上失败，不代表 `pf rdr -> 127.0.0.1:<PORT>` 一定失败；但必须单独测试 `pf` 入口。

客户端确认路由：

```bash
# Linux 客户端：确认访问 Mac 入口 IP 时使用的源地址和接口
ip route get <LAN_IP>

# ping 只证明 IP 可达，不证明代理端口可用
ping -c 2 <LAN_IP>
```

选择规则：

| 场景 | 处理 |
| --- | --- |
| `<PROXY_SHARE_IP>:<PORT>` 客户端可用 | 直接使用 Shadowrocket 原生共享 |
| `<PROXY_SHARE_IP>:<PORT>` 不可用，但 `<PROXY_SHARE_IP>` 是唯一入口 | 可以在这个 IP 对应接口上测试 `pf` |
| Mac 有多个 IP | 只为实际需要且 `pf` 测试成功的接口写正式规则 |
| `.local` 解析到不可用 IP | 不要默认把 `.local` 作为客户端代理地址 |
| 只有单 IP 且原生共享不可用 | 仍可测试 `pf`；如果 `pf` 也失败，需要换网络、换监听方式或加中转服务 |

## 4. 临时测试 pf

建议先写临时文件，不要直接覆盖 `/etc/pf.conf`：

```pf
scrub-anchor "com.apple/*"
nat-anchor "com.apple/*"
rdr-anchor "com.apple/*"

# shadowrocket rdr
rdr pass on <LAN_IF> inet proto tcp from (<LAN_IF>:network) to (<LAN_IF>) port <PORT> -> 127.0.0.1 port <PORT>

dummynet-anchor "com.apple/*"
anchor "com.apple/*"
load anchor "com.apple" from "/etc/pf.anchors/com.apple"

# shadowrocket share lan
pass in on <LAN_IF> proto tcp from (<LAN_IF>:network) to (<LAN_IF>) port <PORT> keep state
pass out all keep state
```

写入 `/tmp/pf.conf.shadowrocket-test` 后测试：

```bash
# 只检查语法
sudo pfctl -nf /tmp/pf.conf.shadowrocket-test

# 临时加载，不覆盖 /etc/pf.conf
sudo pfctl -f /tmp/pf.conf.shadowrocket-test
sudo pfctl -e

# 验证规则
sudo pfctl -s nat
sudo pfctl -s rules | grep -E '<PORT>|<LAN_IF>'
sudo pfctl -s info | grep Status
```

期望输出：

```text
rdr pass on <LAN_IF> inet proto tcp from (<LAN_IF>:network) to (<LAN_IF>) port = <PORT> -> 127.0.0.1 port <PORT>
pass in on <LAN_IF> inet proto tcp from (<LAN_IF>:network) to (<LAN_IF>) port = <PORT> flags S/SA keep state
Status: Enabled
```

客户端测试：

```bash
nc -vz -w 3 <LAN_IP> <PORT>
curl -x http://<LAN_IP>:<PORT> https://www.google.com -v --connect-timeout 5
```

成功后再写入正式配置。

## 5. 写入正式 pf 配置

备份：

```bash
sudo cp /etc/pf.conf /etc/pf.conf.backup.$(date +%Y%m%d%H%M%S)
```

把已验证成功的临时配置写入 `/etc/pf.conf`：

```bash
sudo cp /tmp/pf.conf.shadowrocket-test /etc/pf.conf
sudo pfctl -nf /etc/pf.conf
sudo pfctl -f /etc/pf.conf
sudo pfctl -e
```

说明：

- `(<LAN_IF>)` 会跟随该接口的 IP 变化自动更新。
- `(<LAN_IF>:network)` 会跟随该接口所在网段变化自动更新。
- 如果接口名变化，仍需修改 `/etc/pf.conf`。
- 不要无差别给所有接口加规则；每个接口都必须单独验证。

## 6. 客户端使用

```bash
export http_proxy=http://<LAN_IP>:<PORT>
export https_proxy=http://<LAN_IP>:<PORT>
```

验证：

```bash
curl https://www.google.com -v --connect-timeout 5
```

## 7. 开机启动

安装 plist：

```bash
sudo cp ~/.config/docs/pf-shadowrocket-references/com.shadowrocket.pfctl.plist /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
sudo chown root:wheel /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
sudo chmod 644 /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
plutil -lint /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
```

如果任务已存在：

```bash
sudo launchctl bootout system /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/com.shadowrocket.pfctl.plist
```

验证：

```bash
sudo launchctl print system/com.shadowrocket.pfctl
sudo pfctl -s info | grep Status
```

期望输出：

```text
arguments = {
        /bin/sh
        -c
        /sbin/pfctl -f /etc/pf.conf && /sbin/pfctl -e
}
Status: Enabled
```

## 已知结论

以下结论来自当前网络实测，换网络后应重新验证：

| 项 | 结论 |
| --- | --- |
| Shadowrocket 原生 Proxy Share | 单网卡场景下可以开箱即用；多网卡场景下 UI 显示的 IP 可能端口不可用 |
| `ping <PROXY_SHARE_IP>` | 只证明 IP 可达，不证明代理端口可用 |
| `127.0.0.1:<PORT>` | Mac 本机 loopback HTTP proxy 可用时，可作为 `pf rdr` 目标 |
| `198.18.0.3:<PORT>` | Mac 本机可访问，但客户端不能直连；当前测试中不适合作为 `pf rdr` 目标 |
| `.local` 主机名 | 可能解析到不可用共享 IP；需要用 `nc` / `curl` 验证 |
| 已启用 `pf` | 会接管匹配接口上的 `<PORT>` 入站流量；测试原生 Proxy Share 前应先停用 `pf` |

## 换网络后的检查

```bash
# 查看当前接口/IP
ifconfig | grep -E "^[a-z0-9]+:|inet "

# 查看当前 pf 规则
sudo pfctl -s nat
sudo pfctl -s rules | grep <PORT>

# 客户端重新验证
nc -vz -w 3 <LAN_IP> <PORT>
curl -x http://<LAN_IP>:<PORT> https://www.google.com -v --connect-timeout 5
```

## 维护

重新加载：

```bash
sudo pfctl -nf /etc/pf.conf
sudo pfctl -f /etc/pf.conf
```

临时停用：

```bash
sudo pfctl -d
```

回滚：

```bash
sudo cp /etc/pf.conf.backup.<timestamp> /etc/pf.conf
sudo pfctl -f /etc/pf.conf
sudo pfctl -d
```

日志：

```bash
cat /var/log/pfctl-launchd.out
cat /var/log/pfctl-launchd.err
log show --predicate 'process == "pfctl"' --last 5m
```
