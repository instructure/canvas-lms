GraphQL API
===============================

## GraphQL Introduction

GraphQL is a query API language that executes queries by using a type system
based on defined input data. GraphQL provides more specific inquiries with
faster results and populate multiple inputs into one query.

Note: GraphQL endpoint permissions mirror permissions for the REST API. A
user is only granted access to view grades based on that user’s permissions.
For instance, a student cannot view grades for another student, but an
instructor can view grades for any student in a course.

[Learn more about GraphQL](https://graphql.org/learn/).

## Using GraphQL

Canvas has included the tool GraphiQL (https://github.com/graphql/graphiql), an
in-browser graphical interface for interacting with GraphQL endpoints.

The GraphiQL interface can be viewed by adding /graphiql to the end of your
Canvas production URL (e.g. your-institution.instructure.com/graphiql).

The /graphiql access can also be added to a test or beta environment URL.
Requests from the selected environment will always return that environment’s
data.

The Explorer sidebar displays all available queries and mutations. Any selected
items display in the GraphiQL window. Once a query or mutation is selected, any
values displayed in purple text identify the value as an input argument.

### REST vs GraphQL

The Canvas REST API will continue to be available.

Fields are being added to the GraphQL API on an as-needed basis.  The GraphQL
API does not include everything that is currently in the REST API.  Feel free
to submit pull requests on github to add additional features or talk about it
in the `#canvas-lms` channel on libera.chat.

## GraphQL Endpoint

<div class="method_details">
  <h3 class="endpoint">POST /api/graphql</h3>
</div>

All GraphQL queries are posted to this endpoint.

#### Request Parameters

<table class="request-params">
  <tr>
    <th class="param-name">Parameter</th>
    <th class="param-req"></th>
    <th class="param-type">Type</th>
    <th class="param-desc">Description</th>
  </tr>
  <tr class="request-param">
    <td>query</td>
    <td></td>
    <td>string</td>
    <td>the GraphQL query to execute</td>
  </tr>
  <tr class="request-param">
    <td>variables</td>
    <td></td>
    <td>Hash</td>
    <td>variable values as required by the supplied query</td>
  </tr>
</table>

#### Example Request:

```bash
curl https://<canvas>/api/graphql \
  -H 'Authorization: Bearer <ACCESS_TOKEN>' \
  -d query='query courseInfo($courseId: ID!) {
       course(id: $courseId) {
        id
        _id
        name
       }
     }' \
  -d variables[courseId]=1
```

#### Example Response

```js
{
  "data": {
    "course": {
      "id": "Q291cnNlLTE=",
      "_id": "1",
      "name": "Mr. Ratburn's Class"
    }
  }
}
```

## GraphQL in Canvas

### `id` vs `_id` and the `node` field

The Canvas LMS GraphQL API follows the [Relay Object Identification
spec](https://relay.dev/graphql/objectidentification.htm).
Querying for an object's `id` will return a global identifier instead of the
numeric ids that are used in the REST API.  The traditional ids can be queried
by requesting the `_id` field.

Most objects can be fetched by passing their  GraphQL  `id` to the
`node` field:

```graphql
{
  node(id: "Q291cnNlLTE=") {
    ... on Course {
      _id  #  traditional ids (e.g. "1")
      name
      term { name }
    }
  }
}
```

A `legacyNode` field is also available to fetch objects via the
REST-style ids:

```
{
  # object type must be specified when using legacyNode
  legacyNode(type: Course, _id: "1") {
    ... on Course {
      _id
      name
    }
  }
}
```

For commonly accessed object types, type-specific fields are provided:

```
{
  # NOTE: id arguments will always take either GraphQL or rest-style ids
  c1: course(id: "1") {
    _id
    name
  }
  c2: course(id: "Q291cnNlLTE=") {
    _id
    name
  }
}
```

### Pagination

Canvas follows the [Relay Connection
Spec](https://facebook.github.io/relay/graphql/connections.htm)
for paginating collections.  Request reasonable page sizes to avoid
being limited.

```
{
  course(id: "1") {
    assignmentsConnection(
      first: 10,      # page size
      after: "XYZ"    # `endCursor` from previous page
    ) {
      nodes {
        id
        name
      }
      pageInfo {
        endCursor     # this is your `after` value for the next request
        hasNextPage
      }
    }
  }
}
```
