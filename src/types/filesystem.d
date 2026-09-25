module dulib.types.filesystem;

import sf = std.file;
import sp = std.path;
import sio = std.stdio;

import istr = dulib.types.identring;
import dt = dulib.types;
import dtmt = dulib.types.monads.trither;
import dtmo = dulib.types.monads.option;
import dp = dulib.paths;
import dtmm = dulib.types.monads.maybeith;

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
  private alias Self = SymLink!(M);
  alias Con = dtmo.Option!(Self);
  alias Link = dtmt.Trither!(FileLinkPath, DirLinkPath, BrokenLinkPath);
  Link link;

  pure string linkPath() {
    if (link.isLeft()) return link.getLeft().getText();
    if (link.isMiddle()) return link.getMiddle().getText();
    assert(link.isRight());
    return link.getRight().getText();
  }

  dtmo.Option!(string) targetPath() in(!link.isRight()) {
    alias Ret = typeof(return);

    auto lpo = LinkPath.make(this.linkPath());
    if (lpo.isNone()) return Ret.make();

    auto fseo = dp.followLink(lpo.get());
    if (fseo.isNone()) return Ret.make();

    return Ret.make(fseo.get().getPath());
  }

  pure bool isFile() {
    return link.isLeft();
  }

  pure bool isDir() {
    return link.isMiddle();
  }

  pure bool isBroken() {
    return link.isRight();
  }

  this(FileLinkPath flp) {
    this.link = Link.makeLeft(flp);
  }

  this(DirLinkPath dlp) {
    this.link = Link.makeMiddle(dlp);
  }

  this(BrokenLinkPath blp) {
    this.link = Link.makeRight(blp);
  }

  static Con make(string ls) {
    auto lp = LinkPath.make(ls);
    if (lp.isNone()) {
      return Con.make();
    }
    return Self.make(lp.get());
  }

  static Con make(LocationPath lp) {
    auto ln = LinkPath.make(lp.getText());
    if (ln.isNone()) return Con.make();
    return Self.make(ln.get());
  }
  static Con make(LinkPath lp) {
    if (!lp.doubleCheck()) {
      return Con.make();
    }

    const txt = lp.getText();

    // simpler to check this one first
    auto blp = BrokenLinkPath.make(txt);
    if (blp.isSome()) {
      return Con.make(Self(blp.get()));
    }

    auto dlp = DirLinkPath.make(txt);
    if (dlp.isSome()) {
      return Con.make(Self(dlp.get()));
    }

    auto flp = FileLinkPath.make(txt);
    if (flp.isSome()) {
      return Con.make(Self(flp.get()));
    }

    return Con.make();
  }
}

struct FSEntry(dt.Mutability M = dt.Mutability.Immutable) {
  alias Entry = dtmt.Trither!(FilePath, DirPath, LinkPath, M);
  Entry entry;

  this(FilePath fp) {
    this.entry = Entry.makeLeft(fp);
  }

  this(DirPath dp) {
    this.entry = Entry.makeMiddle(dp);
  }

  this(LinkPath lp) {
    this.entry = Entry.makeRight(lp);
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

  public dtmo.Option!(LocationPath) getLocation() {
    return LocationPath.make(this.getPath());
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
          //auto followed = dp.followLink(mem.getLink());
          //if (followed.isSome()) {
          //  sio.writeln("Followed link: " ~ followed.get().getPath());
          //} else sio.writeln(mem.getPath() ~ " is a broken link");

          auto slo = SymLink!(dt.IMut).make(mem.getLink());
          assert(slo.isSome());
          auto sl = slo.get();
          if (sl.isFile()) sio.writeln(sl.linkPath() ~ " is a link to a file " ~ sl.targetPath().get());
          if (sl.isDir()) sio.writeln(sl.linkPath() ~ " is a link to a directory " ~ sl.targetPath().get());
          if (sl.isBroken()) sio.writeln(sl.linkPath() ~ " is a broken link that leads no where");

        }
      }
    }

  }

  assert("ab//cd"[2..4] == "//");
  assert("abc"[0..3-1]=="ab");
}
