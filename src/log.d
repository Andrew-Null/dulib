module dulib.log;

import sio = std.stdio;
import das = dulib.array.search;
import dtp = dulib.types.pair;

void errPrint(string txt) {
  sio.stderr.write(txt);
}

void errPrintln(string txt) {
  sio.stderr.writeln(txt);
}

private:

enum LogOutput {
  File, StdOut, StdErr, None
}

struct LogDestination {
  alias LO = LogOutput;
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
