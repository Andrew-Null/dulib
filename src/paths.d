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

alias Path = istr.CheckedStr!(sp.isValidPath);
alias ResolvedPath = istr.CheckedStr!(isResolved);
alias LocationPath = istr.CheckedStr!(sf.exists);
alias FilePath = istr.CheckedStr!(isFile);
alias DirPath = istr.CheckedStr!(isDir);

unittest {
  bool ert = false;
  version(linux) {
    //assert(isFile("~/.bash_profile") | isFile("~/.zprofile"));
    assert(Path.make("/this/is/a/nonsense/path").some());
    assert(LocationPath.make("/usr").some());
    assert(isFile("/etc/passwd"));
    assert(FilePath.make("/etc/passwd").some());
    assert(isDir("/home"));
    assert(DirPath.make("/home").some());
    assert(sp.isValidPath("~/.vimrc"));
    string resPath = "~/../../etc/passwd";
    sio.writeln("[common.d]::[resolvePath(" ~ resPath ~ ")]: " ~ resolvePath(resPath));
  }
}
