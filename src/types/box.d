module dulib.types.box;

import dt = dulib.types;

class Box(B, ulong MIN_SIZE = 0, dt.Mutability M = dt.Mut) {
  static assert (B.sizeof >= MIN_SIZE);
  dt.AsMut!(B, M).Out boxed;

  this(B b) {
    this.boxed = b;
  }
}

bool delegate(B) eqBox(B)(B fixed) {
  bool equal(B var) {
    return fixed == var;
  }
  return &equal;
}

unittest {
  auto test = eqBox!(ulong)(0);
  assert(test(0));
  assert(!test(1));
}

unittest {
  auto boxed = new Box!(ulong)(0);
  assert(boxed.boxed == 0);
}
