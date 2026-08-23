module dulib.types.monads.result;

import dt = dulib.types;
import dtme = dulib.types.monads.either;
alias Eith = dtme.Either;

struct Result(O, E, dt.Mutability M) {
  private alias Data = Eith!(O, E, M);
  private alias Self = Result!(O, E, M);
  Data data;

  private pure this(Data d) {
    this.data = d;
  }

  public static pure Self okay(O o) {
    return Self(Data.left(o));
  }

  public static pure Self error(E e) {
    return Self(Data.right(e));
  }

  public pure bool isOkay() {return this.data.isLeft();}
  public pure bool isError() {return this.data.isRight();}

  public pure O getOkay()
      in(this.isOkay())
      {return this.data.getLeft();}

  public pure E getError()
      in(this.isError())
      {return this.data.getRight();}

  static if (dt.isMut!(M)()) {
    public void setOkay(O o) {
      this.data.setLeft(o);
    }

    public void setError(E e) {
      this.data.setRight(e);
    }
  }
}

unittest {
  alias Res = Result!(int, float, dt.Mut);

  Res r = Res.okay(2);
  assert(r.isOkay());
  assert(!r.isError());
  assert(r.getOkay() == 2);

  r.setError(1.0);
  assert(!r.isOkay());
  assert(r.isError());
  assert(r.getError() == 1.0);
}
