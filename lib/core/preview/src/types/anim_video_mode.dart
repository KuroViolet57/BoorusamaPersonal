enum AnimVideoMode {
  off,
  animated,
  video;

  AnimVideoMode get next => switch (this) {
    AnimVideoMode.off => AnimVideoMode.animated,
    AnimVideoMode.animated => AnimVideoMode.video,
    AnimVideoMode.video => AnimVideoMode.off,
  };

  String? get extraTag => switch (this) {
    AnimVideoMode.off => null,
    AnimVideoMode.animated => 'animated',
    AnimVideoMode.video => 'video',
  };
}
