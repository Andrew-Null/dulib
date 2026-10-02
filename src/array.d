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
  else static if (SM == SMT.All) alias Out = immutable(ulong)[];
}

SearchOut!(M).Out searchArray(T, SearchMode M = SearchMode.First)(T[] ary, T target, ulong nth = 0) in {

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

    ulong ret = (ary.length + 1);

    foreach(i, elem; ary) {

      if (elem != target) {
        continue;
      }
      assert(elem == target);

      // Toss up which is harder to read these odd almost counter
      // intuitive guard clauses or the extra nesting to do otherwise

      if (ret < ary.length) {
        return Ret.make();
      }
      assert(ret == (ary.length + 1)); // should look familiar

      ret = i;
    }

    if (ret < ary.length) {
      // assuming by this point this is the hotter path
      return Ret.make(ret);
    }
    return Ret.make();

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

SearchOut!(M).Out[] multiSearchArray(T, SearchMode M = SearchMode.First)(T[] ary, T[] targets, ulong[] nth = []) in {
  static if (M == SearchMode.Nth) {
    assert(targets.length == nth.length);
  }

  static if (M != SearchMode.Nth) {
    assert(nth.length == 0);
  }
 } out(r; r.length == targets.length) do {
  alias Ret = typeof(return);
  Ret ret;

  foreach(i, target; targets) {
    static if (M == SearchMode.Nth) {
      ret ~= searchArray!(T, M)(ary, target, nth[i]);
    } else {
      ret ~= searchArray!(T, M)(ary, target);
    }
  }

  return ret;
}

unittest {
  ulong[] test = [5, 1, 5, 2, 2, 5, 3, 3, 3, 5, 4, 4, 4, 4, 5];
  alias count = searchArray!(ulong, SearchMode.Count);
  alias first = searchArray!(ulong, SearchMode.First);
  alias once = searchArray!(ulong, SearchMode.Once);
  alias nth = searchArray!(ulong, SearchMode.Nth);
  alias all = searchArray!(ulong, SearchMode.All);

  for (ulong cnt = 1; cnt <= 5; cnt++) {
    assert(count(test, cnt) == cnt);
    assert(all(test, cnt).length == cnt);

  }

  auto o1 = once(test, 1);
  auto f1 = first(test, 1);
  auto n1 = nth(test, 1, 1);
  assert(o1.isSome() && f1.isSome() && n1.get());
  assert((o1.get() == 1) && (o1.get() == f1.get()) && (o1.get() == n1.get()));

  for (ulong cnt = 2; cnt <= 5; cnt++) {
    auto o = once(test, cnt);
    auto f = first(test, cnt);
    auto n = nth(test, cnt, 1);
    auto np = nth(test, cnt, 2);

    assert(o.isNone);
    assert(f.isSome() && n.isSome() && np.isSome());
    assert(f.get() == n.get());
    assert(n.get() < np.get());
    assert(((np.get() == (n.get() + 1)) && (cnt != 5)) ^ ((np.get() == n.get() + 2) && (cnt == 5)));
  }

  assert(count(test, 6) == 0);
  assert(first(test, 6).isNone());
  assert(once(test, 6).isNone());
  assert(nth(test, 6, 1).isNone());
  assert(all(test, 6) == []);
}

unittest {
  ulong[] test = [6, 1, 6, 2, 2, 6, 3, 3, 3, 6, 4, 4, 4, 4, 6, 5, 5, 5, 5, 5, 6];
  ulong[] set = [1, 2, 3, 4, 5, 6];

  alias count = multiSearchArray!(ulong, SearchMode.Count);
  alias first = multiSearchArray!(ulong, SearchMode.First);
  alias once = multiSearchArray!(ulong, SearchMode.Once);
  alias nth = multiSearchArray!(ulong, SearchMode.Nth);
  alias all = multiSearchArray!(ulong, SearchMode.All);


  foreach(cnt; set) {
    assert(searchArray!(ulong, SearchMode.Count)(test, cnt) == cnt);
    assert(searchArray!(ulong, SearchMode.All)(test, cnt).length == cnt);
  }

  auto counted = count(test, set);
  foreach(num; set) {
    assert(counted[num-1] == num);
  }

  /*
    Could multiSearchArray use more testing? Maybe.
    But most logic is in searchArray, which is well tested
    so should be fine
  */
}
