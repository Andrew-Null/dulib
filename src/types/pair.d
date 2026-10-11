module dulib.types.pair;

import dt = dulib.types;

struct Duo(F, S, string FNAME, string LNAME, dt.Mutability M = dt.Mutability.Immutable){
  mixin("public dt.AsMut!(F, M).Out " ~ FNAME ~ ";");
  mixin("public dt.AsMut!(S, M).Out " ~ LNAME ~ ";");

  mixin("pure this(F f, S s) {
     this." ~ FNAME ~ " = f;
     this." ~ LNAME ~" = s;
   }");
}

alias Pair(F, S, dt.Mutability M = dt.IMut) = Duo!(F, S, "first", "second", M);
alias KeyValue(F, S, dt.Mutability M = dt.IMut) = Duo!(F, S,"key", "value", M);

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
