module dulib;

import sio = std.stdio;
import dc = dulib.charify;

public pure nothrow uint parseUInt(string num) in(dc.isNumber(num)) {
  uint ret = 0;

  foreach (char c; num) {
    ret = (ret * 10) + (c - 48);
  }

  return ret;
}

