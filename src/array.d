module dulib.array;

import dt = dulib.types;
import dl = dulib.logic;
import dtmo = dulib.types.monads.option;
import dtb = dulib.types.box;

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
  alias Trgt = SearchTargeting;
  static if (ST == Trgt.Single) {
    alias Out = T;
  } else static if (ST == Trgt.Multi) {
    alias Out = dt.AsMut!(T[], AM).Out;
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

  foreach(i,n; flat) {
    assert(i == n);
  }
}

struct SearchConfig(T, SearchMode M = SearchMode.First,
                    SearchTargeting ST = SearchTargeting.Single,
                    SearchOutput SO = SearchOutput.Index,
                    dt.Mutability AM = dt.Mut) {
  alias Self = SearchConfig!(T, M, ST, SO, AM);
  alias BaseType = T;
  private static alias Remake(SearchMode m = M, SearchOutput so = SO, SearchTargeting st = ST, dt.Mutability am = M) = SearchConfig!(T, m, st, so, am);

  static alias Output = SOT!(T, SO).Out;

  static enum SearchOutput OUTPUT = SO;
  static enum SearchMode MODE = M;
  static enum SearchTargeting TARGETING = ST;
  static enum dt.Mutability MUTABILITY = AM;

  static assert(dl.imply(SO != SearchOutput.Index, ST != SearchTargeting.Single));
  static if (ST != SearchTargeting.Multi) {
    alias Return = SearchOut!(M, T, SO).Out;
  } else {
    alias Return = SearchOut!(M, T, SO).Out[];
  }

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

  static if (ST != SearchTargeting.Single) {
    alias SingleSearch = Self.ChangeTargeting!(SearchTargeting.Single);
  }

  static if (ST != SearchTargeting.Delegate) {
    alias DelegateSearch = Self.ChangeTargeting!(SearchTargeting.Delegate);
  }

  static if (ST != SearchTargeting.Multi) {
    alias MultiSearch = Self.ChangeTargeting!(SearchTargeting.Multi);

    static bool check(BaseType elem, InputTarget target) {
      static if (ST == SearchTargeting.Single) {
        return elem == target;
      } else {
        return target(elem);
      }
    }
  }
}

private SOT!(T, SO).Out getOutput(T, SearchOutput SO, dt.Mutability M)(dt.AsMut!(T, M).Out[]* ary, ulong index) {
  static if (SO == SearchOutput.Index) {
    return index;
  } else {
    static assert(SO == SeachOutput.Value);
    return ary*[index];
  }
}

CFG.Return newSearch(CFG)(CFG.InputArray ary, CFG.InputTarget target, CFG.INth nth = CFG.DefaultNth) in {
  static if (CFG.TARGETING != SearchTargeting.Multi) {
    static if (CFG.MODE != SearchMode.Nth) {
      assert(nth == 0); // Don't need it, don't touch it
    }
    // Could of done else opted to do separate if for explicitness/clarity
    static if (CFG.MODE == SearchMode.Nth) {
      assert(nth > 0, "nth mode is one indexed");
    }
  }

  static if (CFG.TARGETING == SearchTargeting.Multi){
    static assert(CFG.TARGETING == SearchTargeting.Multi);
    static if (CFG.MODE != SearchMode.Nth) {
      assert(nth == []); // Don't need it, don't touch it
    }

    static if (CFG.MODE == SearchMode.Nth) {
      assert(nth.length == target.length);
      foreach(n; nth) {
        assert(n > 0, "nth mode is one indexed");
      }
    }
  }
 } do{

  /*
    Pretty sure I could of reused the same loop, using condititonal
    compilation inside instead to have save some typing

    Sticking with this as it is
    A) already done
    B) Probably easier to read, with each version having its own block
       instead of them practically overlapping
  */

  pragma(msg, "dulib.array.newSearch is to be renamed shortly");
  static assert(CFG.mangleof == SearchConfig!(CFG.BaseType, CFG.MODE, CFG.TARGETING, CFG.OUTPUT, CFG.MUTABILITY).mangleof);
  alias Ret = typeof(return);
  alias getOut = getOutput!(CFG.BaseType, CFG.OUTPUT, CFG.MUTABILITY);

  static if (CFG.TARGETING == SearchTargeting.Multi && CFG.MODE != SearchMode.Nth) {
    Ret ret = [];

    foreach (trgt; target) {
      ret ~= newSearch!(CFG.SingleSearch)(ary, trgt);
    }
    return ret;
  } else static if (CFG.TARGETING == SearchTargeting.Multi && CFG.MODE == SearchMode.Nth) {
    Ret ret = [];
    foreach (i, trgt; target) {
      ret ~= newSearch!(CFG.SingleSearch)(ary, trgt, nth[i]);
    }
    return ret;
  } else {

    static assert(CFG.TARGETING != SearchTargeting.Multi);
    static if (CFG.MODE == SearchMode.First) {
      foreach(i, elem; ary) {
        if (CFG.check(elem, target)) {
          return Ret.make(getOut(&ary, i));
        }
      }
      return Ret.make();
    } else static if (CFG.MODE == SearchMode.Once) {
      ulong index = ulong.max; // By the time this doesn't work, you have bigger issues
      assert(index > ary.length);

      foreach (i, elem; ary) {
        if (CFG.check(elem, target)) {
          if (index < ary.length) {
            return Ret.make();
          }
          index = i;
        }
      }
      if (index < ary.length) {
        return Ret.make(getOut(&ary, index));
      }
      return Ret.make();
    } else static if (CFG.MODE == SearchMode.Count) {
      ulong ret = 0;
      foreach(elem; ary) {
        ret += CFG.check(elem, target);
      }
      return ret;
    } else static if (CFG.MODE == SearchMode.Nth) {
      foreach (i, elem; ary) {
        nth -= CFG.check(elem, target);
        if (nth == 0) {
          return Ret.make(getOut(&ary, i));
        }
      }
      return Ret.make();
    } else static if (CFG.MODE == SearchMode.All) {
      Ret ret = [];
      foreach (i, elem; ary) {
        if (CFG.check(elem, target)) {
          ret ~= getOut(&ary, i);
        }
      }
      return ret;
    } else static if (CFG.MODE == SearchMode.Contains) {
      foreach (elem; ary) {
        if (CFG.check(elem, target)) {
          return true;
        }
      }
      return false;
    } else {
      static assert(false);
    }

  }
}

