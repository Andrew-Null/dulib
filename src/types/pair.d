module dulib.types.pair;

import dt = dulib.types;

struct Pair(F, S, dt.Mutability M = dt.Mutability.Immutable){
  public dt.AsMut!(F, M).Out first;
  public dt.AsMut!(S, M).Out second;

  this(F f, S s) {
    this.first = f;
    this.second = s;
  }
}
