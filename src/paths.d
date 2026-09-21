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

bool isFileLink(string fl, bool dr = false) {
  return isFile(fl, dr) && isLink(fl, dr);
}

bool isDirLink(string fl, bool dr = false) {
  return isDir(fl, dr) && isLink(fl, dr);
}

bool isBrokenLink(string l, bool dr = false) {
  return isLink(l, dr) && !(isDir(l, dr) || isFile(l, dr));
}

bool isUnbrokenLink(string l, bool dr = false) {
  return !isBrokenLink(l, dr);
}

string resolvePath(bool ABS = true)(string path, lazy string base = sf.getcwd) in(sp.isValidPath(path)) out(ret) {
  assert(sp.isValidPath(ret));
} do {
  version (Posix) {
    static if (ABS) {
      return sp.buildNormalizedPath(sp.expandTilde(path));
    } else {
      string cat = base; //careful of lazy, "call" once

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

alias Path = istr.CheckedStr!(sp.isValidPath);
alias ResolvedPath = istr.CheckedStr!(isResolved);
alias LocationPath = istr.CheckedStr!(sf.exists);
alias FilePath = istr.CheckedStr!(isFile);
alias DirPath = istr.CheckedStr!(isDir);
alias LinkPath = istr.CheckedStr!(isLink);
alias SymlinkPath = LinkPath;
alias UnbrokenLinkPath = istr.CheckedStr!(isUnbrokenLink);

struct FSEntry(dt.Mutability M = dt.Mutability.Immutable) {
  alias Entry = dtmt.Trither!(FilePath, DirPath, LinkPath, M);
  Entry entry;

  this(FilePath fp) {
    this.entry = Entry.left(fp);
  }

  this(DirPath dp) {
    this.entry = Entry.middle(dp);
  }

  this(LinkPath lp) {
    this.entry = Entry.right(lp);
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

    // MUST be first,
    // symlinks can be confused for what they are linked to
    auto lp = LinkPath.make(entry.getText());
    if (lp.isSome()) {
      return Con.make(Self(lp.get()));
    }

    //Not sure which is more likely file or directory, going to guess files
    auto fp = FilePath.make(entry.getText());
    if (fp.isSome()) {
      return Con.make(Self(fp.get()));
    }

    auto dp = DirPath.make(entry.getText());
    if (dp.isSome()) {
      return Con.make(Self(dp.get()));
    }

    return Con.make();
  }

  static Self make(FilePath fp) {
    return Self(fp);
  }
  static Self make(DirPath dp) {
    return Self(dp);
  }
  static Self make(LinkPath lp) {
    return Self(lp);
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
    return this.entry.getLeft();
  }

  public DirPath getDirectory() in(this.isDirectory()) {
    return this.entry.getMiddle();
  }

  public LinkPath getLink() in(this.isLink()) {
    return this.entry.getRight();
  }

  public string getPath() {
    if (this.isFile()) return this.getFile().getText();
    if (this.isDirectory()) return this.getDirectory().getText();
    assert(this.isLink());
    return this.getLink().getText();
  }
}

FSEntry!(M).Con followLink(dt.Mutability M = dt.Mutability.Immutable)(LinkPath lp) {
  string link = lp.getText();
  return FSEntry!(M).make(
      resolvePath!(false)(
          sf.readLink(
              link), sp.dirName(link)));
}

FSEntry!(M)[] directoryContents
(dt.Mutability M = dt.Mutability.Immutable, sf.SpanMode SPAN = sf.SpanMode.shallow, bool FOLLOW = false)(DirPath dp) {
  auto contents = sf.dirEntries(dp.getText(), SPAN, FOLLOW);
  alias Ret = FSEntry!(M);
  Ret[] ret = [];
  foreach (entry; contents) {
    auto temp = Ret.make(entry);
    if (temp.isSome()) ret ~= temp.get();
  }

  return ret;
}


unittest {
  enum bool PRINT = true;
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

    if (PRINT) {
      sio.writeln("[paths.d]::[resolvePath(" ~ resPath ~ ")]: " ~ resolvePath(resPath));

      auto home = DirPath.make(resolvePath("~"));
      assert(home.isSome());
      auto inhome = directoryContents(home.get());
      foreach (mem; inhome) {
        string kind = "";
        if (mem.isFile()) kind = "File";
        if (mem.isDirectory()) kind = "Dir";
        if (mem.isLink()) kind = "Symlink";
        sio.writeln(kind ~ " : " ~ mem.getPath());
        if (mem.isLink()) {
          auto followed = followLink(mem.getLink());
          if (followed.isSome()) {
            sio.writeln("Followed link: " ~ followed.get().getPath());
          } else sio.writeln(mem.getPath() ~ " is a broken link");
        }
      }
    }

  }

  assert("ab//cd"[2..4] == "//");
  assert("abc"[0..3-1]=="ab");
}
