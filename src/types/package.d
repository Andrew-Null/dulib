module dulib.types;

public enum Verdict : bool {
  Success = true,
  Failure = false
}

enum Mutability {
  Immutable, Mutable
}
enum Mutability IMut = Mutability.Immutable;
enum Mutability Mut = Mutability.Mutable;
