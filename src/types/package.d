module dulib.types;

public enum Verdict : bool {
  Success = true,
  Failure = false
}

public enum Mutability {
  Immutable, Mutable
}

public enum Triplean {
  Yes, Maybe, No
}

enum Mutability IMut = Mutability.Immutable;
enum Mutability Mut = Mutability.Mutable;

pure bool isIMut(Mutability m)() {
  static if (m == IMut) return true;
  else return false;
}

pure bool isMut(Mutability m)() {
  return !isIMut!(m)();
}

template AsMut(T, Mutability m) {
  static if (isMut!(m)()) alias Out = T;
  else alias Out = const(T);
}
