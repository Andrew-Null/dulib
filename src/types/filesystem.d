module dulib.types.filesystem;

import sf = std.file;
import sp = std.path;

import istr = dulib.types.identring;
import dt = dulib.types;
import dtmt = dulib.types.monads.trither;
import dtmo = dulib.types.monads.option;
import dp = dulib.paths;

alias Path = istr.CheckedStr!(sp.isValidPath);
alias ResolvedPath = istr.CheckedStr!(dp.isResolved);
alias LocationPath = istr.CheckedStr!(sf.exists);
alias FilePath = istr.CheckedStr!(dp.isFile);
alias DirPath = istr.CheckedStr!(dp.isDir);
alias LinkPath = istr.CheckedStr!(dp.isLink);
alias SymlinkPath = LinkPath;
alias UnbrokenLinkPath = istr.CheckedStr!(dp.isUnbrokenLink);
alias FileLinkPath = istr.CheckedStr!(dp.isFileLink);
alias DirLinkPath = istr.CheckedStr!(dp.isDirLink);
alias BrokenLinkPath = istr.CheckedStr!(dp.isBrokenLink);

struct SymLink(dt.Mutability M = dt.Mutability.Immutable) {
  alias Link = dtmt.Trither!(FileLinkPath, DirLinkPath, BrokenLinkPath);
  Link link;
}

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

unittest {
  import sio = std.stdio;

  enum bool PRINT = true;
  bool ert = false;
  version(linux) {
    //assert(isFile("~/.bash_profile") | isFile("~/.zprofile"));
    assert(Path.make("/this/is/a/nonsense/path").isSome());
    assert(LocationPath.make("/usr").isSome());
    assert(FilePath.make("/etc/passwd").isSome());
    assert(DirPath.make("/home").isSome());
    string resPath = "~/../../etc/passwd";

    if (PRINT) {
      sio.writeln("[paths.d]::[resolvePath(" ~ resPath ~ ")]: " ~ dp.resolvePath(resPath));

      auto home = DirPath.make(dp.resolvePath("~"));
      assert(home.isSome());
      auto inhome = dp.directoryContents(home.get());
      foreach (mem; inhome) {
        string kind = "";
        if (mem.isFile()) kind = "File";
        if (mem.isDirectory()) kind = "Dir";
        if (mem.isLink()) kind = "Symlink";
        sio.writeln(kind ~ " : " ~ mem.getPath());
        if (mem.isLink()) {
          auto followed = dp.followLink(mem.getLink());
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
