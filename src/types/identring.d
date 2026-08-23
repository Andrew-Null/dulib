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
  
  alias CSR = opts.Option!(Self, dt.Mut);
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

  string getText() {
    return this.txt;
  }

  invariant {
    assert(check(this.txt));
    
    auto bl = check("");
    immutable string typ = typeof(bl).stringof;

    static assert(typ == bool.stringof);
  }
}

alias AlphaStr = CheckedStr!(cify.isAlpha);
alias SimpleStr = CheckedStr!(cify.isSimple);
alias NatNumStr = CheckedStr!(cify.isNumber);

unittest {
  alias AS = AlphaStr;
  AS.CSR csr = AS.make("a");
  
  assert(csr.some());
  assert(AS.make("1").none());
}
