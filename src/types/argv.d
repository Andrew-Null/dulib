module dulib.types.argv;

import cr = core.runtime;

import dtmo = dulib.types.monads.option;
import dt = dulib.types;
import dl = dulib.logic;
import dp = dulib.paths;
alias Flagdex = dtmo.Option!(ulong);

enum string[] HELP_FLAGS = ["-h", "--help", "-help", "help"];

struct Argv {
  const dp.FilePath exe;
  const string[] args;

  private this(dp.FilePath self, string[] argary) {
    this.exe = self;
    this.args = argary;
  }

  private alias Con = dtmo.Option!(Argv);
  public static Con make(string[] argv) {
    enum Con FAIL = Con.make();

    if (argv.length == 0) return FAIL;

    auto fpo = dp.FilePath.make(argv[0]);
    if (fpo.isNone()) return FAIL;

    string[] ary = [];
    if (argv.length > 1) ary = argv[1..$];

    return Con.make(Argv(fpo.get, ary));
  }

  @property pure ulong argc() {
    return this.args.length;
  }

  @property pure ulong argl() {
    return this.args.length + 1;
  }

  public Flagdex findFlag(bool P = false)(string f) {
    alias PreRet = dtmo.Option!(ulong, dt.Mutability.Mutable);
    static if (P) {
      import sp = std.parallelism;
      dtmo.Option!(bool)[this.argc.length] checks;

      foreach (dex, arg; sp.parallel(this.args)) {
          checks[dex] = dtmo.Option!(bool)(arg == f);
        }

      foreach (dex, chk; checks) {
        if (chk.get()) return Flagdex.some(dex);
      }

      return Flagdex.none();
    }
  }
}