unittest {
  alias search(cfg) = newSearch!(cfg); // newSearch is temp name, will make fixing this easier

  alias Once = SearchConfig!(ulong, SearchMode.Once, SearchTargeting.Multi);
  alias First = Once.ChangeMode!(SearchMode.First);
  alias Count = Once.ChangeMode!(SearchMode.Count);
  alias Nth = Once.ChangeMode!(SearchMode.Nth);
  alias All = Once.ChangeMode!(SearchMode.All);
  alias Contains = Once.ChangeMode!(SearchMode.Contains);

  enum string[] mangles = [Once.mangleof, First.mangleof, Count.mangleof, Nth.mangleof, All.mangleof, Contains.mangleof];
  foreach(i, mang; mangles) {
    alias all = search!(SearchConfig!(string, SearchMode.All, SearchTargeting.Single));
    auto matches = all(mangles, mang);
    assert(matches.length == 1);
    assert(matches[0] == i);
  }

  alias count = search!(Count);
  alias scount = search!(Count.SingleSearch);
  alias sall = search!(All.SingleSearch);
  alias contains = search!(Contains);

  ulong[] test = [6, 1, 6, 2, 2, 6, 3, 3, 3, 6, 4, 4, 4, 4, 6, 5, 5, 5, 5, 5, 6];
  ulong[] set = [1, 2, 3, 4, 5, 6];

  auto cont = contains(test, set);
  foreach(c; cont) {
    assert(c);
  }

  foreach(cnt; set) {
    assert(scount(test, cnt) == cnt);
    assert(sall(test, cnt).length == cnt);
  }

  auto counted = count(test, set);
  foreach(num; set) {
    assert(counted[num-1] == num);
  }

  // Might not be tested, but at least being initialized
  alias once = search!(Once);
  alias first = search!(First);
  alias nth = search!(Nth);
  alias all = search!(All);

  // Given multi searches 'map' Single searches not as much testing
  // needed
}

unittest {
  alias search(cfg) = newSearch!(cfg); // newSearch is temp name, will make fixing this easier

  alias Once = SearchConfig!(ulong, SearchMode.Once);
  alias First = SearchConfig!(ulong, SearchMode.First);
  alias Count = SearchConfig!(ulong, SearchMode.Count);
  alias Nth = SearchConfig!(ulong, SearchMode.Nth);
  alias All = SearchConfig!(ulong, SearchMode.All);
  alias Contains = SearchConfig!(ulong, SearchMode.Contains);

  alias once = search!(Once);
  alias first = search!(First);
  alias count = search!(Count);
  alias nth = search!(Nth);
  alias all = search!(All);
  alias contains = search!(Contains);

  enum ulong[] test = [5, 1, 5, 2, 2, 5, 3, 3, 3, 5, 4, 4, 4, 4, 5];

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

SearchOut!(M, T).Out searchArray(T, SearchMode M = SearchMode.First, dt.Mutability I = dt.Mut)
  (dt.AsMut!(T[], I).Out ary, T target, ulong nth = 0) in {

 } do {
  alias Ret = typeof(return);


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
