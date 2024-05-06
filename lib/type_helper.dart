class TypeHelper<X> {
  const TypeHelper();
  
  bool operator >=(TypeHelper other) => other is TypeHelper<X>;
  bool operator <=(TypeHelper other) => other >= this;
  bool operator >(TypeHelper other) => this >= other && !(other >= this);
  bool operator <(TypeHelper other) => other >= this && !(this >= other);

  R callWith<R>(R Function<Y>() callback) => callback<X>();

  X cast(Object? o) => o as X;

  bool containsInstance(Object? o) => o is X;

  R? _unsafePromote<R>(Object? instance, Function callback) =>
      callback<X>(instance as X);
}

extension TypeHelpingExtension<X> on X {
  X asA(TypeHelper<X> t) => t.cast(this);
  bool isA(TypeHelper<Object?> t) => t.containsInstance(this);
  bool isNotA(TypeHelper<Object?> t) => !t.containsInstance(this);
}

extension TypeHelperExtension<X> on TypeHelper<X> {
  R? promoting<R>(Object? toPromote, R Function<Y extends X>(Y) callback) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;
}
