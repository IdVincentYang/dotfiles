# Termux + Ubuntu proot Android SDK/NDK

在 Termux 编辑项目，由 Ubuntu proot 提供 Linux ARM64 Android 构建工具。

## Termux 安装与准备

- 按 [Termux 官方安装说明][termux-install] 从 F-Droid 或官方 GitHub
  Releases 安装。Termux 与插件应用必须来自同一安装来源，不能混装。
- 首次打开 Termux 后更新基础包并安装本指南需要的 proot-distro：

  ```sh
  # 更新 Termux 软件包索引并升级已安装的软件包。
  pkg update && pkg upgrade
  # 安装用于管理 Ubuntu 环境的 proot-distro。
  pkg install proot-distro
  # 安装 Ubuntu 环境。
  proot-distro install ubuntu
  ```

- 本指南不需要额外的 Termux 插件应用。使用 Android 系统 API 时，需安装
  [Termux:API][termux-api]，并在 Termux 中运行：

  ```sh
  # 安装 Termux:API 对应的命令行软件包。
  pkg install termux-api
  ```

  使用桌面快捷脚本时，才需要 [Termux:Widget][termux-widget]。

## Ubuntu 路径变量

- 安装 Ubuntu 后，登录 Ubuntu proot，并在同一个 shell 会话中设置路径。以下是示例，
  可按实际目录修改；后续 Ubuntu 命令直接使用这些变量：

  ```sh
  # 设置 Android SDK 的安装目录。
  export SDK_ROOT="$HOME/android/sdk"
  # 设置下载包和临时组装文件的专用目录。
  export WORK_DIR="$HOME/tmp/android-sdk-work"
  ```

## 1. 准备 Ubuntu 与官方命令行工具

- 在 Ubuntu 安装基础工具和 ARM64 构建工具：

  ```sh
  # 安装 Java、归档和网络工具，以及 SDK 组装所需的 ARM64 工具。
  apt install \
    openjdk-21-jdk \
    curl \
    unzip \
    tar \
    xz-utils \
    file \
    git \
    cmake \
    ninja-build \
    lldb \
    clangd \
    glslc
  ```

- 使用 Ubuntu 安装的 CMake 版本，不固定版本号；记录其实际版本供后续路径设置使用：

  ```sh
  # 读取当前 Ubuntu 系统中 CMake 的实际版本。
  export CMAKE_VERSION="$(
    cmake --version | sed -n '1s/.*version //p'
  )"
  ```

- 从 [Android 官方命令行工具页面][android-cli-tools] 下载 Linux
  Command-line Tools，解压至 `$SDK_ROOT/cmdline-tools/latest/`。

## 2. 评估项目需求并选择可用版本

- 项目配置给出的是需求和兼容约束，不代表所有版本都有 Linux ARM64 工具包。
  只有项目所需组件能找到 ARM64 版本且彼此兼容时，本指南的组装流程才适用。
- 先梳理项目的版本要求，再逐项核对 ARM64 组件的可用版本：
  - AGP 版本查看 `settings.gradle(.kts)`、顶层 `build.gradle(.kts)` 或
    `gradle/libs.versions.toml`；SDK 与 native 配置查看 Android 模块的
    `build.gradle(.kts)`。
  - `compileSdk` 决定 `ANDROID_API`；不要用 `targetSdk` 代替。
  - 项目若设置了 `buildToolsVersion`，使用该值；否则查对应 AGP 文档中的
    Build Tools 默认/要求版本。
  - 原生项目查看模块的 `ndkVersion`；未设置时查 AGP 对应的默认 NDK 版本。
    优先找相同版本的 Linux AArch64 发布包；若没有，不要直接换版本，先确认
    项目、AGP 和 native 依赖允许使用哪个可用版本，再修改配置并验证构建。
  - CMake 项目查看 `externalNativeBuild.cmake.version`，Ubuntu 的 ARM64 CMake
    版本需满足项目要求；若项目允许多个版本，可从可用版本中选择兼容版本。
- 项目依赖的预编译原生库也必须包含目标 Android ABI（例如 `arm64-v8a`）。
  若缺少兼容的 ARM64 工具或原生依赖，单纯组装 SDK 无法解决，需移植/重编依赖，
  或改用满足项目约束的其他构建环境。
- 查版本和下载文件：
  - Android API、AGP 与 Build Tools 的兼容要求：
    [Android Gradle Plugin 文档][agp-docs]。
  - ARM64 SDK 组件的版本、发布包和安装要求：
    [zhuwanhong/android-sdk-linux-arm64 Releases][arm64-sdk-releases] 及其
    [版本说明][arm64-sdk-versions]。
  - NDK 版本与项目配置方式：
    [Android NDK 配置文档][ndk-config]；AArch64 安装包从
    [lzhiyong/termux-ndk Releases][termux-ndk-releases] 选择。
