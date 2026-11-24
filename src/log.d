module dulib.log;

import sio = std.stdio;
import sf = std.file;
import ct = core.time;
import sdd = std.datetime.date;
import sds = std.datetime.systime;
import ss = std.string;

import das = dulib.array.search;
import dtp = dulib.types.pair;
import dtf = dulib.types.filesystem;
import dtmo = dulib.types.monads.option;
import dl = dulib.logic;
import dtme = dulib.types.monads.either;
import dtmm = dulib.types.monads.maybeith;
import dt = dulib.types;

void errPrint(string txt) {
  sio.stderr.write(txt);
}

void errPrintln(string txt) {
  sio.stderr.writeln(txt);
}

private: //temporary

private alias LO = LogOut;
enum LogOutput : LO {
  StdOut = LO.StdOut, StdErr = LO.StdErr, None = LO.None
}

private enum LogOut {
  File, StdOut, StdErr, None
}

enum WriteMode : immutable(char[2]) {
  Overrite = ['w', '='], Append = ['a', '='], Write = ['w', '+'], Create = ['c', '+']
}

private struct FlushTimer {
  /*
    Using with Logger would force Logger to be constantly impure . . . Using
    this as originally intended likely would require a lot of comptime/meta
    programming which I am obviously capable of (see arraySearch), ultimately
    integration is a project for a later date, especially if I want both
    timers either master xor per category

    Integration is going to have to wait as I want some sort of time stamping
    capability, either time or order first

    Not to mention the question of making this multi threaded safe . . . which
    may mean a rework . . . time will tell

    TODO (11-16-26): integration
  */
  immutable(ulong) max;
  ulong current = 0;

  this(ulong mx) {
    this.max = mx;
    this.current = mx;
  }

  bool tick() in (this.current > 0) out (r; this.current > 0) {
      this.current -= 1; //tick

    if (this.current > 0) {
      return false;
    }

    assert(this.current == 0);

    //reset
    this.current = this.max;
    return true;
  }
}

struct LogDestination {
  alias Self = LogDestination;
  immutable(LO) tag;
  private alias FileCfg = dtp.Duo!(dtf.Path, WriteMode, "path", "mode");
  alias LFile = immutable(dtmo.Option!(FileCfg));
  LFile logFile;

  pure invariant {
    bool ft = this.tag == LO.File; // file tag
    bool some = this.logFile.isSome();
    assert(dl.imply(ft, some) && dl.imply(!ft, !some));
  }

  pure private this(LogOutput lo) {
    this.tag = lo;
    this.logFile = LFile.make();
  }

  pure private this(LFile lf) {
    this.logFile = lf;
    this.tag = LO.File;
  }

  pure static Self makeOut() {
    return Self(LogOutput.StdOut);
  }

  pure static Self makeErr() {
    return Self(LogOutput.StdErr);
  }

  pure static Self makeNone() {
    return Self(LogOutput.None);
  }

  static dtmo.Option!(Self) makeFile(dtf.Path file, WriteMode mode) {
    alias Ret = typeof(return);
    immutable(string) path = file.getText();

    if (mode[1] == '=' && !sf.exists(path)) {
      return Ret.make();
    }

    return Ret.make(Self(LFile.make(FileCfg(file, mode))));
  }

  static dtmo.Option!(Self) makeFile(string file, WriteMode mode) {
    alias Ret = typeof(return);
    auto path = dtf.Path.make(file);

    if (path.isNone()) {
      return Ret.make();
    }

    return LogDestination.makeFile(path.get(), mode);
  }

  void writeln(string s) {
    final switch (this.tag) {
      case LO.StdOut: {
        sio.writeln(s);
      } break;
      case LO.StdErr: {
        sio.stderr.writeln(s);
      } break;
      case LO.None: {} break;
      case LO.File: {
        // This is terrible for writing a bunch of lines
        // TODO: better multi line writing/peristent handle
        assert(this.logFile.isSome());
        string path = this.logFile.get().path.getText();
        auto opened = sio.File(path);
        opened.writeln(s);
        opened.close();
      }
    }
  }
}

