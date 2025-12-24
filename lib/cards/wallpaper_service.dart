// Stub file that exports the correct implementation based on platform
export 'wallpaper_service_stub.dart'
    if (dart.library.io) 'wallpaper_service_mobile.dart';
