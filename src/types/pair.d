module dulib.types.pair;

import dt = dulib.types;

public enum Naming {
  // Why? Because names mean something
  // And because I can
  KV, Order, Either, List, Lisp
  // Either, List, and Lisp are probably unnecessary
  // But at least for the moment, there isn't much of a
  // cost to having them
}

struct Duo(F, S, dt.Mutability M = dt.Mutability.Immutable, Naming N = Order){
  static if (N == Naming.Order) {
    public dt.AsMut!(F, M).Out first;
    public dt.AsMut!(S, M).Out second;

    this(F f, S s) {
      this.first = f;
      this.second = s;
    }
  } else static if (N == Naming.KV) {
    public dt.AsMut!(F, M).Out key;
    public dt.AsMut!(S, M).Out value;

    this(F k, S v) {
      this.key = k;
      this.value = v;
    }
  } else static if (N == Naming.Either) {
    public dt.AsMut!(F, M).Out left;
    public dt.AsMut!(S, M).Out right;

    this(F l, S r) {
      this.left = l;
      this.right = r;
    }
  } else static if (N == Naming.List) {
    public dt.AsMut!(F, M).Out head;
    public dt.AsMut!(S, M).Out tail;

    this(F h, S t) {
      this.head = o;
      this.tail = t;
    }
  } else static if (N == Naming.Lisp) {
    public dt.AsMut!(F, M).Out car;
    public dt.AsMut!(S, M).Out cdr;

    this(F a, S d) {
      this.car = a;
      this.cdr = d;
    }
  }
}

alias Pair(F, S, dt.Mutability M = dt.IMut) = Duo!(F, S, M, Naming.Order);
alias KeyValue(F, S, dt.Mutability M = dt.IMut) = Duo!(F, S, M, Naming.KV);

unittest {
  alias P = Pair!(ulong, float);
  ulong f = 4;
  float s = -2.5;
  P pair = P(f, s);
  assert(pair.first == f);
  assert(pair.second == s);
}

unittest {
  alias P = KeyValue!(ulong, float);
  ulong f = 4;
  float s = -2.5;
  P pair = P(f, s);
  assert(pair.key == f);
  assert(pair.value == s);
}

// should probably test the others
