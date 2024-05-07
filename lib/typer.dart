class Typer<X> {
  const Typer();

  bool operator >=(Typer other) => other is Typer<X>;
  bool operator <=(Typer other) => other >= this;
  bool operator >(Typer other) => this >= other && !(other >= this);
  bool operator <(Typer other) => other >= this && !(this >= other);

  R callWith<R>(R Function<Y>() callback) => callback<X>();

  X cast(Object? o) => o as X;

  bool containsInstance(Object? o) => o is X;

  Type get type => X;

  R? _unsafePromote<R>(Object? instance, Function callback) =>
      callback<X>(instance as X);
}

extension UseTyperExtension<X> on X {
  X asA(Typer<X> t) => t.cast(this);
  bool isA(Typer<X> t) => t.containsInstance(this);
  bool isNotA(Typer<X> t) => !t.containsInstance(this);
}

extension TyperExtension<X> on Typer<X> {
  R? promoteOrNull<R>(Object? toPromote, R callback<Y extends X>(Y)) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;

  R promote<R>(Object? toPromote, R callback<Y extends X>(Y),
      {required R orElse()}) =>
    containsInstance(toPromote)
    ? _unsafePromote(toPromote, callback)
    : orElse();
}
