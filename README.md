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
  print(t2 < t1); // 'false'.
}
```

`TypeHelper` 
