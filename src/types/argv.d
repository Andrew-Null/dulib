module dulib.types.argv;

import cr = core.runtime;

import dtmo = dulib.types.monads.option;
import dt = dulib.types;
import dl = dulib.logic;
import dp = dulib.paths;
import dtf = dulib.types.filesystem;
import da = dulib.array;

alias Flagdex = dtmo.Option!(ulong);

enum string[] HELP_FLAGS = ["-h", "--help", "-help", "help"];

public alias Argv = ArgVec!(false);
struct ArgVec(bool MOCK = false) {
  alias Self = ArgVec!(MOCK);
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

    return Con.make(Self(fpo.get, ary));
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

  public auto findFlag(da.SearchMode M)(string flag) {
    return da.searchArray!(string, M, dt.Const)(this.args, flag);
  }
}

unittest {
  assert(Argv.make([]).isNone());
  assert(ArgVec!(true).make([]).isNone());

  alias AV = ArgVec!(true);
  AV count = AV.mock("not an exe", ["-b", "-a", "-a", "-b", "-c", "-b"]);
  assert(count.findFlag!(da.SearchMode.Count)("-a") == 2);
  assert(count.findFlag!(da.SearchMode.Count)("-b") == 3);
  assert(count.findFlag!(da.SearchMode.Count)("-c") == 1);
}
