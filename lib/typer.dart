class _Typer<X> {
  const _Typer();

  bool operator >=(_Typer other) => other is _Typer<X>;
  bool operator <=(_Typer other) => other >= this;
  bool operator >(_Typer other) => this >= other && !(other >= this);
  bool operator <(_Typer other) => other >= this && !(this >= other);

  R callWith<R>(R Function<Y>() callback) => callback<X>();

  X cast(Object? o) => o as X;

  bool containsInstance(Object? o) => o is X;

  Type get type => X;

  R? _unsafePromote<R>(Object? instance, Function callback) =>
      callback<X>(instance as X);
}

extension TyperExtension<X> on X {
  X asA(Typer<X> t) => t.cast(this);
  bool isA(Typer<X> t) => t.containsInstance(this);
  bool isNotA(Typer<X> t) => !t.containsInstance(this);
}

extension type const Typer<X>._(_Typer<X> _) implements _Typer<X> {
  // This constructor should be `const`, but we need
  // https://github.com/dart-lang/language/issues/3614
  // before we can do that.
  Typer() : this._(_Typer<X>());

  R? promoting<R>(Object? toPromote, R Function<Y extends X>(Y) callback) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;

  R promotingOrElse<R>(Object? toPromote, R Function<Y extends X>(Y) callback,
      {required R Function() orElse}) {
    if (containsInstance(toPromote)) {
      return _unsafePromote(toPromote, callback);
    } else {
      return orElse();
    }
  }
}

class TyperConstant<X> extends _Typer<X> {
  const TyperConstant();
  Typer<X> get asTyper => Typer._(this);
}

extension TyperConstantExtension<X> on TyperConstant<X> {
  R? promoting<R>(Object? toPromote, R Function<Y extends X>(Y) callback) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;

  R promotingOrElse<R>(Object? toPromote, R Function<Y extends X>(Y) callback,
          {required R Function() orElse}) =>
      containsInstance(toPromote)
          ? _unsafePromote(toPromote, callback)
          : orElse();
}
