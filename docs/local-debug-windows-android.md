# Windows 本机调试指南（Android 模拟器）

> 基于本机实际踩坑整理（Echo Loop）。目标：在 **Windows + Android x86_64 模拟器** 上跑通调试。  
> 最后更新：2026-09-30

## 0. 先记住几条结论

| 平台 | 能否完整调试听说主链路 | 说明 |
|------|------------------------|------|
| **Android 模拟器 / 真机** | 可以 | 主音频走 `just_audio`，有原生实现 |
| **Windows 桌面** | UI 可看，播放易失败 | `just_audio` 无 Windows 原生插件 → `MissingPluginException` |
| **Chrome / Web** | 不可用 | `dart:ffi`（sqlite3 / media_kit / sherpa 等）不支持 Web |

日常请优先：

```powershell
flutter run -d <android设备id> --dart-define-from-file=.dev.env --flavor=dev
```

---

## 1. 环境准备

### 1.1 仓库与环境变量

```powershell
cd E:\open_source\flutter\Echo-Loop

# 若还没有 .dev.env
copy .dev.env.template .dev.env
# 编辑 .dev.env，至少确认：
#   API_BASE_URL=https://dev.echo-loop.top
```

> 不加 `--dart-define-from-file=.dev.env` 时，`API_BASE_URL` 会回退到默认 `http://localhost:3000`，远程配置 / catalog 会失败。

### 1.2 Flutter 版本（建议）

- 仓库 CI 锁定：**Flutter 3.41.5**
- 本机全局若是更新的 stable（如 3.47.x），**日常 `flutter run` 多半能跑**；但 `dart run build_runner` 可能因 `analyzer` 过旧报 `visitDotShorthandPropertyAccess`。

可选：用 FVM 对齐 CI：

```powershell
dart pub global activate fvm
# 确保 %LOCALAPPDATA%\Pub\Cache\bin 在 PATH

fvm install 3.41.5
fvm use 3.41.5

# 之后把下面命令里的 flutter / dart 换成：
fvm flutter ...
fvm dart ...
```

### 1.3 JDK（必做）

Android Studio 自带 JBR 可能是 **JDK 25**，构建会神秘失败（错误信息只显示 `25.0.2`）。请固定 **JDK 17**：

```powershell
flutter config --jdk-dir=D:\Programs\jdk-17.0.11
flutter config --list
# 应看到：jdk-dir: D:\Programs\jdk-17.0.11
```

用户级 Gradle（可选，直接跑 `gradlew` 时有用）  
编辑 `%USERPROFILE%\.gradle\gradle.properties`：

```properties
org.gradle.java.home=D:\\Programs\\jdk-17.0.11
```

### 1.4 Android SDK / NDK

确认环境变量：`ANDROID_HOME=D:\androidsdk`（按本机路径）。

本项目 `ndkVersion = flutter.ndkVersion`，需要完整的 NDK（目录内必须有 `source.properties`）。若半成品安装失败：

```powershell
Remove-Item -Recurse -Force "$env:ANDROID_HOME\ndk\28.2.13676358" -ErrorAction SilentlyContinue
& "$env:ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" "ndk;28.2.13676358"
```

装完检查：

```powershell
Get-Content "$env:ANDROID_HOME\ndk\28.2.13676358\source.properties"
```

### 1.5 NuGet（仅 Windows 桌面编译需要）

Windows 编译 `flutter_tts` / `flutter_inappwebview` 需要 `nuget.exe`：

```powershell
winget install Microsoft.NuGet --source winget
# 新开终端
nuget help
```

---

## 2. 模拟器

### 2.1 创建（Android Studio Device Manager）

本机示例：`Pixel_10_Pro_XL`（Virtual，API 37.x）。**首次冷启动可能很慢（数分钟）**，属正常。

### 2.2 日常启动（可不打开 Android Studio）

```powershell
flutter emulators
flutter emulators --launch Pixel_10_Pro_XL

# 等到变成 device（不是 offline）
adb devices
# emulator-5554    device

flutter devices
```

`offline` = 还在开机；`device` = 可以 `flutter run`。

### 2.3 ABI 说明（本仓库当前本机改动）

`android/app/build.gradle.kts` 若只保留 **`x86_64`**，适合本机模拟器，**不能装真机**。  
真机调试前改回 `arm64-v8a`，并去掉对 `lib/arm64-v8a/**` 的 packaging 排除。

若 APK 安装后闪退且日志含：

```text
Could not find 'libflutter.so'. Looked for: [x86_64, arm64-v8a], but only found: []
```

就是 ABI 与模拟器不匹配（只打了 arm64 却跑在 x86_64 上）。

---

## 3. 常用调试命令

### 3.1 依赖与代码生成

