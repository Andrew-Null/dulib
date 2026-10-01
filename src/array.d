module dulib.array;

import dt = dulib.types;
import dtmo = dulib.types.monads.option;

enum SearchMode {
  Once, First, Count, Nth, All
}

private template SearchOut(SearchMode SM) {
  alias OptIndex =  dtmo.Option!(ulong, dt.IMut);
  private alias SMT = SearchMode;
  static if (SM == SMT.Count) alias Out = ulong;
  else static if
    ((SM == SMT.First) || (SM == SMT.Nth) || (SM == SMT.Once))
    alias Out = OptIndex;
  else static if (SM == SMT.All) alias Out = immutable(immutable(ulong)[]);
}

SearchOut!(M) searchArray(T, SearchMode M = SearchMode.First)(T[] ary, T target, ulong nth = 0) in {

  static if (M == SearchMode.Once) {
    assert(searchArray!(SearchMode.Count, T)(ary, target) <= 1);
  }

  static if (M != SearchMode.Nth) {
    assert(nth == 0); // Don't need it, don't touch it
  }

  // Could of done else opted to do separate if for explicitness/clarity
  static if (M == SearchMode.Nth) {
    assert(nth > 0);
  }

 } do {
  alias Ret = typeof(return);

  /*
    Pretty sure I could of reused the same loop, using condititonal
    compilation inside instead to of saved some typing

    Sticking with this as it is
    A) already done
    B) Probably easier to read, with each version having its own block
       instead of them practically overlapping
  */

  static if (M == SearchMode.Count) {

    Ret ret = 0;
    foreach(elem; ary) {
      ret += elem == target;
    }
    return ret;

  } else static if (M == SearchMode.First) {

    foreach(i, elem; ary) {
      if (elem == target) {
        return Ret.make(i);
      }
    }
    return Ret.make();

  } else static if (M == SearchMode.Once) {

    return searchArray!(SearchMode.First, T)(ary, target);

  } else static if (M == SearchMode.All) {

    Ret ret = [];
    foreach(i, elem; ary) {
      if (elem == target) {
        ret ~= i;
      }
    }
    return ret;

  } else static if (M == SearchMode.Nth) {

    foreach(i, elem; ary) {
      if (elem == target) {
        nth -= 1;
      }
      if (nth == 0) {
        return Ret.make(i);
      }
    }
    return Ret.make();

  }
}
