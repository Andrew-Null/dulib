module dulib.log;

import sio = std.stdio;
import sf = std.file;

import das = dulib.array.search;
import dtp = dulib.types.pair;
import dtf = dulib.types.filesystem;
import dtmo = dulib.types.monads.option;
import dl = dulib.logic;

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

class Logger(string[] CATS) {
  alias Logs = string[][string];
  Logs logs;
  LogDestination[CATS.length] outs;

  invariant {
    assert(logs.length == CATS.length);
  }

  private static pure Logs initLogs() {
    Logs ret;
    foreach (cat; CATS) {
      ret[cat] = [];
    }

    return ret;
  }

  this(LogDestination[CATS.length] dsts) {
    this.logs = initLogs();
    this.outs = dsts;
  }

  pure static bool isCategory(string cat) {
    alias CFG = das.SearchConfig!(string).ChangeMode!(das.SearchMode.Contains);
    return das.arraySearch!(CFG)(CATS, cat);
  }

  pure void logln(string cat)(string msg) {
    static assert(isCategory(cat));
    this.logs[cat] ~= msg;
  }

  private void flushln(ulong cat, string log) in (cat < CATS.length) {
    this.outs[cat].writeln(CATS[cat] ~ ": " ~ log);
  }
  private ulong _flushcat(ulong cat) in (cat < CATS.length) {
    const curcat = this.logs[CATS[cat]];
    ulong ret = curcat.length;
    foreach(log; curcat) {
      this.flushln(cat, log);
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
}

unittest {
  import ss = std.string;
  enum string[] testCats = ["info", "debug", "err"];
  alias TestLog = Logger!(testCats);
  foreach(cat; testCats) {
    assert(TestLog.isCategory(cat));
  }

  alias LD = LogDestination;
  TestLog tl = new TestLog([LD.makeNone(), LD.makeNone(), LD.makeNone()]);
  tl.logln!("info")("info log msg");
  //tl.logln!("invalid")("shouldn't compile");
  assert(tl.flushcat!("info")());


  tl.logln!("info")("log msg 2");
  tl.logln!("info")("log 3");

  assert(tl.flushcat!("debug")() == 0);

  tl.logln!("err")("crashing");

  ulong flushed = tl.flush();
  assert(flushed == 3, ss.format("%d", flushed));
}
