import sc = std.concurrency;

import dtmo = dulib.types.monads.option;
import dt = dulib.types;

private alias HasRet = bool;
private immutable HasRet DefHR = false;

alias recieve(T, HasRet R = DefHR) = sc.receiveOnly!(Message!(T, R));

struct Message(T, HasRet R = DefHR) {
  alias Self = Message!(T, R);
  alias Tddr = Tiddress!(R);
  immutable Tddr tids;
  immutable T message;

  private this(T m, Tddr a) {
    this.tids = cast(immutable(Tddr)) a;
    this.message = cast(immutable(T)) m;
  }

  public static void send(Tddr a, T msg) {
    sc.send(cast(sc.Tid) a.dst, Self(msg, a));
  }
}

struct Tiddress(HasRet RTID = DefHR) {
  immutable sc.Tid src, dst;
  alias Cast = immutable(sc.Tid);
  alias Self = Tiddress!(RTID);
  static if (RTID) {
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
    static assert(!RTID);
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
    alias OutMsg = Message!(Resp, false);
    alias Tddr = Tiddress!(false);

    while (true) {
      auto r = recieve!(T, false)();
      Tddr ret = Tddr.fromHere(r.tids.returnTid());
      if (r.message == exit) {
        OutMsg.send(ret, Resp(r.message, Flow.Exit));
        return;
      }
      OutMsg.send(ret, Resp(r.message, Flow.Continue));

    }
  }
}

unittest {
  alias True = Tiddress!(true);
  alias False = Tiddress!(false);

  sc.Tid HERE = sc.thisTid();

  auto t = True(HERE, HERE, HERE);
  auto f = False(HERE, HERE);
}

unittest {
  enum HasRet UTHR = false;
  alias Tddr = Tiddress!(UTHR);
  Tddr tddr = Tddr.fromHere(sc.spawn(&echo!(ulong), 0));

  alias Msg = Message!(ulong, UTHR);
  alias RMsg = Message!(dtp.Pair!(ulong, Flow), UTHR);
  alias rec = recieve!(dtp.Pair!(ulong, Flow), UTHR);

  for (ulong msg = 1; msg <= 10; msg++) {
    Msg.send(tddr, msg);
    auto ret = rec();
    assert(ret.message.first == msg);
    assert(ret.message.second == Flow.Continue);

  }

    Msg.send(tddr, 0);
    assert(rec().message.second == Flow.Exit);

    //sc.join(tddr.dst);
}