enum Stamp {
  Time, Order, None
}

struct UnixStamp {
  private alias TStamp = long;
  immutable(TStamp) time;

  static TStamp getTime() {
    return sds.Clock.currTime().toUnixTime!(TStamp);
  }

  pure private this(TStamp t) {
    this.time = t;
  }

  static public UnixStamp make() {
    return UnixStamp(UnixStamp.getTime());
  }

}

struct Log {
  private alias OStamp = dtp.Duo!(ulong, ulong, "category", "all");
  private alias LStamp = dtmm.MaybEith!(UnixStamp.TStamp, OStamp);

  invariant {
    if (this.stamp.isRight()) {
      OStamp os = this.stamp.getRight();
      assert(os.all >= os.category);
    }
  }

  immutable(string) log;
  immutable(LStamp) stamp;

  pure private this(string l, ulong c, ulong a) in (a >= c) {
    this.log = l;
    this.stamp = LStamp.makeRight(OStamp(c, a));
  }

  pure private this(string l, UnixStamp us) {
    this.log = l;
    this.stamp = LStamp.makeLeft(us.time);
  }

  pure private this(string l) {
    this.log = l;
    this.stamp = LStamp.makeNeither();
  }

  private pure string format(string cat) {
    if (this.checkStampType(Stamp.None)) {
      return ss.format("%s: %s", cat, this.log);
    } else if (this.checkStampType(Stamp.Time)) {
      return ss.format("%s (%u): %s", cat, this.stamp.getLeft(), this.log);
    } else {
      assert(this.checkStampType(Stamp.Order));
      OStamp ostamp = this.stamp.getRight();
      return ss.format("%s (%u %u): %s", cat, ostamp.all, ostamp.category, this.log);
    }
  }

  const pure bool checkStampType(Stamp exp) {
    final switch (exp) {
      case Stamp.None: return this.stamp.isNeither();
      case Stamp.Time: return this.stamp.isLeft();
      case Stamp.Order: return this.stamp.isRight();
    }

  }
}

class Logger(string[] CATS, bool ORDER = true) {
  static assert(CATS.length > 0);

  alias Logs = Log[][string];
  Logs logs;
  LogDestination[CATS.length] outs;
  Stamp[CATS.length] stampTags;
  static if (ORDER) {
    ulong[CATS.length] stamps;

    pure ulong orderSum() {
      ulong ret = stamps[0];
      for(ulong dex = 1; dex < CATS.length; dex++) {
        ret += stamps[dex];
      }

      return ret;
    }
  }

  invariant {
    assert(logs.length == CATS.length);


    foreach(i, cat; CATS) {
      foreach(log; this.logs[cat]) {
        assert(log.checkStampType(this.stampTags[i]));
      }
    }
  }

  private static pure Logs initLogs() {
    Logs ret;
    foreach (cat; CATS) {
      ret[cat] = [];
    }

    return ret;
  }

  private static Stamp[CATS.length] defaultStamps() {
    typeof(return) ret;

    Stamp dflt = Stamp.Time;

    version(unittest) dflt = Stamp.Order;

    for(ulong dex = 0; dex < CATS.length; dex++) {
      ret[dex] = dflt;
    }

    return ret;
  }

  this(LogDestination[CATS.length] dsts, Stamp[CATS.length] st = defaultStamps()) {
    this.logs = initLogs();
    this.outs = dsts;
    this.stampTags = st;
  }

  pure static bool isCategory(string cat) {
    alias CFG = das.SearchConfig!(string).ChangeMode!(das.SearchMode.Contains);
    return das.arraySearch!(CFG)(CATS, cat);
  }

