class AppConfig {
  static const cloudinaryCloudName = 'q3e5xemu';
  static const cloudinaryUploadPreset = 'decorra_unsigned';

  static bool get cloudinaryConfigured =>
      cloudinaryCloudName != 'YOUR_CLOUD_NAME' &&
      cloudinaryUploadPreset != 'YOUR_UNSIGNED_PRESET';
}