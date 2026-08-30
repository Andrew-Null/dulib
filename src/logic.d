module dulib.logic;

pragma(inline, true);
bool imply(bool a, bool b) {
  if (a) return b;
  return true;
}

T truthy(T)(bool b, T t, T f) {
  return (b * t) + ((1 - b) * f);
}

unittest {
  assert(imply(false, false));
  assert(imply(false, true));
  assert(!imply(true, false));
  assert(imply(true, true));
	 
}