  pure static private ulong getCatDex(string cat) out(d; d < CATS.length) {
    assert(isCategory(cat));
    alias CFG = das.SearchConfig!(string).ChangeMode!(das.SearchMode.Once);
    auto once = das.arraySearch!(CFG)(CATS, cat);
    assert(once.isSome());
    return once.get();
  }

  pure bool incOrder(string cat)() out(r; r == ORDER) {
    static assert(isCategory(cat));
    static if (ORDER) {
      enum ulong index = getCatDex(cat);
      stamps[index] += 1;
      return true;
    }
    return false;
  }

  private alias Conf = dt.Confirmation;

  pure Conf logln(string cat, Stamp tag)(string msg) if (tag != Stamp.Time) {
    enum ulong index = getCatDex(cat);
    if (this.stampTags[index] != tag) {
      return Conf.Failure;
    }

    static if (tag == Stamp.Order) {
      this.logs[cat] ~= Log(msg, stamps[index], this.orderSum());
    } else {
      this.logs[cat] ~= Log(msg);
    }

    incOrder!(cat)();
    return Conf.Success;
  }

  void logln(string cat, Stamp tag)(string msg) if (tag == Stamp.Time) {
    enum ulong index = getCatDex(cat);
    if (this.stampTags[index] != tag) {
      return Conf.Failure;
    }

    this.logs[cat] ~= Log(msg, UnixStamp.make());
  }

  private void flushln(ulong cat, string log) in (cat < CATS.length) {
    this.outs[cat].writeln(CATS[cat] ~ ": " ~ log);
  }
  private ulong _flushcat(ulong cat) in (cat < CATS.length) {
    const curcat = this.logs[CATS[cat]];
    ulong ret = curcat.length;
    foreach(log; curcat) {
      this.flushln(cat, log.log);
    }

    this.logs[CATS[cat]] = [];
    return ret;
  }

  ulong flush() {
    ulong ret = 0;
    foreach(i, cat; CATS) {
      ret += this._flushcat(i);
    }
    return ret;
  }

  ulong flushcat(string CAT)() {
    static assert(isCategory(CAT));
    alias CFG = das.SearchConfig!(string).ChangeMode!(das.SearchMode.Once);
    enum auto dex = das.arraySearch!(CFG)(CATS, CAT);
    static assert(dex.isSome());
    enum ulong index = dex.get();
    return this._flushcat(index);
  }

  version(unittest) {
    pure string[] reviewCat(string CAT)() {
      static assert(isCategory(CAT));
      string[] ret;

      foreach(log; this.logs[CAT]) {
        ret ~= log.format(CAT);
      }

      return ret;
    }
  }
}

unittest {
  import ss = std.string;
  enum string[] testCats = ["info", "debug", "err"];
  alias TestLog = Logger!(testCats);
  foreach(cat; testCats) {
    assert(TestLog.isCategory(cat));
  }

  //pragma(msg, "fix/enable tests"); // Disabled for commits


  alias LD = LogDestination;
  TestLog tl = new TestLog([LD.makeNone(), LD.makeNone(), LD.makeNone()], [Stamp.Order, Stamp.Order, Stamp.Order]);
  assert(tl.logln!("info", Stamp.Order)("info log msg"));

  //tl.logln!("invalid")("shouldn't compile");
  assert(tl.flushcat!("info")());


  assert(tl.logln!("info", Stamp.Order)("log msg 2"));
  assert(tl.logln!("info", Stamp.Order)("log 3"));

  string[] forReview = tl.reviewCat!("info")();
  assert(forReview[0] == "info (1 1): log msg 2");
  assert(forReview[1] == "info (2 2): log 3");

  assert(tl.flushcat!("debug")() == 0);

  assert(tl.logln!("err", Stamp.Order)("crashing"));
  assert(tl.reviewCat!("err")()[0] == "err (3 0): crashing");

  ulong flushed = tl.flush();
  assert(flushed == 3, ss.format("%d", flushed));

}
