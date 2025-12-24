import 'package:flutter/widgets.dart';

class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double widescreen = 1800;
}

enum DeviceType { mobile, tablet, desktop, widescreen }

DeviceType getDeviceType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < Breakpoints.mobile) return DeviceType.mobile;
  if (width < Breakpoints.tablet) return DeviceType.tablet;
  if (width < Breakpoints.desktop) return DeviceType.desktop;
  return DeviceType.widescreen;
}

int getGridColumns(BuildContext context) {
  switch (getDeviceType(context)) {
    case DeviceType.mobile:
      return 2;
    case DeviceType.tablet:
      return 3;
    case DeviceType.desktop:
      return 4;
    case DeviceType.widescreen:
      return 5;
  }
}

double getGridSpacing(BuildContext context) {
  switch (getDeviceType(context)) {
    case DeviceType.mobile:
      return 8;
    case DeviceType.tablet:
      return 12;
    case DeviceType.desktop:
      return 16;
    case DeviceType.widescreen:
      return 20;
  }
}
