module dulib.types.argv;

import cr = core.runtime;

import dtmo = dulib.types.monads.option;
import dt = dulib.types;
import dl = dulib.logic;
import dp = dulib.paths;
import dtf = dulib.types.filesystem;

alias Flagdex = dtmo.Option!(ulong);

enum string[] HELP_FLAGS = ["-h", "--help", "-help", "help"];

enum FindFlagMode {
  Once, First, Count, Nth
}
private alias FFM = FindFlagMode;

private template FFOut(FindFlagMode FF) { // FindFlagOut
  static if (FF == FFM.Count) alias Out = ulong;

}

struct Argv(bool MOCK = false) {
  alias Self = Argv!(MOCK);
  static assert(dl.imply(MOCK, dl.isUnittest));
  static if (dl.isUnittest() && MOCK) {
    alias Exe = dtf.FilePath.Mockable;

    public static Self mock(string e, string[] args) {
      return Self(Exe.mock(e), args);
    }

  } else {
    alias Exe = dtf.FilePath;
  }
  const Exe exe;
  const string[] args;

  private this(Exe self, string[] argary) {
    this.exe = self;
    this.args = argary;
  }

  private alias Con = dtmo.Option!(Self);
  public static Con make(string[] argv) {
    enum Con FAIL = Con.make();

    if (argv.length == 0) return FAIL;

    auto fpo = Exe.make(argv[0]);
    if (fpo.isNone()) return FAIL;

    string[] ary = [];
    if (argv.length > 1) ary = argv[1..$];

    return Con.make(Argv(fpo.get, ary));
  }

  @property pure ulong argc() {
    return this.args.length;
  }

  @property pure ulong argvl() {
    return this.args.length + 1;
  }

  //public Flagdex findFlag(string f) {
  //  alias PreRet = dtmo.Option!(ulong, dt.Mutability.Mutable);
  //  dtmo.Option!(bool)[] checks;

  //  foreach (dex, arg; this.args) {
  //    if (arg == f) return Flagdex.make(dex);
  //  }

  //  return Flagdex.make();
  //}

  public FFOut!(M).Out findFlag(FindFlagMode M)(string flag) {
    alias Ret = typeof(return);
    static if (M == FFM.Count) {
      Ret cnt = 0;
      foreach(arg; this.args) {
        cnt += arg == flag;
      }
      return cnt;

    }
    assert(0);

  }
}

unittest {
  assert(Argv!(false).make([]).isNone());
  assert(Argv!(true).make([]).isNone());

  alias AV = Argv!(true);
  AV count = AV.mock("not an exe", ["-b", "-a", "-a", "-b", "-c", "-b"]);
  assert(count.findFlag!(FFM.Count)("-a") == 2);
  assert(count.findFlag!(FFM.Count)("-b") == 3);
  assert(count.findFlag!(FFM.Count)("-c") == 1);
}
