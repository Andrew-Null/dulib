module dulib.array;

import dt = dulib.types;
import dl = dulib.logic;
import dtmo = dulib.types.monads.option;

enum SearchMode {
  Once, First, Count, Nth, All, Contains
}

enum SearchTargeting {
  Single, Multi, Function, Delegate
}

enum SearchOutput {
  Index, Value
}

private template SOT(T, SearchOutput SO = SearchOutput.Index) {
  static if (SO == SearchOutput.Index) {
    alias Out = ulong;
  } else {
    alias Out = T;
  }
}


private template SearchOut(SearchMode SM, T, SearchOutput SO = SearchOutput.Index) {
  alias Output = SOT!(T, SO).Out;
  alias OptIndex =  dtmo.Option!(Output, dt.IMut);
  private alias SMT = SearchMode;
  static if (SM == SMT.Count) alias Out = Output;
  static if (SM == SMT.Contains) alias Out = bool;
  else static if
    ((SM == SMT.First) || (SM == SMT.Nth) || (SM == SMT.Once))
    alias Out = OptIndex;
  else static if (SM == SMT.All) alias Out = immutable(Output)[];
}

private template SearchTarget(T, SearchTargeting ST = SearchTargeting.Single, dt.Mutability AM = dt.Mut) {
  static assert(dl.imply(AM != dt.Mut, ST == SearchTargeting.Multi));
  alias Trgt = SearchTargeting;
  static if (ST == Trgt.Single) {
    alias Out = T;
  } else static if (ST == Trgt.Multi) {
    alias Out = dt.AsMut(T[], AM);
  } else static if (ST == Trgt.Function) {
    alias Out = bool function(T);
  } else {
    static assert(ST == Trgt.Delegate);
    alias Out = bool delegate(T);
  }

}

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

  foreach(i,n;flat) {
    assert(i == n);
  }
}

struct SearchConfig(T, SearchMode M = SearchMode.First, SearchOutput SO = SearchOutput.Index,
                    SearchTargeting ST = SearchTargeting.Single,
                    dt.Mutability AM = dt.Mut) {
  alias Self = SearchConfig!(T, M, SO, ST, AM);
  private static alias Remake(SearchMode m = M, SearchOutput so = SO, SearchTargeting st = ST, dt.Mutability am = M) = SearchConfig!(T, m, so, st, am);

  static alias Output = SOT!(T, SO);

  static enum SearchOutput OUTPUT = SO;
  static enum SearchMode MODE = M;
  static enum SearchTargeting TARGETING = ST;
  static enum dt.Mutability MUTABILITY = AM;

  static assert(dl.imply(SO != SearchOutput.Index, ST != SearchTargeting.Single));
  alias Return = SearchOut!(M, T, SO);

  static assert(dl.imply(AM != dt.Mut, ST == SearchTargeting.Multi));
  alias InputArray = dt.AsMut!(T, AM).Out[];
  static if (ST == SearchTargeting.Multi) {
    alias INth = ulong[];
    enum INth DefaultNth = [];
  } else {
    alias INth = ulong;
    enum INth DefaultNth = 0;
  }

  alias InputTarget = SearchTarget!(T, ST, AM).Out;

  static alias ChangeMode(SearchMode sm) = Remake!(sm, SO, ST, AM);
  static alias ChangeOutput(SearchOutput so) = Remake!(M, so, ST, AM);
  static alias ChangeTargeting(SearchTargeting st) = Remake!(M, SO, st, AM);
  static alias ChangeArrayMutability(dt.Mutability am) = Remake!(M, SO, ST, am);

  static if (M != SearchMode.First) {
    alias FindFirst = Self.ChangeMode!(SearchMode.First);
  }
}

unittest {
  SearchConfig!(string) sc = SearchConfig!(string).init;
  SearchConfig!(ulong) sc2 = SearchConfig!(ulong).init;
  typeof(sc).ChangeMode!(SearchMode.All) sc3;
  //pragma(msg, SearchConfig.stringof);
  //pragma(msg, SearchConfig.mangleof);
  //pragma(msg, typeof(sc).mangleof);
  //pragma(msg, typeof(sc2).mangleof);
}

CFG.Output newSearch(CFG)(CFG.InputArray ary, CFG.InputTarget target, CFG.INth nth = CFG.DefaultNth) {

}

SearchOut!(M, T).Out searchArray(T, SearchMode M = SearchMode.First, dt.Mutability I = dt.Mut)
  (dt.AsMut!(T[], I).Out ary, T target, ulong nth = 0) in {

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

  } else static if (M == SearchMode.Contains) {

    foreach (i, elem; ary) {
      if (elem == target) {
        return true;
      }
    }
    return false;

  } else {
    static assert(0);
  }
}

SearchOut!(M, T).Out[] multiSearchArray(T, SearchMode M = SearchMode.First, dt.Mutability I = dt.Mut)
  (dt.AsMut!(T[], I).Out ary, T[] targets, ulong[] nth = []) in {
  static if (M == SearchMode.Nth) {
    assert(targets.length == nth.length);
  }

  static if (M != SearchMode.Nth) {
    assert(nth.length == 0);
  }
 } out(r; r.length == targets.length) do {
  alias Ret = typeof(return);
  Ret ret;
  alias search = searchArray!(T, M, I);

  foreach(i, target; targets) {
    static if (M == SearchMode.Nth) {
      ret ~= search(ary, target, nth[i]);
    } else {
      ret ~= search(ary, target);
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
  alias contains = searchArray!(ulong, SearchMode.Contains);

  for (ulong cnt = 1; cnt <= 5; cnt++) {
    assert(count(test, cnt) == cnt);
    assert(all(test, cnt).length == cnt);

  }

  for (ulong val = 0; val < test.length; val++) {
    assert((count(test, val) > 0) == contains(test, val));
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

/*SearchOut!(M, O).Out searchArray(T, SearchMode M = SearchMode.First, dt.Mutability I = dt.Mut, O = ulong)
  (dt.AsMut!(T[], I).Out ary, bool function(T) targeting, ulong nth = 0) in {
  static assert((O.stringof == ulong.stringof) || (O.stringof == T.stringof));

  static if (M != SearchMode.Nth) {
    assert(nth == 0); // Don't need it, don't touch it
  }

  // Could of done else opted to do separate if for explicitness/clarity
  static if (M == SearchMode.Nth) {
    assert(nth > 0);
  }

 } do {
  alias Ret = typeof(return);
  return Ret.init;
 }*/
