class PitchRingBuffer {
  final int capacity;
  late final List<double> _buffer;
  int _writeIndex = 0;
  int _size = 0;

  PitchRingBuffer(this.capacity) {
    _buffer = List<double>.filled(capacity, 0.0);
  }

  void add(double value) {
    _buffer[_writeIndex] = value;
    _writeIndex = (_writeIndex + 1) % capacity;
    if (_size < capacity) {
      _size++;
    }
  }

  void clear() {
    _writeIndex = 0;
    _size = 0;
  }

  int get length => _size;
  bool get isEmpty => _size == 0;
  bool get isFull => _size == capacity;

  List<double> toList() {
    final list = <double>[];
    int readIndex = _size < capacity ? 0 : _writeIndex;
    for (int i = 0; i < _size; i++) {
      list.add(_buffer[readIndex]);
      readIndex = (readIndex + 1) % capacity;
    }
    return list;
  }
}
