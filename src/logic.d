module dulib.logic;

pragma(inline, true);
bool imply(bool a, bool b) {
  if (a) return b;
  return true;
}

unittest {
  assert(imply(false, false));
  assert(imply(false, true));
  assert(!imply(true, false));
  assert(imply(true, true));
	 
}
