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
      legacy_id = GraphQLHelpers.parse_relay_id(reference[:id], "Course")
      GraphQLNodeLoader.load("Course", legacy_id, context)
    end
  end
end
```

We expect to promote many types in exactly this way, so we've built a helper
for it.  If a type's `id` field is a Relay-style "global" id (as most are),
*and* you want to promote that type with *only* a single `@key` directive on
the `id` field, i.e. `@key(fields: "id")`, you can just use `key_field_id` like
so:

```ruby
module Types
  class CourseType < ApplicationObjectType
    key_field_id
  end
end
```

See [the gem usage docs](https://github.com/Gusto/apollo-federation-ruby#usage)
for more examples and guidance on using Federation features, including how to
extend entities whose canonical definition resides in an external subgraph.

### Smoke Testing the Federation Subgraph

In deployed environments, only an Apollo API Gateway will be able to query the federation subgraph.  However if you need to smoke test it locally, this is the way.

0. Generate two RSA keypairs and designate one your signing key, the other your
   encryption key.

1. Copy `config/vault_contents.yml.example` to
   `config/vault_contents.yml`, then replace the
   `development.'app-canvas/data/secrets'.data.inst_access_signature.private_key` with the base64-encoded representation of the
   private key of your signing keypair, and the
   `development.'app-canvas/data/secrets'.data.inst_access_signature.encryption_public_key` with the base64-encoded representation
   of the public key of your encryption keypair.

2. Start up your Canvas server and get yourself an API access token, e.g. by
   following the "Manual Token Generation" section of [the OAuth
   docs](../../doc/api/oauth.md).

3. Export that thing as `API_TOKEN` and use it to get yourself an unencrypted
   InstAccess token, e.g.:
```
   $ curl 'http://localhost:3000/api/v1/inst_access_tokens?unencrypted=1' \
     -X POST \
     -H 'Authorization: Bearer $API_TOKEN'
```

4. Now export _that_ thing as `INST_ACCESS` and use _it_ to issue a query to
   the subgraph, e.g.:
```
   $ curl http://localhost:3000/api/graphql/subgraph \
   -X POST \
   -H "Accept: application/json" \
   -H "Content-type: application/json" \
   -H "Authorization: Bearer $INST_ACCESS" \
   --data '
   {
     "query": "query ($_representations: [_Any!]!) { _entities(representations: $_representations) { ... on Course { name } } }",
     "variables": {
       "_representations": [
         {
           "__typename": "Course",
           "id": "Q291cnNlLTE="
         }
       ]
     }
   }'
```

The above query should return a result that includes the name of Course 1, as
long as it exists and the user you used to get the initial access token has
permission to read it.
