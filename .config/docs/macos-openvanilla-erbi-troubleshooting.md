# macOS OpenVanilla ERBI 灰色不可选排查

适用于 macOS 中 OpenVanilla 在输入法菜单里灰色、无法选中，或选择后仍直接输出英文字母的情况。优先通过命令行读取设置和状态，再用实际输入候选字验收。

**2026 年 10 月 17 日的已验证原因是 KeePassXC 持续占用安全输入。正常退出 KeePassXC 后，系统解除对 OpenVanilla 的禁用，用户确认 ERBI 候选字恢复。**

## 快速处理

1. 确认正在普通文本框中输入，而非密码框。
2. 运行下面的只读诊断，记录安全输入状态；需要时加 `--menu` 读取菜单实际允许的输入源。
3. 如果安全输入开启且 KeePassXC 正在运行，先保存密码库中的修改，再正常完全退出 KeePassXC。
4. 重复同一条诊断命令，对照状态是否变化。
5. 手动选择 OpenVanilla，输入小写 `a`，确认出现 ERBI 候选字。

```sh
python3 "$HOME/.config/docs/openvanilla-references/status.py"

# 可选的深入查询，使用 macOS 私有菜单接口
python3 "$HOME/.config/docs/openvanilla-references/status.py" --menu
```

脚本仅适用于 macOS，使用 Python 3 标准库。默认查询公开的 `IsSecureEventInputEnabled()`；`--menu` 在子进程中查询菜单并设置超时。脚本不选择输入源、不模拟按键、不终止应用、不写偏好，也不进行网络访问。

安全输入开启不一定是异常，密码框可以正常启用它。需要确认的是：离开密码输入后状态是否仍保持，以及相关应用退出后是否解除。若退出 KeePassXC 后状态未变，继续按下文检查，不能直接认定同一个原因。

## 本次案例与证据

案例软件版本为 macOS 27.0.1、OpenVanilla 1.8.3、KeePassXC 2.7.12。版本用于界定本次观察范围，不代表其他版本必然具有相同行为。

症状：

- 输入法菜单中的 OpenVanilla 灰色，点击无法正常切入。
- 输入 `a` 得到英文字母，没有 ERBI 候选字。
- 在文本编辑的新建文档中也复现。
- 锁屏解锁和注销重新登录后仍未恢复。

对照结果：

| 操作后的状态 | 安全输入 | 菜单实际允许的键盘输入源 | 实际输入结果 |
| --- | --- | --- | --- |
| 故障时 | `true` | 系统拼音、ABC | OpenVanilla 灰色，无候选字 |
| 正常完全退出 Firefox | `true` | 系统拼音、ABC | 禁用状态未解除 |
| 正常完全退出 KeePassXC | `false` | 系统拼音、OpenVanilla、ABC | 用户确认 OpenVanilla 可选，ERBI 候选字恢复 |

退出 KeePassXC 前后，OpenVanilla 的进程 PID 未变，安装位置仍为用户目录。词库、偏好和应用签名均未在这次退出对照中修改。

因此，本次已定位到 KeePassXC 持续占用安全输入这一直接原因。其内部具体触发步骤尚未复现；此前提到的键盘卡顿也未单独确认原因。

## 读取安全输入与菜单状态

### 公开状态查询

```sh
python3 "$HOME/.config/docs/openvanilla-references/status.py"
```

重点看 `secure_event_input_before` 和 `secure_event_input_after`：

- `true`：系统安全输入开启，需要结合输入框类型和应用退出对照判断。
- `false`：当次采样未处于安全输入状态；继续检查词库、活动方案、注册和进程。
- `null` 或 `status: "unknown"`：查询失败，不能解释成安全输入关闭。
- `state_changed: true`：查询期间状态有变化，待状态稳定后重新采集。

### 实际菜单查询

```sh
python3 "$HOME/.config/docs/openvanilla-references/status.py" --menu
```

只有 `menu.status` 为 `ok`、`transport_ok` 和 `reply_received` 为 `true`，且 `source_ids` 为有效数组时，才解释菜单结果。OpenVanilla 的 ID 是：

```text
org.openvanilla.inputmethod.OpenVanilla
```

本次故障时，菜单 `source_ids` 只有：

```json
["com.apple.inputmethod.SCIM.ITABC", "com.apple.keylayout.ABC"]
```

退出 KeePassXC 后，列表重新包含 OpenVanilla。

`--menu` 使用 `TextInputMenuUI` 中 `TSMMessageHandler` 的消息 22，读取现存菜单对象中过滤禁用项后的输入源 ID。本次在 macOS 27.0.1 中确认该消息为只读；脚本仅对这个已审阅版本启用此查询。私有接口可能随系统更新改变，其他版本或查询失败一律视为未知，不能视为 OpenVanilla 被禁用。默认的公开安全输入查询可独立使用。

