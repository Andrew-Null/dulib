module dulib.types.argv;

import cr = core.runtime;

import dtmo = dulib.types.monads.option;
import dt = dulib.types;
import dl = dulib.logic;
import dp = dulib.paths;
import dtf = dulib.types.filesystem;

alias Flagdex = dtmo.Option!(ulong);

enum string[] HELP_FLAGS = ["-h", "--help", "-help", "help"];

struct Argv {
  const dtf.FilePath exe;
  const string[] args;

  private this(dtf.FilePath self, string[] argary) {
    this.exe = self;
    this.args = argary;
  }

  private alias Con = dtmo.Option!(Argv);
  public static Con make(string[] argv) {
    enum Con FAIL = Con.make();

    if (argv.length == 0) return FAIL;

    auto fpo = dtf.FilePath.make(argv[0]);
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

  public Flagdex findFlag(string f) {
    alias PreRet = dtmo.Option!(ulong, dt.Mutability.Mutable);
    dtmo.Option!(bool)[] checks;

    foreach (dex, arg; this.args) {
      if (arg == f) return Flagdex.make(dex);
    }

    return Flagdex.make();
  }
}
