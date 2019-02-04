# Adding Types in GraphQL

All data in GraphQL is modeled using types. Canvas models will generally
correspond to a GraphQL type.

Many types in GraphQL will not have an underlying ActiveRecord object.  For
example, the `AssignmentGroupRules` type describes the blob data found in
AssignmentGroup#rules_hash.  We want to lean on the GraphQL type system as much
as possible when building out the GraphQL Schema.

## Naming

When the name of a thing differs between the Canvas back-end (ActiveRecord
model) and what Canvas calls something in the UI/documentation, **prefer the
UI/documented name**. (e.g. prefer "module" over "context module", "grade" over
"score", "page" over "wiki page", etc.)

## Node interface

If possible, your type should implement the `Node` interface.  Any type that
implements `Node` can be loaded with the top-level `Query.node` field.

```graphql
query {
  node(id: "ZXCVASDF") {
    ... on Assignment {
      name
    }
  }
}
```

### How to implement the `Node` interface:

1. Use the following boilerplate on your type:

          class MyType < ApplicationObjectType
            implements GraphQL::Types::Relay::Node
            global_id_field :id  # this is a relay-style "global" identifier
            field :_id, ID, "legacy canvas id", method: :id, null: false
            ...
          end

2. Implement the loading-logic in `app/graphql/graphql_node_loader.rb`. **This
   is also where you will check permissions for that object**.

3. Add the type name to `app/graphql/types/legacy_node_type.rb` (more on
   `LegacyNode` below)

4. If the newly added type is not linked into the graph anywhere (other than
   being a return value for a interface/union), you must specify that it is an
   [orphan type](https://graphql-ruby.org/type_definitions/interfaces.html#orphan-types)

5. (Optional) add a new type-specific getter to `QueryType`:

          query {
            assignment(id: "99") {  # id could also have been "ZXCVASDF"
              name
            }
          }

Note that in GraphQL we have the relay-style `id` field (which includes
type-information kind of like canvas asset_strings), and the `_id` field (which
corresponds to the Foo#id).  Fields that take id arguments should accept either
form when possible.

### LegacyNode

`Query.node` lets a user load any object that implements `Node` given a
relay-style id.  Because Canvas API consumers will often only have  a "regular" id,
field, we also expose `Query.legacyNode` which allows a user to load any object
that implements `Node` given a type/_id pair.

```graphql
query {
  legacyNode(type: Assignment, _id: "99") {
    ... on Assignment {
      name
    }
  }
}
```

### Node permissions

It's important to ensure we are using the right set of permissions when
allowing objects to be loaded at the top-level.  Hopefully the type that is
being added has a sensibile `read` permission defined on it, but it's helpful
to see what permission checks are being done on the relevant controller's
`show` action (also see the api serializers for insight into what fields may
need additional permission checks).