菜单结果里的 `front_pid` 是采样时的前台应用 PID，用于对照查询上下文，**不是安全输入持有者**。查询前后前台应用发生变化时，应在同一普通文本输入场景中重采。

### 用应用正常退出做因果对照

先记录安全输入、实际菜单列表和 OpenVanilla PID：

```sh
python3 "$HOME/.config/docs/openvanilla-references/status.py" --menu
pgrep -x OpenVanilla
```

保存相关应用中的未完成修改，经用户确认后正常完全退出一个有依据关联的应用，再采集同组状态。KeePassXC 是本次已验证的首要对象；仅关闭窗口或锁定密码库不等于退出进程。

```sh
# 没有输出通常表示主进程已退出
pgrep -x KeePassXC

python3 "$HOME/.config/docs/openvanilla-references/status.py" --menu
pgrep -x OpenVanilla
```

以“安全输入解除、菜单重新允许 OpenVanilla、用户看到候选字”构成恢复确认。一次退出后状态不变，也可能仍有其他持有者，不能仅凭这一结果概括某个应用永远无关。

## 检查 ERBI 词库和活动方案

### 核对词库链接

本目录中的安装 recipe 使用以下路径：

```text
词库源：~/.config/backups/erbi/OpenVanilla/erbi.cin
输入法读取位置：~/Library/Application Support/OpenVanilla/UserData/TableBased/erbi.cin
```

只读检查：

```sh
source_table="$HOME/.config/backups/erbi/OpenVanilla/erbi.cin"
target_dir="$HOME/Library/Application Support/OpenVanilla/UserData/TableBased"
target_table="$target_dir/erbi.cin"

ls -ld "$target_dir" "$target_table" "$source_table"
readlink "$target_table"
test -r "$target_table" && printf 'table readable\n'
cmp -s "$source_table" "$target_table" && printf 'table matches source\n'
```

本次链接存在、可读、指向正确源文件；使用 OpenVanilla 1.8.3 的实际解析器也能解析该词库。故障排查中发现的 `%selket` 拼写和缺少 `%chardef end` 被该版本解析器容忍，未导致本次菜单灰色，不应顺带修改词库来处理此故障。

### 链接确实失效时再修复

旧聊天“排查 OpenVanilla 输入法灰色”在 2026 年 8 月 20 日记录过词库目录或链接缺失，处理动作是重建链接并启动输入法。该轮旧记录没有后续用户候选字验收；它提供了检查词库的线索，不能代替本次的退出对照证据。

只有确认链接缺失、断裂或指错位置时，才执行以下修复。有效源不存在时停止；目标已有内容先移入同目录下的独立保护目录。

```sh
(
    set -eu
    source_table="$HOME/.config/backups/erbi/OpenVanilla/erbi.cin"
    target_dir="$HOME/Library/Application Support/OpenVanilla/UserData/TableBased"
    target_table="$target_dir/erbi.cin"

    if [ ! -f "$source_table" ] || [ ! -r "$source_table" ] || [ ! -s "$source_table" ]; then
        printf 'No readable non-empty source table; existing target preserved.\n' >&2
        exit 1
    fi

    mkdir -p "$target_dir"
    if [ -e "$target_table" ] || [ -L "$target_table" ]; then
        protection_dir=$(mktemp -d "$target_dir/erbi-link-backup.XXXXXX")
        mv "$target_table" "$protection_dir/erbi.cin"
        printf 'Previous target preserved in %s\n' "$protection_dir"
    fi

    ln -s "$source_table" "$target_table"
    cmp -s "$source_table" "$target_table"
)
```

之后再启动或重启 OpenVanilla，并实际输入确认。安装逻辑见 [justfile](../justfile) 中 `system-productivity-openvanilla-darwin`。

### 核对活动方案与启用记录

```sh
defaults read org.openvanilla.inputmethod.OpenVanilla ActiveInputMethod
defaults read org.openvanilla.inputmethod.OpenVanilla ExcludedInputMethods
defaults read com.apple.inputsources AppleEnabledThirdPartyInputSources
defaults read com.apple.HIToolbox AppleEnabledInputSources
```

预期：

- 活动方案为 `org.openvanilla.OVIMTableBased.erbi`。
- ERBI 没有出现在 `ExcludedInputMethods` 中。
- 两个系统启用列表均包含 `Bundle ID = org.openvanilla.inputmethod.OpenVanilla`、`InputSourceKind = Keyboard Input Method`。

本次这几项均正常，并与旧成功记录中的启用字典一致。系统管理的输入源偏好不纳入自动迁移；需要恢复应用偏好时使用 `defaults export/import`，详细规则见 [macOS 应用配置备份与恢复](macos-app-config-backup-restore.md)。

