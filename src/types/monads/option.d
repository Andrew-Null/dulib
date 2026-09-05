module dulib.types.monads.option;
import dulib.logic;
import dt = dulib.types;


private enum OpTag {
  Some,
  None,
}

struct Option(S, dt.Mutability M = dt.IMut) {
  private dt.AsMut!(OpTag, M).Out tag;
  private dt.AsMut!(S, M).Out just;

  alias Self = Option!(S, M);

  private pure this(const bool because) in(!because) {
    this.tag = OpTag.None;
  }

  private pure this(const bool because, S data) in(because) {
    this.tag = OpTag.Some;
    this.just = data;
  }

  static public pure Self make(S data) {
    return Self(true, data);
  }

  static public pure Self make() {
    return Self(false);
  }
  
  static if (dt.isMut!(M)()) {
    pure nothrow public void set() {
      this.tag = OpTag.None;
    }

    pure nothrow public void set(S data) {
      this.just = data;
      this.tag = OpTag.Some;
    }
  }
  
  pure nothrow public bool isSome() //would put contract on both, but concerned about endless recursion
       out(s; s == !isNone()) do {
    return this.tag == OpTag.Some;
  }

  pure nothrow public bool isNone() {
    return this.tag == OpTag.None;
  }

  pure public S get() in (this.isSome()) {return cast(S) this.just;}
				 
  public Option!(O, N) bind(O, dt.Mutability N = M)(O function(S) somef) {
    alias Ret = Option!(O, N);
    if (this.isSome()) return Ret.make(somef(this.get()));
    else return Ret.make();
  }

  public Option!(O, N) bind(O, dt.Mutability N = M)(O delegate(S) somef) {
    alias Ret = Option!(O, N);
    if (this.some()) return Ret.make(somef(this.just));
    else return Ret.make();
  }

  public Option!(O, N) join(O, dt.Mutability N = M)(Option!(O, N) function(S) somef) {
    alias Ret = Option!(O, N);
    if (this.some()) return somef(this.get());
    else return Ret.make();
  }

  public Option!(O, N) join(O, dt.Mutability N = M)(Option!(O, N) delegate(S) somef) {
    alias Ret = Option!(O, N);
    if (this.some()) return somef(this.get());
    else return Ret.make();
  }
}

version(unittest) { private int twice(int i) {return (i << 1);} }
unittest {

  bool ert = true;
  alias Opt = Option!(int, dt.Mut);
  auto a = Opt.make();
  assert(a.isNone());
  assert(a.bind(&twice).isNone());

  try {
    a.get();
    ert = false;
  } catch (Error ae) {
  }
  assert(ert);

  a.set(1);
  assert(a.isSome());
  assert(a.get() == 1);
  assert(a.bind(&twice).get() == 2);

  a.set();
  try {
    a.get();
    ert = false;
  } catch (Error ae) {
  }
  assert(ert);
}

unittest {
  alias Opt = Option!(int,);
  auto a = Opt.make(1);
  assert(a.isSome());
  assert(!a.isNone());
  int got = a.get();
  assert(got == 1);
}
