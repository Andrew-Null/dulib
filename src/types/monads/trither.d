module dulib.types.monads.trither;

import dt = dulib.types;

private enum Tag {
  Left, Middle, Right
}

private union Eion(L, M, R, dt.Mutability MU) {
  dt.AsMut!(L, MU).Out left;
  dt.AsMut!(M, MU).Out middle;
  dt.AsMut!(R, MU).Out right;
}

struct Trither(L, M, R, dt.Mutability MU = dt.IMut) {
  dt.AsMut!(Tag, MU).Out tag;
  Eion!(L, M, R, MU) data;
  private alias Self = Trither!(L, M, R, MU);

  private pure this(L l, Tag tag) in(tag == Tag.Left) {
    this.tag = Tag.Left;
    this.data.left = l;
  }

  private pure this(R r) {
    this.tag = Tag.Right;
    this.data.right = r;
  }

  private pure this(M m, bool b) in(b) {
    this.tag = Tag.Middle;
    this.data.middle = m;
  }

  public static pure Self left(L l) {
    return Self(l, Tag.Left);
  }

  public static pure Self right(R r) {
    return Self(r);
  }

  public static pure Self middle(M m) {
    return Self(m, true);
  }

  public pure bool isLeft() {
    return this.tag == Tag.Left;
  }

  public pure bool isRight() {
    return this.tag == Tag.Right;
  }

  public pure bool isMiddle() {
    return this.tag == Tag.Middle;
  }

  public pure L getLeft() in(this.isLeft()) {
    return this.data.left;
  }

  public pure M getMiddle() in(this.isMiddle()) {
    return this.data.middle;
  }

  public pure R getRight() in(this.isRight()) {
    return this.data.right;
  }

  static if (dt.isMut!(MU)()) {
    public void setLeft(L l) {
      this.data.left = l;
      this.tag = Tag.Left;
    }

    public void setMiddle(M m) {
      this.data.middle = m;
      this.tag = Tag.Middle;
    }

    public void setRight(R r) {
      this.data.right = r;
      this.tag = Tag.Right;
    }
  }

}

unittest {
  alias Eith = Trither!(int, bool, float, dt.Mut);

  Eith e = Eith.left(2);
  assert(e.isLeft());
  assert(!e.isMiddle());
  assert(!e.isRight());
  assert(e.getLeft() == 2);

  e.setMiddle(true);
  assert(!e.isLeft());
  assert(e.isMiddle());
  assert(!e.isRight());
  assert(e.getMiddle());

  e.setRight(1.0);
  assert(!e.isLeft());
  assert(!e.isMiddle());
  assert(e.isRight());
  assert(e.getRight() == 1.0);
}
