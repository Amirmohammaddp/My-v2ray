enum VpnStatus { disconnected, connecting, connected, disconnecting, error }

class TrafficStats {
  final int downBps;
  final int upBps;
  final int totalDown;
  final int totalUp;
  const TrafficStats({this.downBps = 0, this.upBps = 0, this.totalDown = 0, this.totalUp = 0});
  static const zero = TrafficStats();
}

String formatBytes(num bytes, {bool perSecond = false}) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${units[i]}${perSecond ? '/s' : ''}';
}
