import 'dart:async';

class Ticker {
  final void Function(Duration) onTick;
  Timer? _timer;
  final Duration _elapsed = Duration.zero;

  Ticker(this.onTick);

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      onTick(Duration(seconds: timer.tick));
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _timer?.cancel();
  }
}
