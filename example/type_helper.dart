import 'dart:math';
import 'package:type_helper/type_helper.dart';

class Parent {}

class Child implements Parent {
  String get childThing => 'Just kidding!';
}

class OtherChild implements Parent {}

List<X> listOfMaybe<X>(Object? perhapsInclude) =>
    perhapsInclude is X ? <X>[perhapsInclude] : <X>[];

TypeHelper<List<X>> listTypeHelper<X>() => TypeHelper<List<X>>();

const typeInt = TypeHelperConstant<int>();

void main() {
  Parent p = Random().nextBool() ? Child() : OtherChild();
  final typeParent = TypeHelper<Parent>();
  final typeChild = TypeHelper<Child>();
  final typeWhoKnows = typeChild as TypeHelper<Parent>;

  print('typeChild <: typeParent: ${typeChild <= typeParent}'); // 'true'.
  print('typeParent <: typeChild: ${typeParent <= typeChild}'); // 'false'.

  print('p is typeParent: ${p.isA(typeParent)}'); // 'true'.
  print('p is typeChild: ${p.isA(typeChild)}'); // 'true' or 'false'.

  // Create a `TypeHelper` for a `List` type whose type argument is `typeChild`.
  var typeListOfChild = typeChild.callWith(<X>() => TypeHelper<List<X>>());
  print(typeListOfChild.type); // `List<Child>`.

  // Create a `List` whose type argument is `typeChild`, containing `p` if OK.
  var listOfChild = typeChild.callWith(<X>() => listOfMaybe<X>(p));
  print('listOfChild: $listOfChild, of type: ${listOfChild.runtimeType}');

  // Promote to the type of a `TypeHelper`. Note that we are using the
  // statically known bound `Parent` of `typeWhoKnows`, but the promotion
  // will check that `p` has the actual type represented by `typeWhoKnows`,
  // which could be any subtype of `Parent` (in this case it is `Child`).
  print('Promoting:');
  List<Parent>? ps = typeWhoKnows.promoting(p, <X extends Parent>(X promotedP) {
    print('  The promotion to `typeWhoKnows` succeeded!');
    return <X>[promotedP];
  });
  print('Type of `ps`: ${ps.runtimeType}'); // `List<Child>` or `Null`.

  print('Promoting with `orElse` fallback:');
  Child c = typeChild.promotingOrElse(p, <X extends Child>(X promotedP) {
      print('  The promotion to `typeChild` succeeded!');
      print('  Can do `Child` specific things: ${promotedP.childThing}');
      return promotedP;
    },
    orElse: () => Child(),
  );
  print('c: $c, same as `p`: ${identical(p, c)}');
}
