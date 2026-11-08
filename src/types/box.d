module dulib.types.box;

import dt = dulib.types;
import dtmo = dulib.types.monads.option;

class Box(B, ulong MIN_SIZE = 0, dt.Mutability M = dt.Mut) {
  static assert (B.sizeof >= MIN_SIZE);
  dt.AsMut!(B, M).Out boxed;

  @disable this();

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

struct AnonPtr {
  immutable(string) mangle;
  private void* ptr;

  private this(void* p, string m) {
    this.mangle = m;
    this.ptr = p;
  }

  public static AnonPtr make(T)(T* data) {
    return AnonPtr(cast(void*)data, T.mangleof);
  }

  public dtmo.Option!(T) deref(T)() {
    alias Ret = typeof(return);
    if (T.mangleof == this.mangle) {
      return Ret.make(*(cast(T*)this.ptr));
    }
    return Ret.make();
  }

  public dt.Confirmation set(T)(T* data) {
    if (T.mangleof == this.mangle) {
      this.ptr = data;
      return dt.Confirmation.Success;
    }
    return dt.Confirmation.Failure;
  }
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

unittest {
  ulong test = 0;
  AnonPtr ptr = AnonPtr.make!(ulong)(&test);

  auto zero = ptr.deref!(ulong)();
  assert(zero.isSome());
  assert(zero.get() == 0);

  test = 1;
  auto one = ptr.deref!(ulong)();
  assert(one.isSome());
  assert(one.get() == 1);

  auto invalid = ptr.deref!(byte);
  assert(invalid.isNone());

}

unittest {
  assert(string.sizeof == 16);
  assert(ulong[].sizeof == 16);
}
