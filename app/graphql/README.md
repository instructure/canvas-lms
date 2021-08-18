# GraphQL in Canvas

Canvas has a "first-class" GraphQL data graph that is publicly exposed on an
API endpoint.  This is already [well-documented](../../doc/api/graphql.md).

## Apollo Federation

In addition to the standard GraphQL endpoint, Canvas exposes a "subgraph"
endpoint whose schema is suitable for use in an [Apollo
Federation](https://www.apollographql.com/docs/federation/).  This is the same
schema, but extended according to the Apollo Federation
[specification](https://www.apollographql.com/docs/federation/federation-spec/),
and with some Federation directives applied to various fields and types.

The [apollo-federation gem](https://github.com/Gusto/apollo-federation-ruby) is
used to add Federation directives to this subgraph.  While it is important that
the public-facing graph does not include Federation extensions, the gem's
features can be used freely on any type or field.  They are simply ignored in
the public-facing graph, and do not show up in its schema.

### Promoting an Object Type to a Federation Entity

A Federation [entity](https://www.apollographql.com/docs/federation/entities)
is an object type whose definition spans multiple subgraphs.  One subgraph
provides its canonical definition, and others extend it.

To promote an existing type to an entity with its canonical definition in
Canvas, declare one or more `key` fields and implement `::resolve_reference`.
E.g.:

```ruby
module Types
  class CourseType < ApplicationObjectType
    key fields: "id"
    def self.resolve_reference(reference, context)
      GraphQLNodeLoader.load("Course", reference[:id], context)
    end
  end
end
```

See [the gem usage docs](https://github.com/Gusto/apollo-federation-ruby#usage)
for more examples and guidance on using Federation features, including how to
extend entities whose canonical definition resides in an external subgraph.
