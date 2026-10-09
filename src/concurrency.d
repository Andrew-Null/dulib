import sc = std.concurrency;

import dtmo = dulib.types.monads.option;
import dt = dulib.types;

private alias HasRet = dtmo.Option!(bool);
private immutable HasRet DefHR = HasRet.make();

alias recieve(T, HasRet R = DefHR) = sc.receiveOnly!(Message!(T, R));

struct Message(T, HasRet R = DefHR) {
  alias Self = Message!(T, R);
  alias Tddr = Tiddress!(R);
  immutable Tddr address;
  immutable T msg;

  private this(T m, Tddr a) {
    this.address = cast(immutable(Tddr)) a;
    this.msg = cast(immutable(T)) m;
  }

  public static void send(Tddr a, T msg) {
    sc.send(cast(sc.Tid) a.dst, Self(msg, a));
  }
}

struct Tiddress(HasRet RTID = HasRet.make()) {
  immutable sc.Tid src, dst;
  alias Cast = immutable(sc.Tid);
  alias Self = Tiddress!(RTID);
  static if (RTID.isNone()) {
    alias RTid = dtmo.Option!(sc.Tid);
    RTid ret;

    pure this(sc.Tid s, sc.Tid d, sc.Tid r) {
      this.src = cast(Cast) s;
      this.dst = cast(Cast) d;
      this.ret = RTid.make(r);
    }

    pure this(sc.Tid s, sc.Tid d) {
      this.src = cast(Cast) s;
      this.dst = cast(Cast) d;
      this.ret = RTid.make();
    }

    pure dtmo.Option!(Tiddress!(HasRet.make(B))) tryHarden(bool B)() {
      alias Neo = Tiddress!(HasRet.make(B));
      alias Ret = typeof(return);
      if (this.ret.isSome() ^ B) {
        return Ret.make();
      }
      assert(this.ret.isSome() == B);
      static if (B) {
        assert(ret.isSome());
        return Ret.make(Neo(cast(sc.Tid) this.src, cast(sc.Tid) this.dst, cast(sc.Tid) this.ret.get()));

      } else {
        assert(ret.isNone());
        return Ret.make(Neo(cast(sc.Tid) this.src, cast(sc.Tid) this.dst));
      }



    }

    static Self fromHere(bool R, bool A = false)
    (sc.Tid dst, sc.Tid ret = sc.thisTid) in {
      static if (!R) {
        assert(ret == sc.thisTid);
      } else {
        // src is default return, if you going to the trouble of
        // specifying why would you be specifying the src?
        // Well can override if need be
        assert(A || ret != sc.thisTid);
      }
    } do {
      static if (R) {
        return Self(sc.thisTid, dst, ret);
      }
      return Self(sc.thisTid, dst);
    }

    pure sc.Tid returnTid() {
      alias Ret = typeof(return);
      if (this.ret.isSome()) {
        return cast(Ret) this.ret.get();
      }
      return cast(Ret) this.src;
    }

  } else static if (RTID.get()) {
    immutable(sc.Tid) ret;
    pure this(sc.Tid s, sc.Tid d, sc.Tid r) {
      this.src = cast(Cast) s;
      this.dst = cast(Cast) d;
      this.ret = cast(Cast) r;
    }

    pure sc.Tid returnTid() {
      return cast(sc.Tid) this.ret;
    }

    static Self fromHere(sc.Tid dst, sc.Tid ret) {
      return Self(sc.thisTid, dst, ret);
    }

  } else {
    pure this( sc.Tid s, sc.Tid d) {
      this.src = cast(immutable(sc.Tid)) s;
      this.dst = cast(immutable(sc.Tid)) d;
    }

    const sc.Tid returnTid() {
      return cast(sc.Tid) this.src;
    }

    static Self fromHere(sc.Tid dst) {
      return Self(sc.thisTid, dst);
    }
  }

}

enum Flow {
  // Some simple commands, based on existing control flow
  // Maybe they will prove useless and get removed
  Break, Continue, Exit, Yield, Return
}

version(unittest) {
  import dtp = dulib.types.pair;
  void echo(T)(T exit) {
    alias Resp = dtp.Pair!(T, Flow);
    alias InMsg = Message!(T);
    alias OutMsg = Message!(Resp, HasRet.make(false));
    alias Tddr = Tiddress!(HasRet.make(false));

    while (true) {
      auto r = recieve!(T, dtmo.Option!(bool).make(false))();
      Tddr ret = Tddr.fromHere(r.address.returnTid());
      if (r.msg == exit) {
        OutMsg.send(ret, Resp(r.msg, Flow.Exit));
        return;
      }
      OutMsg.send(ret, Resp(r.msg, Flow.Continue));

    }
  }
}

unittest {
  sc.Tid here = sc.thisTid();
  alias None = Tiddress!();
  None two = None.fromHere!(false)(here);
  None three = None.fromHere!(true, true)(here, here);

  alias True = Tiddress!(HasRet.make(true));
  auto tru2 = two.tryHarden!(true)();
  assert(tru2.isNone());

  auto tru3 = three.tryHarden!(true)();
  assert(tru3.isSome());



  alias False = Tiddress!(HasRet.make(false));

  auto fls2 = two.tryHarden!(false)();
  assert(fls2.isSome());

  auto fls3 = three.tryHarden!(false)();
  assert(fls3.isNone());

  True tru = tru3.get();
  False fls = fls2.get();
}

unittest {
  enum HasRet UTHR = HasRet.make(false);
  alias Tddr = Tiddress!(UTHR);
  Tddr tddr = Tddr.fromHere(sc.spawn(&echo!(ulong), 0));

  alias Msg = Message!(ulong, UTHR);
  alias RMsg = Message!(dtp.Pair!(ulong, Flow), UTHR);
  alias rec = recieve!(dtp.Pair!(ulong, Flow), UTHR);

  for (ulong msg = 1; msg <= 10; msg++) {
    Msg.send(tddr, msg);
    auto ret = rec();
    assert(ret.msg.first == msg);
    assert(ret.msg.second == Flow.Continue);

  }

    Msg.send(tddr, 0);
    assert(rec().msg.second == Flow.Exit);

    //sc.join(tddr.dst);
}
