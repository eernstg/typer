# typer

Provide `Typer<X>`, a user-written, but more capable version of `Type`.

## The built-in `Type` class

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

## Typer

For all other things than getting the run-time type of an existing object,
we can use an instance of `Typer<T>` for any type `T` that we can denote,
and this will do more than a `Type` can do.

### Comparing types

In particular, `Typer` has support for the relational operators
`<`, `<=`, `>`, and `>=`. They will determine whether one `Typer`
represents a type which is a subtype/supertype of another:

```dart
void main() {
  const t1 = Typer<int>();
  const t2 = Typer<num>();
  print(t1 <= t2); // 'true'.
  print(t2 <= t1); // 'false'.
}
```

### Type tests and type casts

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

### Using the type that a `Typer` represents

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
  List<num>? xs = typer.promoteOrNull(n, <X extends num>(X promoted) {
    print('  The promotion to `typer` succeeded!');
    return <X>[promoted];
  });
  print('Type of `xs`: ${xs.runtimeType}'); // `List<int>` or `Null`.

  print('Promoting with `orElse` fallback:');
  Object o = n; // Promote from a rather general type.
  num n2 = typer.promote(o, <X extends num>(X promoted) {
      print('  The promotion to `typer` succeeded!');
      // `typer` has static type `Typer<num>`, so we can use `num` members.
      promoted.floor();
      return promoted;
    },
    orElse: () => 14,
  );
  print('n2: $n2'); // '2' or '14'.
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
receive the object which is being type tested (`promoted` in the example).

In the body of that callback we can then use the promoted value, and it is
statically known that it has a type which is a subtype of that type
argument (in the example: we know that the actual argument has type `X`).
Note that `X` is bounded by the statically known type argument of `typer`,
which means that we can use the interface of `num` on the promoted object.

Note, though, that we are actually promoting the promoted object to the
type reified by `typer` (which is `int`), not just to the statically known
bound (which is `num`). So when the value of `n` is `2.5`, we use the
value from `orElse()`, and do not run the `callback`.

### Example design

Here is an example of a design which can be used to enable techniques that
are similar to an existential open operation, in a rather general
fashion. That is, it allows us to use the type arguments of a given object
"from the outside".

The basic idea is that a generic class with type parameters `X1 .. Xk`
has a getter for each type variable `Xj`, returning a `Typer<Xj>`.

These getters can be used to write code that uses the actual value of each
of the type variables of the class, which is again a feature that Dart does
not support for client code. In fact, only code in the body of the class
has access to the type variables because that's the only code for which
those type variables are in scope. Outside clients only know an approximate
value which is a supertype of the actual value, based on the statically
known type of the given object.

For instance, in the body of the `List<E>` class the type parameter `E` is
in scope, and we can do things like `return <E>{};`. But in code outside
the body of `List`, we may only know that the list is a `List<T>` where `T`
could be any supertype of the actual value, e.g., we might only know that
it is a `List<Object?>`.

In this example, we use the `Typer` to create a set from a given list,
preserving the actual type argument.

The example uses mock classes `MyIterable`, `MyList`, and `MySet`, but this
is only because we can't easily add the necessary `Typer` getters to the
real `List` and `Set` classes. Nevertheless, if such getters were added
then these techniques could be just on real `List` and `Set` objects, just
like they are used here.

This is true for any class, of course: If you want to enable this kind of
existential opening for one of the classes you maintain then you just need
to add those `Typer` getters, and you're done.

Here is the example:

```dart
abstract class MyIterable<E> {
  const MyIterable();

  E get first;

  Typer<E> get typerOfE => Typer();
}

class MyList<E> extends MyIterable<E> {
  final E e;

  const MyList(this.e);

  @override
  E get first => e;
}

class MySet<E> extends MyIterable<E> {
  final E e;

  const MySet(this.e);

  @override
  E get first => e;
}

MySet<X> iterableToSet<X>(MyIterable<X> iterable) =>
    iterable.typerOfE.callWith(<Y>() {
      return MySet<Y>(iterable.first as Y) as MySet<X>;
    });

void main() {
  // Assume that we do not know the precise type of `iterable`.
  MyIterable<Object?> iterable = MyList<int>(42);

  // Now we want to create a set with the same element type.
  var set = iterableToSet(iterable);
  print(set.runtimeType); // 'MySet<int>'.
}
```

This kind of code isn't particularly convenient. For example, we have to
"manually tell the type system" that `iterable.first` has the type `Y`.

This is indeed true because `Y` will be the actual type argument of
`iterable`, but the type system cannot make that connection. (It would
take a full-fledged language mechanism to be able to know this in the type
system.) Still, the fact that `Y` is guaranteed to be the actual type
argument of `iterable` allows us to write type casts that are guaranteed to
succeed. And the point is that we can now _use_ that actual type argument
because it's available as `Y` in the body of the function literal.

The crucial insight is that it is not possible to get access to the value
of a type variable of an existing object unless we have _something_ inside
the body of the class of that object. The `typerOfE` getter is a quite
general tool for this purpose.

This means that you can do things that you otherwise can't do. 

To handle the inconvenience, we'd use well-known abstraction techniques to
make it look nice, e.g., by writing a reusable function like
`iterableToSet`.
