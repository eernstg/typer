# type_helper

Provide `TypeHelper<X>`, a more capable version of `Type`.

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

Other than that, you can use an instance of `TypeHelper<T>` for any type
`T` that you can denote, and this will do more than a `Type` can do.

In particular, `TypeHelper` has support for the relational operators
`<`, `<=`, `>`, and `>=`. They will determine whether one `TypeHelper`
represents a type which is a subtype/supertype of another:

```dartdart
void main() {
  const t1 = TypeHelper<int>();
  const t2 = TypeHelper<num>();
  print(t1 <= t2); // 'true'.
  print(t2 <= t1); // 'false'.
}
```

If `typeHelper` is a `TypeHelper<T>` then you can test whether a given
object `o` is an instance of `T` using `o.isA(typeHelper)`, and perform a
cast to `T` using `o.asA(typeHelper)`. Note that these tests will use the
actual value of the type argument of `typeHelper`, not the statically known
type argument (which could be any supertype of the actual one).

```dart
void main() {
  // Somehow, we've forgotten that `typeHelper` represents `int`,
  // we just remember that it is some subtype of `num`.
  TypeHelper<num> typeHelper = TypeHelper<int>();
  
  // But the `isA` (and `asA`) methods will use the actual type.
  print(2.isA(typeHelper)); // 'true'.
  print(1.5.isA(typeHelper)); // 'false'.
  2.asA(typeHelper); // OK.
  1.5.asA(typeHelper); // Throws.
}
```

The methods `isA`, `isNotA`, and `asA` are extension methods. They are
based on instance members. You may wish to use the extension methods
because they have a more conventional syntax, or you may wish (or need) to
use the instance members, e.g., because you do not want to import the
extension, or because the call must be dynamic.

```dart
// Same thing as previous example, using instance members.

void main() {
  TypeHelper<num> typeHelper = TypeHelper<int>();

  print(typeHelper.containsInstance(2)); // 'true'.
  print(typeHelper.containsInstance(1.5)); // 'false'.
  typeHelper.cast(2); // OK.
  typeHelper.cast(1.5); // Throws.
}
```

You can use the getter `type` to access the underlying type as an object
(an instance of `Type`):

```dart
void main() {
  TypeHelper<num> typeHelper = TypeHelper<int>();
  print(typeHelper.type); // 'int'.
}
```

You can use the method `callWith` to get access to the underlying type in a
statically safe manner (this is essentially an "existential open"
operation):

```dart
List<X> createList<X>(TypeHelper<X> typeHelper) {
  
}

void main() {
  // Again, we do not have perfect knowledge about the type.
  TypeHelper<num> typeHelper = TypeHelper<int>();
  
  List<num> xs = typeHelper.callWith(<X>() => <X>[]);
  print(xs is List<int>); // 'true'.
}
```

