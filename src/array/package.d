module dulib.array;

import dtmo = dulib.types.monads.option;
import das = dulib.array.search;

pure T[] flatten(T)(T[][] unflat) {
  if (unflat.length == 0) {
    return [];
  } else if (unflat.length == 1) {
    return unflat[0];
  }

  T[] ret = unflat[0];
  for (ulong dex = 1; dex < unflat.length; dex++) {
    ret ~= unflat[dex];
  }
  return ret;
}

unittest {
  ulong[][] unflat = [[0,1,2],[3],[4,5],[6,7,8,9],[],[10]];
  ulong[] flat = flatten(unflat);

  foreach(i,n; flat) {
    assert(i == n);
  }
}

dtmo.Option!(T[]) setPostcat(T)(T[] ary, T neo) {
  alias Ret = typeof(return);
  alias CFG = das.SearchConfig!(T).ChangeMode!(das.SearchMode.Contains);
  if (das.arraySearch!(CFG)(ary, neo)) {
    return Ret.make();
  }



  return Ret.make(ary ~ neo);
}

unittest {
  ulong[] start = [0, 1, 2];
  immutable ulong initLen = start.length;

  assert(setPostcat(start, 0).isNone());

  auto next = setPostcat(start, 3);
  assert(next.isSome());

  ulong[] unwrapped = next.get();
  assert(unwrapped.length > start.length);

}

dtmo.Option!(T[]) setPrecat(T)(T[] ary, T neo) {
  alias Ret = typeof(return);
  alias CFG = das.SearchConfig!(T).ChangeMode!(das.SearchMode.Contains);
  if (das.arraySearch!(CFG)(ary, neo)) {
    return Ret.make();
  }

  return Ret.make(neo ~ ary);
}

unittest {
  ulong[] start = [1, 2, 3];
  immutable ulong initLen = start.length;

  assert(setPrecat(start, 3).isNone());

  auto next = setPrecat(start, 0);
  assert(next.isSome());

  ulong[] unwrapped = next.get();
  assert(unwrapped.length > start.length);

}
