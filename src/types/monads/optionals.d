module dulib.optionals;
import dulib.logic;

private enum OpTag {
  Some,
  None,
}

private enum ResulTag {
  Ok,
  Err,
}

struct Option(S) {
  private OpTag tag;
  private S some;
  
  private this(const bool because) in(!because) {
    this.tag = OpTag.None;
  }

  private this(const bool because, S data) in(because) {
    this.tag = OpTag.Some;
    this.some = data;
  }

  static public pure Option makeSome(S data) {
    return Option!(S)(true, data);
  }

  static public pure Option makeNone() {
    return Option!(S)(false);
  }
  
  pure nothrow public void setNone() {
    this.tag = OpTag.None;
  }
  
  pure nothrow public void setSome(S data) {
    this.some = data;
    this.tag = OpTag.Some;
  }
  
  pure nothrow public bool isSome() //would put contract on both, but concerned about endless recursion
       out(s; s == !isNone()) do {
    return this.tag == OpTag.Some;
  }

  pure nothrow public bool isNone() {
    return this.tag == OpTag.None;
  }

  pure public S getSome() in (isSome()) {return this.some;}
				 
  public O match(O)(O function(S) somef, O function() nonef) {
    if (this.isSome()) return somef(this.some);
    return nonef();
  }

  public void match(void function(S) somef, void function() nonef) {
    if (this.isSome()) somef(this.some);
    else return nonef();
  }
}

struct Result(O,E) {
  ResulTag tag;
  union {
    O okay;
    E error;
  }
  
  private this(O d) {
    this.tag = ResulTag.Ok;
    this.okay = d;
  }
  
  private this(E d, bool disc) {
    assert(disc);
    this.tag = ResulTag.Err;
    this.error = d;
  }
  
  public static pure Result makeOkay(O data) out(ret) {
    assert(ret.tag == ResulTag.Ok);
  } do {
    return Result!(O,E)(data);
  }
  public static pure Result makeError(E data) out(ret) {
    assert(ret.tag == ResulTag.Err);
  } do {
    return Result!(O,E)(data, true);
  }
  
  public pure O getOkay() in(this.isOkay()) {
    return this.okay;
  }
  
  public pure E getError() in(this.isError()) {
    return this.error;
  }
  
  public pure nothrow bool isOkay() //would put contract on both, but concerned about endless recursion
       out(ok; ok == !(this.isError())) {return this.tag == ResulTag.Ok;}
  public pure nothrow bool isError() {return this.tag == ResulTag.Err;}
  
  public pure nothrow void setOkay(O d) {
    this.tag = ResulTag.Ok;
    this.okay = d;
  }
  
  public pure nothrow void setError(E d) {
    this.tag = ResulTag.Err;
    this.error = d;
  }
}

unittest {
  bool ert = true;
  alias Opt = Option!(int);
  auto a = Opt.makeNone();
  assert(a.isNone());

  try {
    a.getSome();
    ert = false;
  } catch (Error ae) {
  }
  assert(ert);

  a.setSome(1);
  assert(a.isSome());
  assert(a.getSome() == 1);

  a.setNone();
  try {
    a.getSome();
    ert = false;
  } catch (Error ae) {
  }
  assert(ert);
}

unittest {
  bool ert = true;
  alias Res = Result!(int, float);
  alias Conf = Result!(int, int);

  Res a = Res.makeOkay(1), b = Res.makeError(1.0);
  assert(a.isOkay());
  assert(b.isError());

  try {
    a.getError();
    ert = false;
  } catch (Error e) {}
  assert(ert);

  try {
    b.getOkay();
    ert = false;
  } catch (Error e) {}
  assert(ert);

  assert(a.getOkay() == 1);
  assert(b.getError() == 1.0);

  b.setOkay(1);

  assert(a.getOkay() == b.getOkay());
}
