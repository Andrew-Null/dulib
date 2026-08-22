module dulib;

import sio = std.stdio;

public import dulib.logic;
public import dulib.paths;
public import dulib.optionals;
public import dulib.charify;


public pure nothrow uint parseUInt(string num) in(dulib.charify.isNumber(num)) {
  uint ret = 0;

  foreach (char c; num) {
    ret = (ret * 10) + (c - 48);
  }

  return ret;
}
