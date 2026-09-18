module dulib.logic;

import st = std.traits;
import sio = std.stdio;

pragma(inline, true);
bool imply(bool a, bool b) {
  if (a) return b;
  return true;
}


T truthy(T)(bool b, T t, T f) {
  static if (st.isPointer!(T)) {
    //sio.writeln("b1");
    static assert(T.sizeof == ulong.sizeof);
    //also branchless
    return cast(T)(((cast(ulong)t) * b) + ((cast(ulong)f) * !b));

//  } else static if (T.sizeof == ulong.sizeof) {
//    sio.writeln("b2");
//    return cast(T)( ((cast(ulong)t) * b) + ((cast(ulong)f) * !b) );
//
//  } else static if (T.sizeof == uint.sizeof) {
//    sio.writeln("b3");
//    return cast(T)(((cast(uint)t) * b) + ((cast(uint)f) * !b));

  } else {
    //sio.writeln("b4");
    static assert(!st.isPointer!(T));
    static assert(ulong.sizeof == (T*).sizeof);
    //branchless
    return *cast(T*)((cast(ulong)(&t) * b) + (cast(ulong)(&f) * !b));
  }
}

version(unittest) {
  T echo(T)(T v) {
    sio.writeln(v);
    return v;
  }
 }

unittest {
  import dtmo = dulib.types.monads.option;
  import dtme = dulib.types.monads.either;

  assert(imply(false, false));
  assert(imply(false, true));
  assert(!imply(true, false));
  assert(imply(true, true));

  //Hopefully this is exhaustive enough
  assert(truthy(true, -5.0, 5.0) < -4.0);
  assert(truthy(false, -5.0, 5.0) > 4.0);

  assert(truthy(true, "true", "false") == "true");
  assert(truthy(false, "true", "false") == "false");

  assert(truthy(true, ["tr", "ue"], ["fal", "se"]) == ["tr", "ue"]);
  assert(truthy(false, ["tr", "ue"], ["fal", "se"]) == ["fal", "se"]);

  assert(truthy(true, 0.0, 5.0) == 0.0);

  alias Opt = dtmo.Option!(long);
  Opt a = Opt.make(-3);
  Opt b = Opt.make();
  Opt res1 = truthy(true, a, b);

  assert(res1.isSome());
  assert(res1.get() == -3);

  Opt res2 = truthy(false, a, b);
  assert(res2.isNone());

  alias Ei = dtme.Either!(long, double);
  Ei l = Ei.left(5);
  Ei r = Ei.right(-5.0);
  Ei res3 = truthy(true, l, r);
  Ei res4 = truthy(false, l, r);

  assert(res3.isLeft());
  assert(res4.isRight());

  assert(res3.getLeft() == 5);
  assert(res4.getRight() == -5.0);

  assert(truthy(true, &l, &r) == &l);
  assert(truthy(false, &l, &r) == &r);
}
