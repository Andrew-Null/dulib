module dulib.types.monads.either;

import dt = dulib.types;

private enum EiTag {
  Left, Right
}

private union Eion(L, R, dt.Mutability M) {
  dt.AsMut!(L, M).Out left;
  dt.AsMut!(R, M).Out right;
}

struct Either(L, R, dt.Mutability M = dt.IMut) {
  dt.AsMut!(EiTag, M).Out tag;
  Eion!(L, R, M) data;
  private alias Self = Either!(L, R, M);

  private pure this(L l, EiTag tag) in(tag == EiTag.Left) {
    this.tag = EiTag.Left;
    this.data.left = l;
  }

  private pure this(R r) {
    this.tag = EiTag.Right;
    this.data.right = r;
  }

  public static pure Self makeLeft(L l) {
    return Self(l, EiTag.Left);
  }

  public static pure Self makeRight(R r) {
    return Self(r);
  }

  public pure bool isLeft() {
    return this.tag == EiTag.Left;
  }

  public pure bool isRight() out(r; r != this.isLeft()) {
    return this.tag == EiTag.Right;
  }

  public pure L getLeft() in(this.isLeft()) {
    return this.data.left;
  }

  public pure R getRight() in(this.isRight()) {
    return this.data.right;
  }

  static if (dt.isMut!(M)()) {
    public void setLeft(L l) {
      this.data.left = l;
      this.tag = EiTag.Left;
    }

    public void setRight(R r) {
      this.data.right = r;
      this.tag = EiTag.Right;
    }
  }

}

unittest {
  alias Eith = Either!(int, float, dt.Mut);

  Eith e = Eith.makeLeft(2);
  assert(e.isLeft());
  assert(!e.isRight());
  assert(e.getLeft() == 2);

  e.setRight(1.0);
  assert(!e.isLeft());
  assert(e.isRight());
  assert(e.getRight() == 1.0);
}
