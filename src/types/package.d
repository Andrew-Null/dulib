module dulib.types;

public enum Verdict : bool {
  Success = true,
  Failure = false
}

public enum Mutability {
  Immutable, Constant, Mutable
}

public enum Triplean {
  Yes, Maybe, No
}

enum Mutability IMut = Mutability.Immutable;
enum Mutability Mut = Mutability.Mutable;
enum Mutability Const = Mutability.Constant;

pure bool isIMut(Mutability m)() {
  enum bool ret = m == IMut;
  return ret;
}

pure bool isMut(Mutability m)() {
  enum bool ret = m == Mut;
  return ret;
}

pure bool isConst(Mutability m)() {
  return !(isIMut!(m)() || isMut!(m)());
}

template AsMut(T, Mutability m) {
  static if (isMut!(m)()) alias Out = T;
  else static if (isIMut!(m)) alias Out = immutable(T);
  else {
    static assert(isConst!(m)());
    alias Out = const(T);
  }
}
