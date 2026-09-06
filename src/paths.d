module dulib.paths;

import sf = std.file;
import sp = std.path;
import sio = std.stdio;

import istr = dulib.types.identring;
import dt = dulib.types;
import dtmt = dulib.types.monads.trither;
import dtmo = dulib.types.monads.option;

 
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

bool isLink(string lpath, bool doRes = false) {
  if (doRes) lpath = resolvePath(lpath);
  if (sf.exists(lpath)) return sf.isSymlink(lpath);
  return false;
}
alias isSymlink = isLink;

string resolvePath(bool ABS = true)(string path, lazy string base = sf.getcwd) in(sp.isValidPath(path)) out(ret) {
  assert(sp.isValidPath(ret));
} do {
  version (Posix) {
    static if (ABS) {
      return sp.buildNormalizedPath(sp.expandTilde(path));
    } else {
      string cat = base; //careful of lazy, call once

      //might be worth extracting
      if ((cat[cat.length -1] == "/") && (path[0] =="/")) {
          cat ~= path[1..$];
      } else if ((cat[cat.length -1] != "/") && (path[0] !="/")) {
          cat = cat ~ "/" ~ path;
      } else {
        assert((cat[cat.length -1] == "/") ^ (path[0] =="/"));
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

alias Path = istr.CheckedStr!(sp.isValidPath);
alias ResolvedPath = istr.CheckedStr!(isResolved);
alias LocationPath = istr.CheckedStr!(sf.exists);
alias FilePath = istr.CheckedStr!(isFile);
alias DirPath = istr.CheckedStr!(isDir);
alias LinkPath = istr.CheckedStr!(isLink);
alias SymlinkPath = LinkPath;

struct FSEntry(dt.Mutability M = dt.Mutability.Immutable) {
  alias Entry = dtmt.Trither!(FilePath, DirPath, LinkPath, M);
  Entry entry;

  this(FilePath fp) {
    this.entry = Entry.Left(fp);
  }

  this(DirPath dp) {
    this.entry = Entry.Middle(dp);
  }

  this(LinkPath lp) {
    this.entry = Entry.Right(lp);
  }

  alias Self = FSEntry!(M);
  alias Con = dtmo.Option!(Self);

  static Con make(string path) {
    auto lp = LocationPath.make(path);
    if (lp.isNone()) return Con.make();
    return Self.make(lp.get());
  }

  static Con make(LocationPath entry) {
    if (!entry.doubleCheck()) {
      return Con.make();
    }

    // Hotter than links, but files and directories are a toss up
    // So do this first as ignorance means I need to test links before files
    auto dp = DirPath.make(entry.getText());
    if (fp.isSome()) {
      return Con.make(this(dp.get()));
    }

    //Not sure if links also count as files so check this cold path first
    auto lp = LinkPath.make(entry.getText());
    if (lp.isSome()) {
      return Con.make(this(lp.get()));
    }

    // Fairly certain branch prediction is destroyed by this point
    auto fp = FilePath.make(entry.getText());
    if (fp.isSome()) {
      return Con.make(this(fp.get()));
    }

    return Con.make();
  }

  static Self make(FilePath fp) {
    return this(fp);
  }
  static Self make(DirPath dp) {
    return this(dp);
  }
  static Self make(LinkPath lp) {
    return this(lp);
  }

  public bool isFile() {
    return this.entry.isLeft();
  }

  public bool isDirectory() {
    return this.entry.isMiddle();
  }

  public bool isLink() {
    return this.entry.isRight();
  }

  public FilePath getFile() in(this.isFile()) {
    return this.getLeft();
  }

  public DirPath getDirectory() in(this.isDirectory()) {
    return this.getMiddle();
  }

  public LinkPath getLink() in(this.isLink()) {
    return this.getRight();
  }
}

FSEntry!(M).Con followLink(dt.Mutability M = dt.Mutability.Immutable)(LinkPath lp) {
  return FSEntry!(M).make(sf.readlink(lp.getText()));
}

unittest {
  bool ert = false;
  version(linux) {
    //assert(isFile("~/.bash_profile") | isFile("~/.zprofile"));
    assert(Path.make("/this/is/a/nonsense/path").isSome());
    assert(LocationPath.make("/usr").isSome());
    assert(isFile("/etc/passwd"));
    assert(FilePath.make("/etc/passwd").isSome());
    assert(isDir("/home"));
    assert(DirPath.make("/home").isSome());
    assert(sp.isValidPath("~/.vimrc"));
    string resPath = "~/../../etc/passwd";
    sio.writeln("[common.d]::[resolvePath(" ~ resPath ~ ")]: " ~ resolvePath(resPath));
  }

  assert("ab//cd"[2..4] == "//");
  assert("abc"[0..3-1]=="ab");
}
