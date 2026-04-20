import 'dart:async';

class NotificationEvents {
  static final _controller = StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  static void emit(String event) {
    _controller.add(event);
  }
}