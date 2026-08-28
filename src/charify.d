module dulib.charify;

import opts = dulib.types.monads.option;

pragma(inline, true);
nothrow pure bool isLower(char c) {
  return ('a' <= c) && (c <= 'z');
}

pragma(inline, true);
nothrow pure bool isUpper(char c) {
  return ('A' <= c) && (c <= 'Z');
}

pragma(inline, true);
nothrow pure bool isLetter(char c) {
  return isLower(c) || isUpper(c);
}

pragma(inline);
nothrow pure bool isLower(string s) {
  foreach(c; s) {
    if (!isLower(c)) return false;
  }
  return true;
}

pragma(inline);
nothrow pure bool isUpper(string s) {
  foreach(c; s) {
    if (!isUpper(c)) return false;
  }
  return true;
}


pragma(inline, true);
nothrow pure bool isNumber(char c) {
  return ('0' <= c) && (c <= '9');
}

pragma(inline);
nothrow pure bool isAlpha(string s) {
  foreach(char c; s) {
    if (!isLetter(c)) return false;
  }
  return true;
}

pragma(inline);
nothrow pure bool isAlphaNumeric(string s) {
  foreach(c; s) {
    if (!(isLetter(c) || isNumber(c))) return false;
  }
  return true;
}

pragma(inline);
nothrow pure bool isNumber(string s) {
  foreach(c; s) {
    if (!isNumber(c)) return false;
  }
  return true;
}

pragma(inline, true);
nothrow pure bool isSimple(char c) {
  // letters numbers underscore
    if (isLetter(c)) return true;
    if (isNumber(c)) return true;
    if (c == '_') return true;
    return false;
}

pragma(inline);
nothrow pure bool isSimple(string s) {
  // letters numbers underscore

  foreach (c; s) {
    if (!isSimple(c)) return false;
  }
  return true;
}

pragma(inline, true);
nothrow pure bool isWhitespace(char c) {
    return c == ' ' || c == '\n' || c == '\r';
}

pragma(inline);
nothrow pure bool isWhitespace(string s) {
  foreach (c; s) {
    if (!isWhitespace(c)) return false;
  }
  return true;
}


unittest {
  assert(isAlpha("abcXYZ"));
  assert(isAlpha("a"));
  assert(isAlpha(""));
  assert(isLower("abcxyz"));
  assert(isUpper("ABCXYZ"));
  assert(isAlphaNumeric("abcXYZ123"));
  assert(!isAlpha("123"));

  assert(isSimple('_'));
  assert(isSimple('r'));
  assert(isSimple('1'));
}
