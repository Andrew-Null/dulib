module dulib.types.identring;

import sio = std.stdio;

import dt = dulib.types;
import cify = dulib.charify;
import opts = dulib.types.monads.option;

struct CheckedStr(alias check) {
  alias Self = CheckedStr!(check);
  private string txt;

  pure private this(string s) {
    this.txt = s;
  }
  
  alias CSR = opts.Option!(Self, dt.Const);
  static CSR make(string s) {
    if (!check(s)) {
      return CSR.make();
    }

    return CSR.make(Self(s));
  }

  alias Verdict = dt.Verdict;
  Verdict setText(string s) {
    if (check(s)) {
      this.txt = s;
      return Verdict.Success;
    }
    return Verdict.Failure;
  }

  const string getText() {
    return this.txt;
  }

  invariant {
    assert(check(this.txt));
    
    auto bl = check("");
    immutable string typ = typeof(bl).stringof;

    static assert(typ == bool.stringof);
  }

  bool doubleCheck() { return check(this.txt); } //good for file system stuff or something that might change out from under you
}

alias AlphaStr = CheckedStr!(cify.isAlpha);
alias SimpleStr = CheckedStr!(cify.isSimple);
alias NatNumStr = CheckedStr!(cify.isNumber);

struct CStr {
  const(char)* str;
  immutable(ulong) len;

  @property int length() {
    return cast(int)this.len;
  }

  this(string s) {
    import ss = std.string;
    this.len = s.length;
    this.str = ss.toStringz(s);
  }
}

unittest {
  alias AS = AlphaStr;
  AS.CSR csr = AS.make("a");
  
  assert(csr.isSome());
  assert(AS.make("1").isNone());

  CStr cs = CStr("abc");
  assert(cs.length == 3);
  assert(cs.str[0] == 'a');
}
