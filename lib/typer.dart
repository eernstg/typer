// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Reify the type parameter [X], similarly to a [Type].
///
/// For any type `T`, an instance of [Typer<T>] can be used in a way
/// which is similar to an instance of `Type` that was obtained as a
/// reification of `T`, except that the [Typer] is considerably more
/// capable.
///
/// A [Typer] supports relational operators (`<=`, `<`, etc), deciding
/// whether or not there is a subtype relationship between the two types
/// that are reified by the receiver and the operand of that operator.
///
/// It also supports type tests and type casts, similar to `e is T` and
/// `e as T`, where `T` is the type reified by the given [Typer] (which
/// is not necessarily a type which can be denoted at compile time, so
/// we can't just write `e is T` or `e as T` for any `T` in order to get
/// the same behavior).
///
/// A [Typer] also supports a limited form of existential open, using
/// the method [callWith].
///
/// Finally, a [Typer] supports promotion to the type reified by said
/// [Typer].
class Typer<X> {
  const Typer();

  /// Return true iff this [Typer] is a supertype of [other].
  bool operator >=(Typer other) => other is Typer<X>;

  /// Return true iff this [Typer] is a subtype of [other].
  bool operator <=(Typer other) => other >= this;

  /// Return true iff this [Typer] is a strict supertype of [other].
  bool operator >(Typer other) => this >= other && !(other >= this);

  /// Return true iff this [Typer] is a strict subtype of [other].
  bool operator <(Typer other) => other >= this && !(this >= other);

  /// Invoke the given [callback] with [X] as the type argument.
  ///
  /// This
  R callWith<R>(R Function<Y>() callback) => callback<X>();

  /// Perform a type cast to [X] on the argument [o].
  X cast(Object? o) => o as X;

  /// Perform a type test that the argument [o] is an [X].
  bool containsInstance(Object? o) => o is X;

  /// Return the `Type` that reifies [X].
  Type get type => X;

  R? _unsafePromote<R>(Object? instance, Function callback) =>
      callback<X>(instance as X);

  @override
  bool operator ==(other) {
    if (other is! Typer) return false;
    return this <= other && other <= this;
  }

  static final int _typerHashCode = (Typer<Object?>).hashCode;

  @override
  int get hashCode => X.hashCode ^ _typerHashCode;

  @override
  String toString() => 'Typer<$X>';
}

/// Provide familiar access to some members of `Typer`.
///
/// This extension provides some extension methods on all types
/// of receiver, enabling type tests and type casts to be expressed
/// in a way which is more similar to the built-in type tests and
/// type casts of Dart than a direct use of members of `Typer`.
extension UseTyperExtension<X> on X {
  /// Type cast [this] to the type reified by [t].
  X asA(Typer<X> t) => t.cast(this);

  /// Determine whether [this] has the type reified by [t].
  bool isA(Typer<X> t) => t.containsInstance(this);

  /// Determine whether [this] does not have the type reified by [t].
  bool isNotA(Typer<X> t) => !t.containsInstance(this);
}

/// Support promotion to the type reified by [this].
extension TyperExtension<X> on Typer<X> {
  /// Promote [toPromote] to the type reified by [this], or return null.
  ///
  /// Assume that [toPromote] has the type reified by [this]. In that case,
  /// [callback] will be executed, passing the type reified by [this] as
  /// the actual type argument, and the value returned by [callback] is the
  /// value returned by this method.
  ///
  /// Assume that [toPromote] has some other type. In that case, this
  /// method takes no further action, and null is returned.
  ///
  /// If and when [callback] is executed, it is guaranteed that the actual
  /// argument is identical to [toPromote]. By declaration, the actual
  /// argument has type `Y` (or whatever name was given to that type
  /// parameter by the author of the given [callback]). In other words,
  /// [toPromote] has now been promoted to have the type reified by [this].
  ///
  /// Note that the statically known type argument of [this], namely [X],
  /// is specified to be the bound of `Y`. This means that the interface
  /// of the promoted object has been enhanced to include the interface
  /// of [X].
  ///
  /// In short, we have promoted [toPromote] to the type reified by [this],
  /// and we have promoted the statically known interface of [toPromote]
  /// to the statically known bound of the type reified by [this]. If the
  /// promotion fails (because [toPromote] does not have the required type)
  /// then null is returned.
  R? promoteOrNull<R>(Object? toPromote, R Function<Y extends X>(Y) callback) =>
      containsInstance(toPromote) ? _unsafePromote(toPromote, callback) : null;

  /// Promote [toPromote] to the type reified by [this], or return `orElse()`.
  ///
  /// Assume that [toPromote] has the type reified by [this]. In that case,
  /// [callback] will be executed, passing the type reified by [this] as
  /// the actual type argument, and the value returned by [callback] is the
  /// value returned by this method.
  ///
  /// Assume that [toPromote] has some other type. In that case, this
  /// method returns the result of invoking [orElse].
  ///
  /// If and when [callback] is executed, it is guaranteed that the actual
  /// argument is identical to [toPromote]. By declaration, the actual
  /// argument has type `Y` (or whatever name was given to that type
  /// parameter by the author of the given [callback]). In other words,
  /// [toPromote] has now been promoted to have the type reified by [this].
  ///
  /// Note that the statically known type argument of [this], namely [X],
  /// is specified to be the bound of `Y`. This means that the interface
  /// of the promoted object has been enhanced to include the interface
  /// of [X].
  ///
  /// In short, we have promoted [toPromote] to the type reified by [this],
  /// and we have promoted the statically known interface of [toPromote]
  /// to the statically known bound of the type reified by [this]. If the
  /// promotion fails (because [toPromote] does not have the required type)
  /// then the result of invoking [orElse] is returned.
  R promote<R>(
    Object? toPromote,
    R Function<Y extends X>(Y) callback, {
    required R Function() orElse,
  }) =>
      containsInstance(toPromote)
          ? _unsafePromote(toPromote, callback)
          : orElse();
}
