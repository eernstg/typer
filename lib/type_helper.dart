class _TypeHelper<X> {
  const _TypeHelper();
  
  bool operator >=(_TypeHelper other) => other is _TypeHelper<X>;
  bool operator <=(_TypeHelper other) => other >= this;
  bool operator >(_TypeHelper other) => this >= other && !(other >= this);
  bool operator <(_TypeHelper other) => other >= this && !(this >= other);

  R callWith<R>(R Function<Y>() callback) => callback<X>();

  X cast(Object? o) => o as X;

  bool containsInstance(Object? o) => o is X;

  Type get type => X;

  R? _unsafePromote<R>(Object? instance, Function callback) =>
      callback<X>(instance as X);
}

extension TypeHelperExtension<X> on X {
  X asA(TypeHelper<X> t) => t.cast(this);
  bool isA(TypeHelper<Object?> t) => t.containsInstance(this);
  bool isNotA(TypeHelper<Object?> t) => !t.containsInstance(this);
}

extension type const TypeHelper<X>._(_TypeHelper<X> _)
    implements _TypeHelper<X> {

  // This constructor should be `const`, but we need
  // https://github.com/dart-lang/language/issues/3614
  // before we can do that.
  TypeHelper(): this._(_TypeHelper<X>());
  
  R? promoting<R>(Object? toPromote, R Function<Y extends X>(Y) callback) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;

  R promotingOrElse<R>(Object? toPromote, 
    R Function<Y extends X>(Y) callback,
    {required R Function() orElse}) {
    if (containsInstance(toPromote)) {
      return _unsafePromote(toPromote, callback);
    } else {
      return orElse();
    }
  }
}

class TypeHelperConstant<X> extends _TypeHelper<X> {
  const TypeHelperConstant();
  TypeHelper<X> get asTypeHelper => TypeHelper._(this);
}

extension TypeHelperConstantExtension on TypeHelperConstant<X> {
  R? promoting<R>(Object? toPromote, R Function<Y extends X>(Y) callback) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;

  R promotingOrElse<R>(Object? toPromote, 
    R Function<Y extends X>(Y) callback,
    {required R Function() orElse}) {
    if (containsInstance(toPromote)) {
      return _unsafePromote(toPromote, callback);
    } else {
      return orElse();
    }
  }
}
