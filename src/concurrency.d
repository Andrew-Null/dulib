import sc = std.concurrency;

import dtmo = dulib.types.monads.option;

struct Tiddress(dtmo.Option!(bool) RTID = dtmo.Option!(bool).make()) {
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
  alias Tdrs = Tiddress!();
  Tdrs t = Tdrs(sc.thisTid(), sc.thisTid());
}
