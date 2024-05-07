# typer

Provide `Typer<X>`, a user-written, but more capable version of `Type`.

The language Dart has built-in support for obtaining a reified
representation of a given type `T` by evaluating the corresponding type
literal as an expression:

```dart
typedef TypeOf<X> = X;

void main() {
  // `type` is an `Object` representing the type `int`.
  Type type = int;
  
  // Some types are not expressions, but we can still get their `Type`
  // via a helper type alias like `TypeOf`.
  Type functionType = TypeOf<void Function([String])>;
  
  // Instances of `Type` can't be used for much, but they do have equality.
  print(type == functionType); // 'false'.
  
  // For example, we can't use them in type tests, nor in subtype checks.
  1 is type; // Compile-time error.
  1 as type; // Compile-time error.
  type <= functionType; // Compile-time error.
}
```

The the greatest power offered by `Type` is that we can obtain a
reification of the run-time type of any given object using `runtimeType`:

```dart
void main() {
  Object? o1 = ..., o2 = ...; // Anything will do.
  print(o1.runtimeType == o2.runtimeType);
}
```

Other than that, we can use an instance of `Typer<T>` for any type
`T` that we can denote, and this will do more than a `Type` can do.

In particular, `Typer` has support for the relational operators
`<`, `<=`, `>`, and `>=`. They will determine whether one `Typer`
represents a type which is a subtype/supertype of another:

```dartdart
void main() {
  const t1 = Typer<int>();
  const t2 = Typer<num>();
  print(t1 <= t2); // 'true'.
  print(t2 <= t1); // 'false'.
}
```

If `typer` is a `Typer<T>` then we can test whether a given
object `o` is an instance of `T` using `o.isA(typer)`, and perform a
cast to `T` using `o.asA(typer)`. Note that these tests will use the
actual value of the type argument of `typer`, not the statically known
type argument (which could be any supertype of the actual one).

```dart
void main() {
  // Somehow, we've forgotten that `typer` represents `int`,
  // we just remember that it is some subtype of `num`.
  Typer<num> typer = Typer<int>();
  
  // But the `isA` (and `asA`) methods will use the actual type.
  print(2.isA(typer)); // 'true'.
  print(1.5.isA(typer)); // 'false'.
  2.asA(typer); // OK.
  1.5.asA(typer); // Throws.
}
```

The methods `isA`, `isNotA`, and `asA` are extension methods. They are
based on instance members. We may wish to use the extension methods
because they have a more conventional syntax, or we may wish (or need) to
use the instance members, e.g., because we do not want to import the
extension, or because the call must be dynamic.

```dart
// Same thing as previous example, using instance members.

void main() {
  Typer<num> typer = Typer<int>();

  print(typer.containsInstance(2)); // 'true'.
  print(typer.containsInstance(1.5)); // 'false'.
  typer.cast(2); // OK.
  typer.cast(1.5); // Throws.
}
```

We can use the getter `type` to access the underlying type as an object
(an instance of `Type`):

```dart
void main() {
  Typer<num> typer = Typer<int>();
  print(typer.type); // 'int'.
}
```

We can use the method `callWith` to get access to the underlying type in a
statically safe manner (this is essentially an "existential open"
operation):

```dart
List<X> createList<X>(Typer<X> typer) =>
    typer.callWith(<Y>() => <Y>[] as List<X>);

void main() {
  // Again, we do not have perfect knowledge about the type.
  Typer<num> typer = Typer<int>();

  List<num> xs = createList(typer);
  print(xs is List<int>); // 'true'.
}
```

To see why this is a non-trivial operation, try to complete the following
example which is doing the same thing using the built-in `Type` objects:

```dart
List<X> createList<X>(Type type) => ...; // NB!

void main() {
  Type type = int;

  List<num> xs = createList(type);
  print(xs is List<int>); // 'true'.
}
```

Note that `X` is unconstrained, and there is no guarantee that it has any
relationship with the given `Type` (`X` could have the value `String` and
`type` could be a reified representation of `int`, and we wouldn't know
there's a problem).

It is actually not possible (without 'dart:mirrors') to extract any
information from the given `type` (other than equality, say, which could be
used to test that `type != X`, but that wouldn't be very useful). So we
basically can't write code (again, except using mirrors) which will create
a `List<int>` based on the fact that `type` is a reified representation of
`int`. Using equality we can take some baby steps, but it won't scale up:

```dart
List<X> createList<X>(Type type) => switch (type) {
    int => <int>[],
    String => <String>[],
    _ => throw "OK, obviously this will never happen! ;-)",
  };
```

Finally we have two methods associated with promotion:

```dart
void main() {
  Typer<num> typer = Typer<int>();
  num n = Random().nextBool() ? 2 : 2.5;

  print('Promoting:');
  List<num>? xs = typer.promoting(n, <X extends num>(X promotedN) {
    print('  The promotion to `typer` succeeded!');
    return <X>[promotedN];
  });
  print('Type of `xs`: ${xs.runtimeType}'); // `List<int>` or `Null`.

  print('Promoting with `orElse` fallback:');
  int c = typer.promotingOrElse(n, <X extends num>(X promotedN) {
      print('  The promotion to `typeChild` succeeded!');
      return promotedN as int;
    },
    orElse: () => 14,
  );
  print('c: $c'); // '2' or '14'.
}
```

We cannot use `is` or `as` directly to obtain a promotion because we cannot
test directly against the underlying type `T` of a given
`Typer<T>`. We can call `isA` or `asA`, but those methods do not give
rise to promotion of their receiver because the type system does not know
that `isA` actually returns `true` or `false` in exactly the same way as
`is` does, and `asA` will throw in exactly the same manner as `as`, albeit
based on the type `T` rather than on a type which can be denoted locally.

However, we can pass a generic callback which will receive the underlying
type `T` of the `Typer<T>` as its actual argument, and it will also
receive the object which is being type tested (`promotedN` in the example).

In the body of that callback we can then use the promoted value, and it is
statically known that it has a type which is a subtype of that type
argument (in the example: we know that `promotedN is X`).

In the case where `promoting` is used to return a value, we may need to
perform a type cast on returned values (like `return promotedN as
int`). The reason for this is that it is not known to the static analysis
that `X` is exactly the underlying type of `typer`. It is true, but we
have to insist on it because the type checker can't see it.