## 安全输入关闭后仍有问题

先确认词库和活动方案，再按证据检查以下项目。

### 进程与应用完整性

```sh
app="$HOME/Library/Input Methods/OpenVanilla.app"

pgrep -x OpenVanilla
plutil -p "$app/Contents/Info.plist"
codesign --verify --deep --strict --all-architectures "$app"
spctl --assess --type execute --verbose=4 "$app"
xattr -l "$app"
```

本次 1.8.3 的签名和 Gatekeeper 检查通过。若进程未运行，可按实际安装路径后台启动：

```sh
open -g "$HOME/Library/Input Methods/OpenVanilla.app"
```

### 注册路径与日志

```sh
lsregister='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'
"$lsregister" -dump | rg -n -B 8 -A 12 'org\.openvanilla\.inputmethod\.OpenVanilla'

/usr/bin/log show --last 10m --style compact --info \
    --predicate '(process == "OpenVanilla" OR process == "imklaunchagent" OR process == "TextInputMenuAgent") AND (eventMessage CONTAINS[c] "OpenVanilla" OR eventMessage CONTAINS[c] "Activate Server" OR eventMessage CONTAINS[c] "Refusing connection")'
```

本次发现过旧修复目录中多个同 bundle ID 的应用注册，最初首选 URL 也曾指向备份副本。取消旧副本注册、重新注册实际安装路径后，灰色问题仍未解除。备份副本还可能在重新登录后被再次发现，因此需要核对实际路径，不能把注册命令返回成功当作修复完成。

日志中的 `Refusing connection name` 或 `Endpoint Invalid` 要结合时间、客户端 PID 和实际输入行为分析；部分记录可以由命令行探针触发。仅凭动态 IMK 端点名称与 `InputMethodConnectionName` 字符串不同，不能认定应用配置错误并修改已签名的应用包。

## 本次未能恢复的操作

| 操作 | 本次结果 |
| --- | --- |
| 仅重启 OpenVanilla | 仍灰色 |
| 清理旧备份副本注册并注册当前应用 | 仍灰色 |
| 重启输入法连接服务及输入菜单相关进程 | 仍灰色 |
| 锁屏解锁 | 仍灰色 |
| 注销重新登录 | 仍灰色 |
| 在文本编辑中新建文档测试 | 同样复现，排除仅限某个输入框的解释 |
| 正常完全退出 Firefox | 安全输入仍开启，菜单仍禁用 OpenVanilla |

后续遇到相同症状，优先采集状态和做有范围的退出对照，避免反复重启服务、注销或重建配置。

## 容易误判的信号

- **`select_capable=true` 是静态能力标记。** 本机 Apple SDK 的 `TextInputSources.h` 明确说明该属性不依赖当前状态；它不能证明当前文稿或菜单允许使用此输入法。
- **`TISSelectInputSource` 返回 `0` 只说明该 API 调用成功。** 本次出现过命令行显示选中、用户菜单仍灰色且无候选字的情况。
- **安全输入 PID 只能作为线索。** `IOConsoleUsers/kCGSSessionSecureInputPID` 或会话字典可能指向前台应用或过时进程。本次曾先后指向不同应用；已有公开的[后台调用导致 PID 误报记录](https://github.com/lionheart/openradar-mirror/issues/21098)。通过正常退出后的状态变化确认关联。
- **新建 `InputSource` 对象的标志不代表现存菜单。** 本次新对象显示 `isDisabled=false`、`isAvailable=true`，实际菜单却已禁用 OpenVanilla；应读取菜单进程的实际结果。
- **进程存在不等于已接收输入法会话。** 本次 OpenVanilla 主线程正常等待事件，未发现词库解析卡死；最终恢复仍以候选字出现为准。
- **保护密码框的正常安全输入不应被强行绕过。** 通过持有应用正常释放状态，不运行旧的 `reset_secure_input` 或针对其他连接强制关闭安全输入的私有工具。

## KeePassXC 后续观察

本次已验证的恢复动作是正常退出 KeePassXC。未来复发时，可先在保存修改后采用这一方法。

KeePassXC 上游有[登录后错误开启安全输入的报告](https://github.com/keepassxreboot/keepassxc/issues/12505)，涉及非主桌面和错误焦点事件；该报告的版本、环境与本次不同，不能直接当作本次内部缺陷的定论。报告中的聚焦后再失焦办法尚未在本次环境验证。已有的[安全输入计数及隐藏控件修复](https://github.com/keepassxreboot/keepassxc/pull/11928)也不能证明本次异常已被覆盖。

后续需要继续定位触发条件时，分别观察重新启动 KeePassXC、显示或隐藏密码输入窗口、切换焦点前后的安全输入状态及菜单列表；每次只改变一个条件，并保留实际候选字验收结果。