- SDK release tag、ARM64 SDK 发布包名称/链接、NDK 版本和发布包名称/链接，均从
  对应发布页取得；SDK tag 与 Build Tools 版本不是同一个版本号。
- SHA-256 是单个发布文件的完整性校验值，不表示 SDK/NDK 兼容性。使用发布者
  提供或公布的校验值；本地 `sha256sum` 的输出需与之比较，单独计算不能验证
  文件来源。
- **CMake / Ninja 等：** 使用 Ubuntu ARM64 软件包；组装脚本会将其接入 SDK。

- 以下变量默认采用本指南已验证过的组合：Android API 36、Build Tools 37.0.0、
  NDK 29.0.14206865，以及 ARM64 SDK release v1.0.0。
  其他项目先按项目约束评估；若改选版本，同时更新相应的包名和下载链接。

  ```sh
  # 设置已验证的默认版本；按目标项目需要调整。
  export ANDROID_API=36
  export BUILD_TOOLS_VERSION=37.0.0
  export NDK_VERSION=29.0.14206865
  # 使用已验证的 ARM64 SDK release 及其发布包。
  export ARM64_SDK_RELEASE_TAG=v1.0.0
  export ARM64_SDK_ARCHIVE=android-sdk-linux-arm64-36.0.0-ours.tar.gz
  export ARM64_SDK_ASSET_URL="$(
    printf '%s' \
      'https://github.com/zhuwanhong/' \
      'android-sdk-linux-arm64/releases/download/v1.0.0/' \
      'android-sdk-linux-arm64-36.0.0-ours.tar.gz'
  )"
  # 使用提供 NDK 29 ARM64 构建的发布包。
  export NDK_ARCHIVE=android-ndk-r29-aarch64.tar.xz
  export NDK_ASSET_URL="$(
    printf '%s' \
      'https://github.com/lzhiyong/' \
      'termux-ndk/releases/download/android-ndk/' \
      'android-ndk-r29-aarch64.tar.xz'
  )"
  ```

## 3. 组装 Linux ARM64 Android SDK

- 根据上一节选定并核验过的版本，下载 ARM64 组件：

  ```sh
  # 创建下载和临时转换文件的工作目录。
  mkdir -p "$WORK_DIR"
  # 检出与所选 ARM64 SDK 发布标签匹配的组装脚本。
  git clone \
    --depth 1 \
    --branch "$ARM64_SDK_RELEASE_TAG" \
    https://github.com/zhuwanhong/android-sdk-linux-arm64 \
    "$WORK_DIR/android-sdk-linux-arm64"
  # 下载所选发布包中的 ARM64 SDK 组件。
  curl \
    -fL \
    --retry 8 \
    --retry-all-errors \
    --continue-at - \
    -o "$WORK_DIR/$ARM64_SDK_ARCHIVE" \
    "$ARM64_SDK_ASSET_URL"
  # 下载与项目 ndkVersion 匹配的 AArch64 NDK 压缩包。
  curl \
    -fL \
    --retry 8 \
    --retry-all-errors \
    --continue-at - \
    -o "$WORK_DIR/$NDK_ARCHIVE" \
    "$NDK_ASSET_URL"
  # 计算本地校验值，并与发布者公布的校验值比较。
  sha256sum \
    "$WORK_DIR/$ARM64_SDK_ARCHIVE" \
    "$WORK_DIR/$NDK_ARCHIVE"
  ```

- 若选中的 NDK 发布包为 `.tar.xz`，将其目录整理成 SDK 组装脚本需要的结构。
  `NDK_ARCHIVE_ROOT` 是压缩包解出的顶层目录名。转换后会得到
  `ndk/$NDK_VERSION/`，这是 SDK 组装脚本预期的 NDK 目录结构；文件内容不变。
  `tar -xJf` 解开 xz 压缩的 tar 包；若使用 `--transform`，它会在解包时重命名
  包内路径。这里改用 `mv` 明确整理目录，再重新打包成组装脚本接受的格式。

  ```sh
  # 创建用于解压 NDK 压缩包的临时目录。
  mkdir -p "$WORK_DIR/ndk"
  # 从压缩包目录列表读取顶层目录名，供后续整理目录使用。
  NDK_ARCHIVE_ROOT="$(
    tar -tf "$WORK_DIR/$NDK_ARCHIVE" |
      awk -F/ 'NF { print $1; exit }'
  )"
  printf 'NDK archive root: %s\n' "$NDK_ARCHIVE_ROOT"
  # 解开 .tar.xz 压缩包；tar -xJf 表示解包并通过 xz 解压。
  tar \
    -xJf "$WORK_DIR/$NDK_ARCHIVE" \
    -C "$WORK_DIR/ndk"
  # 创建 Android SDK 标准的 NDK 模块目录。
  mkdir -p "$WORK_DIR/ndk/ndk"
  # 将解出的 NDK 放入按版本号命名的目录。
  mv \
    "$WORK_DIR/ndk/$NDK_ARCHIVE_ROOT" \
    "$WORK_DIR/ndk/ndk/$NDK_VERSION"
  # 将整理后的 ndk/ 目录重新打包成组装脚本接受的格式。
  tar \
    -I 'gzip -1' \
    -cf "$WORK_DIR/android-ndk-aarch64.tar.gz" \
    -C "$WORK_DIR/ndk" \
    ndk
  ```

