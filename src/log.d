module dulib.log;

import sio = std.stdio;
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

private:

private alias LO = LogOut;
enum LogOutput : LO {
  StdOut = LO.StdOut, StdErr = LO.StdErr, None = LO.None
}

private enum LogOut {
  File, StdOut, StdErr, None
}

enum WriteMode : string {
  Overrite = "w", Append = "a", Write = "w+", Create = "+"
}

struct LogDestination {
  immutable(LO) tag;
  alias LFile = immutable(dtmo.Option!(dtf.Path));
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
}

class Logger(string[] CATS) {
  alias Logs = string[][string];
  Logs logs;

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

  this() {
    logs = initLogs();
  }

  pure static bool isCategory(string cat) {
    alias CFG = das.SearchConfig!(string).ChangeMode!(das.SearchMode.Contains);
    return das.arraySearch!(CFG)(CATS, cat);
  }

  pure void logln(string cat)(string msg) {
    static assert(isCategory(cat));
    logs[cat] ~= msg;
  }

  //private void flushln(string cat, string log)
  //private void flushcat
  //private void flush
}

unittest {
  enum string[] testCats = ["info", "debug", "err"];
  alias TestLog = Logger!(testCats);
  foreach(cat; testCats) {
    assert(TestLog.isCategory(cat));
  }

  TestLog tl = new TestLog();
  tl.logln!("info")("info log msg");
  //tl.logln!("invalid")("shouldn't compile");
}
