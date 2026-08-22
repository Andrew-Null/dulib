module dulib.log;

import sio = std.stdio;

void errPrint(string txt) {
  version (unittest) {
    return;
  }

  sio.write(txt);
}

void errPrintln(string txt) {
  version (unittest) {
    return;
  }

  sio.writeln(txt);
}
