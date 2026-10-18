module dulib.types.box;

import dt = dulib.types;

class Box(B, ulong MIN_SIZE = 0, dt.Mutability M = dt.Mut) {
  static assert (sizeof(t) >= MIN_SIZE);
  dt.AsMut!(B, M).Out boxed;

  this(B b) {
    this.boxed = b;
  }
}
