module dulib.types.monads.option;
import dulib.logic;

private enum OpTag {
  Some,
  None,
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

