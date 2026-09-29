import sc = std.concurrency;

import dtmo = dulib.types.monads.option;

private alias HasRet = dtmo.Option!(bool);
struct Tiddress(HasRet RTID = HasRet.make()) {
  sc.Tid src, dst;
  alias Self = Tiddress!(RTID);
  static if (RTID.isNone()) {
    alias RTid = dtmo.Option!(sc.Tid);
    RTid ret;

    pure this(sc.Tid s, sc.Tid d, sc.Tid r) {
      this.src = s;
      this.dst = d;
      this.ret = RTid.make(r);
    }

    pure this(sc.Tid s, sc.Tid d) {
      this.src = s;
      this.dst = d;
      this.ret = RTid.make();
    }

  } else static if (RTID.get()) {
    sc.Tid ret;
    pure this(sc.Tid s, sc.Tid d, sc.Tid r) {
      this.src = s;
      this.dst = d;
      this.ret = r;
    }
  } else {
    pure this(sc.Tid s, sc.Tid d) {
      this.src = s;
      this.dst = d;
    }
  }
}

unittest {
  sc.Tid here = sc.thisTid();
  alias None = Tiddress!();
  None two = None(here, here);
  None three = None(here, here, here);

  alias True = Tiddress!(HasRet.make(true));
  True tru = True(here, here, here);

  alias False = Tiddress!(HasRet.make(false));
  False fls = False(here, here);
}