```powershell
cd E:\open_source\flutter\Echo-Loop
flutter pub get

# 修改 Riverpod / Drift 后需要 codegen（版本过新时可能失败，见 §1.2）
dart run build_runner build --delete-conflicting-outputs
```

### 3.2 跑到 Android 模拟器（推荐主路径）

```powershell
# 确认设备
adb devices
flutter devices

flutter run -d emulator-5554 --dart-define-from-file=.dev.env --flavor=dev
```

参数含义：

| 参数 | 作用 |
|------|------|
| `-d emulator-5554` | 指定设备（以 `flutter devices` 为准） |
| `--dart-define-from-file=.dev.env` | 注入 API / Supabase 等编译期变量 |
| `--flavor=dev` | 构建 `app.echoloop.dev`（Echo Loop Dev），与 prod 包名分离 |

本仓库有 `dev` / `prod` 两个 flavor，**Android 调试一般必须带 `--flavor=dev`**。

### 3.3 仅编译 APK（不自动 run）

```powershell
flutter build apk --debug --flavor=dev --dart-define-from-file=.dev.env
# 产物示例：build\app\outputs\flutter-apk\app-dev-debug.apk
```

### 3.4 Windows 桌面（仅看 UI / 流程，音频可能不可用）

```powershell
flutter run -d windows --dart-define-from-file=.dev.env
# 或
flutter build windows --debug --dart-define-from-file=.dev.env
```

若日志出现：

```text
MissingPluginException(... com.ryanheise.just_audio.methods)
音频文件加载失败
```

属于已知限制（Windows 无 just_audio 原生实现），请改用 Android。

### 3.5 Web（当前不可用）

```powershell
# 预期失败：dart:ffi
flutter run -d chrome --dart-define-from-file=.dev.env
flutter build web --dart-define-from-file=.dev.env
```

---

## 4. 网络与后端

### 4.1 正确 API 地址

带 `.dev.env` 启动后，日志应类似：

```text
GET https://dev.echo-loop.top/api/v1/client/config?...
GET https://dev.echo-loop.top/api/v1/catalog
```

若仍是 `http://localhost:3000/...`，说明**没注入** `.dev.env`，或本机 3000 没有后端。

`Connection closed before full header was received` → 后端不可达；**本地已导入音频的主学习链路通常仍可用**，但播客/官方目录/远程配置会失败。

### 4.2 Gradle 下载超时（国内常见）

首次 Android 构建要下载 Gradle 发行包。超时则：

- 开系统/终端代理后再试  
- 或配置 Gradle 镜像 / 手动把 zip 放进 `%USERPROFILE%\.gradle\wrapper\dists\...`

```powershell
flutter run -d emulator-5554 --dart-define-from-file=.dev.env --flavor=dev
```

---

## 5. 界面「音频异常」vs 播放失败

| 现象 | 含义 |
|------|------|
| 红标「音频异常」 | 库字段 `contentStatus = damaged`（导入时 FFmpeg 短解码判定） |
| `loadAudio` + `MissingPluginException` | 当前平台播不了（如 Windows just_audio） |
| `libflutter.so` not found | ABI 不对（模拟器 x86_64 vs 只打 arm64） |

Android 模拟器 + 正确 ABI + `.dev.env` 后，示例课音频应可正常加载播放。

---

## 6. 一键检查清单

```powershell
cd E:\open_source\flutter\Echo-Loop

flutter --version
flutter config --list          # jdk-dir 是否为 17
adb devices                    # 是否 device
flutter devices

Test-Path .dev.env
Select-String -Path .dev.env -Pattern '^API_BASE_URL'

# NDK 是否完整（版本号以 Flutter 要求为准）
Test-Path "$env:ANDROID_HOME\ndk\28.2.13676358\source.properties"
```

全部正常后再：

```powershell
flutter run -d emulator-5554 --dart-define-from-file=.dev.env --flavor=dev
```

---

## 7. 相关文件

| 文件 | 用途 |
|------|------|
| `.dev.env` / `.dev.env.template` | 编译期变量 |
| `android/app/build.gradle.kts` | flavor、ABI |
| `lib/config/api_config.dart` | `API_BASE_URL` 默认值 |
| `docs/video-support.md` | 音视频引擎演进（Windows / media_kit） |

---

## 8. 本次调试踩坑速查

1. **Gradle 只报 `25.0.2`** → Android Studio JBR 是 JDK 25，改 `flutter config --jdk-dir` 到 17。  
2. **NDK `source.properties` 缺失** → NDK 目录半成品，删掉重装。  
3. **`libflutter.so` 找不到** → ABI 与模拟器不符。  
4. **localhost:3000 连不上** → 未带 `.dev.env` 或本地无后端。  
5. **Windows 能进计划页但播不了** → just_audio 无 Windows 实现，换 Android。  
6. **必须 `--flavor=dev`** → 否则 Android 变体对不上。
