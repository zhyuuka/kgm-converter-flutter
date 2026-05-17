<div align="center">

# KGM Converter

**酷狗音乐 KGM/VPR 加密音频解密转换工具**

A Flutter-based Android app for decrypting and converting KuGou encrypted audio files (`.kgm` / `.vpr`) to standard formats.

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?style=flat-square&logo=android)](https://android.com)
[![License](https://img.shields.io/badge/License-Personal%20Use-blue?style=flat-square)](LICENSE)

</div>

---

## 🇨🇳 中文说明

### 简介

KGM Converter 是一款 Android 应用，用于将酷狗音乐下载的加密音频文件（`.kgm` / `.vpr`）解密并转换为 FLAC、WAV、MP3、AAC、OGG 等标准音频格式。

解密算法基于社区逆向工程成果，采用 **nibble（半字节）级 XOR + 动态掩码查表** 方式还原原始音频数据，再通过内嵌的 FFmpeg 进行格式转换。

### 功能特性

| 功能 | 说明 |
|---|---|
| 解密 KGM/VPR 文件 | 支持 KGM v1（`7C D5 32 EB`）和 VPR（`05 28 BC 96`）两种文件头 |
| 多格式输出 | FLAC（无损压缩）、WAV（无损未压缩）、MP3（320kbps）、AAC（256kbps）、OGG（Vorbis q8） |
| 批量处理 | 支持同时选择多个文件，并行或顺序转换 |
| 自定义文件名 | 转换前可自定义输出文件名 |
| 自定义输出目录 | 可选择保存位置，默认保存到应用内部存储 |
| 内置音频预览 | 转换完成后可直接在应用内播放 |
| 外部播放器打开 | 一键调用系统播放器打开转换后的文件 |
| 中英双语 | 运行时切换中文/英文界面 |
| Material 3 设计 | Teal 配色方案，支持深色模式 |

### 使用方法

1. **添加文件** — 点击 `+` 按钮选择设备中的 `.kgm` 文件
2. **选择格式** — 选择输出格式（FLAC / WAV / MP3 / AAC / OGG）
3. **自定义名称**（可选）— 在文本框中输入自定义输出文件名
4. **设置输出目录**（可选）— 点击输出目录栏更改保存位置
5. **开始转换** — 点击「开始转换」按钮
6. **预览** — 点击播放按钮试听，或点击打开按钮用外部播放器播放

> **并行/顺序模式**：默认并行处理所有文件；长按「开始转换」按钮可切换为顺序模式（逐个处理，内存占用更低）。

### 解密算法

KGM 加密在 **半字节（nibble）级别** 操作，并非简单的字节 XOR：

```
对音频数据中的每个字节 i：
  1. key_byte = 嵌入密钥[i % 17]           // 密钥在文件头偏移 0x1C 处
  2. med8 = key_byte ^ 加密字节[i]
  3. med8 ^= (med8 & 0x0F) << 4            // 半字节交换
  4. mask = getMask(i)                      // 通过 Table1/Table2/MaskV2PreDef 查表
  5. mask ^= (mask & 0x0F) << 4            // 半字节交换
  6. decrypted[i] = med8 ^ mask
  7. 若为 VPR 格式：decrypted[i] ^= VprMaskDiff[i % 17]
```

`getMask()` 函数使用三个 272 字节查找表（`Table1`、`Table2`、`MaskV2PreDef`）通过迭代偏移归约计算位置相关的掩码。

### 构建与安装

**环境要求**：Flutter SDK >= 3.11、Android SDK（minSdk 21）、JDK 17+

```bash
# 获取依赖
flutter pub get

# 构建 Release APK（约 120 MB，内含 FFmpeg 原生库）
flutter build apk --release

# 安装到设备
adb install build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ **重要**：修改代码后务必完全重装 APK（`flutter run` 或 `adb install`），不要依赖 Hot Reload。原生插件（FilePicker、FFmpegKit 等）在 Hot Reload 后会抛出 `MissingPluginException`。

### 项目结构

```
lib/
├── main.dart                              # 应用入口，Material 3 主题
├── l10n/
│   └── strings.dart                       # 中英双语 i18n
├── models/
│   └── conversion_task.dart               # 任务模型，输出格式枚举
├── services/
│   ├── kgm_decryptor.dart                 # KGM/VPR 解密核心
│   ├── audio_converter.dart               # FFmpegKit 编码封装
│   └── conversion_service.dart            # 解密 + 转换编排
├── screens/
│   └── home_screen.dart                   # 主界面，文件选择，设置
└── widgets/
    ├── conversion_progress_widget.dart     # 任务卡片（进度/预览）
    └── format_selector.dart               # 输出格式选择器
```

### 技术说明

- 解密后的输出**已经是完整的音频文件**（通常为 FLAC 或 MP3），而非裸 PCM 数据。FFmpeg 用于格式转换，而非解码。
- 17 字节加密密钥嵌入在 KGM 文件头偏移 `0x1C` 处。
- 头部长度以 little-endian uint32 存储在偏移 `0x10`。
- 音频数据从头部之后开始（偏移 = 头部长度）。
- `MaskV2PreDef` 表（272 字节）和两个计算表（`Table1`、`Table2`）是从酷狗客户端提取的硬编码常量。

### 算法参考

- [孤心浪子 - 闲来无事研究一下酷狗缓存文件kgtemp的加密方式](https://www.cnblogs.com/KMBlog/p/6877752.html)
- [ghtz08/kugou-kgm-decoder](https://github.com/ghtz08/kugou-kgm-decoder)（Rust 参考实现）
- [bluegitter/kgm-decrypt](https://github.com/bluegitter/kgm-decrypt)（Go 参考实现）
- [ix64/unlock-music](https://github.com/ix64/unlock-music)（JavaScript 参考实现）

---

## 🇬🇧 English

### Overview

KGM Converter is an Android application that decrypts KuGou Music's encrypted audio files (`.kgm` / `.vpr`) and converts them to standard formats like FLAC, WAV, MP3, AAC, and OGG.

The decryption algorithm is based on community reverse-engineering efforts, using **nibble-level XOR with dynamic mask lookup tables** to restore the original audio data, followed by format conversion via the embedded FFmpeg.

### Features

| Feature | Description |
|---|---|
| Decrypt KGM/VPR files | Supports both KGM v1 (`7C D5 32 EB`) and VPR (`05 28 BC 96`) magic headers |
| Multiple output formats | FLAC (lossless), WAV (lossless uncompressed), MP3 (320kbps), AAC (256kbps), OGG (Vorbis q8) |
| Batch processing | Select multiple files at once, with parallel or sequential conversion |
| Custom filename | Rename output files before conversion |
| Custom output directory | Choose where converted files are saved |
| Built-in audio preview | Play converted files directly in-app |
| Open with external app | Launch system audio player for converted files |
| Bilingual UI | Chinese / English toggle, switchable at runtime |
| Material 3 design | Teal color scheme, dark mode support |

### Usage

1. **Add files** — Tap the `+` button to select `.kgm` files from your device
2. **Choose format** — Select output format (FLAC / WAV / MP3 / AAC / OGG)
3. **Customize name** (optional) — Enter a custom output name in the text field
4. **Set output folder** (optional) — Tap the output folder bar to change save location
5. **Start conversion** — Tap the convert button
6. **Preview** — Tap play to listen, or tap open to launch in an external player

> **Parallel / Sequential mode**: Default is parallel processing; long-press the convert button to toggle sequential mode (one at a time, lower memory usage).

### Decryption Algorithm

KGM encryption operates at the **nibble (4-bit) level**, not simple byte XOR:

```
For each byte i in the audio data:
  1. key_byte = embedded_key[i % 17]           // Key at file offset 0x1C
  2. med8 = key_byte ^ encrypted_byte[i]
  3. med8 ^= (med8 & 0x0F) << 4               // Nibble swap
  4. mask = getMask(i)                         // Lookup from Table1/Table2/MaskV2PreDef
  5. mask ^= (mask & 0x0F) << 4               // Nibble swap
  6. decrypted[i] = med8 ^ mask
  7. If VPR format: decrypted[i] ^= VprMaskDiff[i % 17]
```

The `getMask()` function computes a position-dependent mask using three 272-byte lookup tables (`Table1`, `Table2`, `MaskV2PreDef`) with iterative offset reduction.

### Build & Install

**Prerequisites**: Flutter SDK >= 3.11, Android SDK (minSdk 21), JDK 17+

```bash
# Get dependencies
flutter pub get

# Build Release APK (~120 MB, includes FFmpeg native libraries)
flutter build apk --release

# Install on device
adb install build/app/outputs/flutter-apk/app-release.apk
```

> ⚠️ **Important**: After code changes, always do a full reinstall (`flutter run` or `adb install`) instead of Hot Reload. Native plugins (FilePicker, FFmpegKit, etc.) will throw `MissingPluginException` after Hot Reload.

### Project Structure

```
lib/
├── main.dart                              # App entry, Material 3 theme
├── l10n/
│   └── strings.dart                       # Bilingual i18n (zh/en)
├── models/
│   └── conversion_task.dart               # Task model, OutputFormat enum
├── services/
│   ├── kgm_decryptor.dart                 # KGM/VPR decryption core
│   ├── audio_converter.dart               # FFmpegKit encoding wrapper
│   └── conversion_service.dart            # Orchestrates decrypt + convert
├── screens/
│   └── home_screen.dart                   # Main UI, file picking, settings
└── widgets/
    ├── conversion_progress_widget.dart     # Task card with progress/preview
    └── format_selector.dart               # Output format selector
```

### Technical Notes

- The decrypted output is **already a valid audio file** (typically FLAC or MP3), not raw PCM. FFmpeg is used for format conversion, not decoding.
- The 17-byte encryption key is embedded in the KGM file header at offset `0x1C`.
- The header length is stored as a little-endian uint32 at offset `0x10`.
- Audio data starts immediately after the header (offset = header length).
- The `MaskV2PreDef` table (272 bytes) and two computation tables (`Table1`, `Table2`) are hardcoded constants derived from the original KuGou client.

### Algorithm References

- [孤心浪子 - KGM encryption analysis (Chinese)](https://www.cnblogs.com/KMBlog/p/6877752.html)
- [ghtz08/kugou-kgm-decoder](https://github.com/ghtz08/kugou-kgm-decoder) (Rust reference)
- [bluegitter/kgm-decrypt](https://github.com/bluegitter/kgm-decrypt) (Go reference)
- [ix64/unlock-music](https://github.com/ix64/unlock-music) (JavaScript reference)

---

## Dependencies

| Package | Purpose |
|---|---|
| `file_picker` | System file/directory selection |
| `ffmpeg_kit_flutter_new_audio` | Built-in FFmpeg with audio codecs |
| `audioplayers` | In-app audio playback |
| `open_filex` | Open files with system default app |
| `path_provider` | Default output directory resolution |
| `permission_handler` | Android storage permissions |

## Supported Formats

| Input | Magic Bytes | Description |
|---|---|---|
| `.kgm` | `7C D5 32 EB 86 02 7F 4B ...` | KuGou encrypted audio (common) |
| `.vpr` | `05 28 BC 96 E9 E4 5A 43 ...` | KuGou encrypted audio (variant) |

| Output | Codec | Bitrate/Quality |
|---|---|---|
| FLAC | FLAC | Lossless, compression level 8 |
| WAV | PCM s16le | Lossless, uncompressed |
| MP3 | libmp3lame | 320 kbps CBR |
| AAC | AAC | 256 kbps |
| OGG | libvorbis | Quality 8 (~256 kbps VBR) |

## License

This project is for **educational and personal use only**. Please respect copyright laws in your jurisdiction.

The decryption algorithm is based on publicly documented reverse-engineering efforts by the community. This project is **not affiliated with or endorsed by** KuGou (酷狗音乐).