- 用匹配的 SDK 组装脚本安装组件。它会下载指定 Android Platform、组装 ARM64
  Build Tools / Platform Tools 和 NDK、接入 Ubuntu 系统工具，并配置 Gradle：

  ```sh
  # 安装所选 Android Platform、ARM64 SDK 组件和 NDK。
  "$WORK_DIR/android-sdk-linux-arm64/tools/install.sh" \
    --sdk-root "$SDK_ROOT" \
    --sdk-tgz "$WORK_DIR/$ARM64_SDK_ARCHIVE" \
    --ndk-tgz "$WORK_DIR/android-ndk-aarch64.tar.gz" \
    --build-tools "$BUILD_TOOLS_VERSION" \
    --platform "$ANDROID_API" \
    --yes
  ```

- 项目的 `local.properties` 中，`sdk.dir` 写为 `$SDK_ROOT` 当前展开后的绝对路径；
  若需指定 CMake，`cmake.dir` 写为 `$SDK_ROOT/cmake/$CMAKE_VERSION` 当前展开后的
  绝对路径。不要将 `$...` 变量表达式原样写入文件，也不要提交这些本机路径。
- 保留标准 Android SDK 目录结构，使所有项目都能共用这套 SDK。
- `$WORK_DIR` 中留下的是下载包、解压内容和组装脚本，不参与后续构建。建议先完成
  一次项目构建验证；之后若不需要重复组装，可核对路径并删除专用工作目录释放空间。
  需要保留安装包以便重试时，就保留该目录；勿将 `$SDK_ROOT` 当作工作目录删除。

  ```sh
  # 删除前确认这里显示的是本指南专用的工作目录路径。
  printf '%s\n' "$WORK_DIR"
  # 确认路径无误且不再需要其中的文件后，删除工作目录。
  rm -r -- "$WORK_DIR"
  ```

## 4. 构建 Android 应用并安装 APK

- 在 Termux shell 设置项目路径变量，并调用 Ubuntu proot 中的 Gradle Wrapper，构建
  Android 应用的 Debug APK：

  ```sh
  # 设置 Termux home 和项目相对路径；按实际项目目录修改。
  export TERMUX_HOME="$HOME"
  export PROJECT_DIR="AndroidProjects/MyApp"
  # 在 Ubuntu 中使用 Termux home 下的项目源码执行构建。
  proot-distro login ubuntu -- \
    bash -c "cd \"$TERMUX_HOME/$PROJECT_DIR\" && ./gradlew assembleDebug"
  ```

- 构建成功后，APK 位于项目目录下的
  `app/build/outputs/apk/debug/app-debug.apk`。

- 安装 APK 前设置：

  1. Android 系统允许 Termux“安装未知应用”。
  2. 在 Termux 的 `~/.termux/termux.properties` 中设置
     `allow-external-apps = true`，然后运行：

     ```sh
     # 应用刚修改的 Termux 设置。
     termux-reload-settings
     ```

- 在 Termux 中把构建出的 APK 交给 Android 系统安装器；在手机界面确认安装：

  ```sh
  # 调用 Android 安装器打开构建好的 APK。
  termux-open "$TERMUX_HOME/$PROJECT_DIR/app/build/outputs/apk/debug/app-debug.apk"
  ```

- 用包含 JNI/C++ 的 Android 项目验证：APK 构建成功、包含设备目标 ABI 的
  `.so`，并能在 Android 上安装和运行。

[termux-install]: https://github.com/termux/termux-app#installation
[termux-api]: https://github.com/termux/termux-api
[termux-widget]: https://github.com/termux/termux-widget
[android-cli-tools]: https://developer.android.com/studio#command-line-tools-only
[agp-docs]: https://developer.android.com/build/releases/about-agp
[arm64-sdk-releases]: https://github.com/zhuwanhong/android-sdk-linux-arm64/releases
[arm64-sdk-versions]: https://github.com/zhuwanhong/android-sdk-linux-arm64/blob/main/docs/VERSIONS.md
[ndk-config]: https://developer.android.com/studio/projects/configure-agp-ndk
[termux-ndk-releases]: https://github.com/lzhiyong/termux-ndk/releases
