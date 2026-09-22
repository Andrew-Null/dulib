module dulib.paths;

import sf = std.file;
import sp = std.path;

import istr = dulib.types.identring;
import dt = dulib.types;
import dtmt = dulib.types.monads.trither;
import dtmo = dulib.types.monads.option;
import dtf = dulib.types.filesystem;

 
@safe bool isFile(string fpath, bool doRes = false) {
  if (doRes) fpath = resolvePath(fpath);
  if (sf.exists(fpath)) return sf.isFile(fpath);
  return false;
}

@safe bool isDir(string dpath, bool doRes = false) {
  if (doRes) dpath = resolvePath(dpath);
  if (sf.exists(dpath)) return sf.isDir(dpath);
  return false;
}

@safe bool isLink(string lpath, bool doRes = false) {
  if (doRes) lpath = resolvePath(lpath);
  if (sf.exists(lpath)) return sf.isSymlink(lpath);
  return false;
}
alias isSymlink = isLink;

@safe bool isFileLink(string fl, bool dr = false) {
  return isFile(fl, dr) && isLink(fl, dr);
}

@safe bool isDirLink(string fl, bool dr = false) {
  return isDir(fl, dr) && isLink(fl, dr);
}

@safe bool isBrokenLink(string l, bool dr = false) {
  return isLink(l, dr) && !(isDir(l, dr) || isFile(l, dr));
}

@safe bool isUnbrokenLink(string l, bool dr = false) {
  return !isBrokenLink(l, dr);
}

string resolvePath(bool ABS = true)(string path, lazy string base = sf.getcwd) in(sp.isValidPath(path)) out(ret) {
  assert(sp.isValidPath(ret));
} do {
  version (Posix) {
    static if (ABS) {
      return sp.buildNormalizedPath(sp.expandTilde(path));
    } else {
      string cat = base; //careful of lazy, eval once

      //might be worth extracting
      if ((cat[cat.length - 1] == '/') && (path[0] == '/')) {
          cat ~= path[1..$];
      } else if ((cat[cat.length -1] != '/') && (path[0] !='/')) {
          cat = cat ~ "/" ~ path;
      } else {
        assert((cat[cat.length -1] == '/') ^ (path[0] =='/'));
        cat ~= path;
      }

      return sp.buildNormalizedPath(cat);
    }
  }
  version (Windows) {
    return sp.buildNormalizedPath(path);
  }

  assert(0);
}

bool isResolved(string path) {
  return path == resolvePath(path);
}

dtf.FSEntry!(M).Con followLink(dt.Mutability M = dt.Mutability.Immutable)(dtf.LinkPath lp) {
  string link = lp.getText();
  return dtf.FSEntry!(M).make(
      resolvePath!(false)(
          sf.readLink(
              link), sp.dirName(link)));
}

dtf.FSEntry!(M)[] directoryContents
(dt.Mutability M = dt.Mutability.Immutable, sf.SpanMode SPAN = sf.SpanMode.shallow, bool FOLLOW = false)(dtf.DirPath dp) {
  auto contents = sf.dirEntries(dp.getText(), SPAN, FOLLOW);
  alias Ret = dtf.FSEntry!(M);
  Ret[] ret = [];
  foreach (entry; contents) {
    auto temp = Ret.make(entry);
    if (temp.isSome()) ret ~= temp.get();
  }

  return ret;
}

unittest {
  version(linux) {
    assert(isFile("/etc/passwd"));
    assert(isDir("/home"));
    assert(sp.isValidPath("~/.vimrc"));
  }
}
