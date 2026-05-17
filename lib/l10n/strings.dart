class S {
  static const _zh = <String, String>{
    'appName': 'KGM 转换器',
    'appSubtitle': '解密并转换加密音频文件',
    'noFiles': '暂无文件',
    'noFilesHint': '点击 + 按钮选择 .kgm 文件',
    'outputFormat': '输出格式',
    'outputFolder': '输出目录',
    'outputFolderDefault': '默认 (Documents/kgm_output)',
    'startConvert': '开始转换',
    'converting': '转换中...',
    'clearDone': '清除已完成/失败项',
    'waiting': '等待中',
    'decrypting': '解密中',
    'encoding': '编码中',
    'done': '已完成',
    'failed': '失败',
    'play': '播放',
    'pause': '暂停',
    'open': '打开',
    'customName': '自定义输出名称（可选）',
    'customNameHint': '留空则使用原文件名',
    'noKgmFiles': '所选文件中没有 .kgm 文件',
    'permissionDenied': '存储权限被拒绝，请在设置中授权',
    'parallelMode': '并行处理',
    'sequentialMode': '顺序处理',
  };

  static const _en = <String, String>{
    'appName': 'KGM Converter',
    'appSubtitle': 'Decrypt & convert encrypted audio files',
    'noFiles': 'No files added yet',
    'noFilesHint': 'Tap the + button to select .kgm files',
    'outputFormat': 'Output Format',
    'outputFolder': 'Output Folder',
    'outputFolderDefault': 'Default (Documents/kgm_output)',
    'startConvert': 'Start Convert',
    'converting': 'Converting...',
    'clearDone': 'Clear done/failed',
    'waiting': 'Waiting',
    'decrypting': 'Decrypting',
    'encoding': 'Encoding',
    'done': 'Done',
    'failed': 'Failed',
    'play': 'Play',
    'pause': 'Pause',
    'open': 'Open',
    'customName': 'Custom output name (optional)',
    'customNameHint': 'Leave empty to use original filename',
    'noKgmFiles': 'No .kgm files found in selection',
    'permissionDenied': 'Storage permission denied',
    'parallelMode': 'Parallel processing',
    'sequentialMode': 'Sequential processing',
  };

  static String _locale = 'zh';

  static void setLocale(String locale) {
    _locale = locale.startsWith('zh') ? 'zh' : 'en';
  }

  static String get locale => _locale;

  static String of(String key) {
    final map = _locale == 'zh' ? _zh : _en;
    return map[key] ?? key;
  }
}
