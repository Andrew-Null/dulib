module dulib.paths;

import sf = std.file;
import sp = std.path;
import sio = std.stdio;

import istr = dulib.types.identring;

 
 bool isFile(string fpath, bool doRes = false) {
  if (doRes) fpath = resolvePath(fpath);
  if (sf.exists(fpath)) return sf.isFile(fpath);
  return false;
}

bool isDir(string dpath, bool doRes = false) {
  if (doRes) dpath = resolvePath(dpath);
  if (sf.exists(dpath)) return sf.isDir(dpath);
  return false;
}

string resolvePath(string path) in(sp.isValidPath(path)) out(ret) {
  assert(sp.isValidPath(ret));
} do {
  version (Posix) {
    return sp.buildNormalizedPath(sp.expandTilde(path));
  }
  version (Windows) {
    return sp.buildNormalizedPath(path);
  }

  assert(0);
}

bool isResolved(string path) {
  return path == resolvePath(path);
}

alias PathStr = istr.CheckedStr!(sp.isValidPath);
alias ResolvedStr = istr.CheckedStr!(isResolved);
alias LocationStr = istr.CheckedStr!(sf.exists);
alias FileStr = istr.CheckedStr!(isFile);
alias DirStr = istr.CheckedStr!(isDir);

unittest {
  bool ert = false;
  version(linux) {
    //assert(isFile("~/.bash_profile") | isFile("~/.zprofile"));
    assert(PathStr.make("/this/is/a/nonsense/path").isSome());
    assert(LocationStr.make("/usr").isSome());
    assert(isFile("/etc/passwd"));
    assert(FileStr.make("/etc/passwd").isSome());
    assert(isDir("/home"));
    assert(DirStr.make("/home").isSome());
    assert(sp.isValidPath("~/.vimrc"));
    string resPath = "~/../../etc/passwd";
    sio.writeln("[common.d]::[resolvePath(" ~ resPath ~ ")]: " ~ resolvePath(resPath));
  }
}
