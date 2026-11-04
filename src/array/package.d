module dulib.array;

import dtmo = dulib.types.monads.option;
import das = dulib.array.search;


dtmo.Option!(T[]) setAppend(T)(T[] ary, T neo) {
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

  assert(setAppend(start, 0).isNone());

  auto next = setAppend(start, 3);
  assert(next.isSome());

  ulong[] unwrapped = next.get();
  assert(unwrapped.length > start.length);

}

dtmo.Option!(T[]) setPrepend(T)(T[] ary, T neo) {
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

  assert(setPrepend(start, 3).isNone());

  auto next = setPrepend(start, 0);
  assert(next.isSome());

  ulong[] unwrapped = next.get();
  assert(unwrapped.length > start.length);

}
