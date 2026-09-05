module dulib.types.monads.maybeith;

import dt = dulib.types;

private enum Tag {
  Left, Neither, Right
}

private union Eion(L, R, dt.Mutability MU) {
  dt.AsMut!(L, MU).Out left;
  dt.AsMut!(R, MU).Out right;
}

struct MaybEith(L, R, dt.Mutability MU = dt.IMut) {
  dt.AsMut!(Tag, MU).Out tag;
  Eion!(L, R, MU) data;
  private alias Self = MaybEith!(L, R, MU);

  private pure this(L l, Tag tag) in(tag == Tag.Left) {
    this.tag = Tag.Left;
    this.data.left = l;
  }

  private pure this(R r) {
    this.tag = Tag.Right;
    this.data.right = r;
  }

  private pure this(Tag t) in (t == Tag.Neither) {
    this.tag = t;
  }

  public static pure Self left(L l) {
    return Self(l, Tag.Left);
  }

  public static pure Self right(R r) {
    return Self(r);
  }

  public static pure Self neither() {
    return Self(Tag.Neither);
  }

  public pure bool isLeft() {
    return this.tag == Tag.Left;
  }

  public pure bool isRight() {
    return this.tag == Tag.Right;
  }

  public pure bool isNeither() {
    return this.tag == Tag.Neither;
  }

  public pure L getLeft() in(this.isLeft()) {
    return this.data.left;
  }

  public pure R getRight() in(this.isRight()) {
    return this.data.right;
  }

  static if (dt.isMut!(MU)()) {
    public void setLeft(L l) {
      this.data.left = l;
      this.tag = Tag.Left;
    }

    public void setNeither() {
      this.tag = Tag.Neither;
    }

    public void setRight(R r) {
      this.data.right = r;
      this.tag = Tag.Right;
    }
  }

}

unittest {
  alias Eith = MaybEith!(int, float, dt.Mut);

  Eith e = Eith.left(2);
  assert(e.isLeft());
  assert(!e.isNeither());
  assert(!e.isRight());
  assert(e.getLeft() == 2);

  e.setNeither();
  assert(!e.isLeft());
  assert(e.isNeither());
  assert(!e.isRight());

  e.setRight(1.0);
  assert(!e.isLeft());
  assert(!e.isNeither());
  assert(e.isRight());
  assert(e.getRight() == 1.0);
}
