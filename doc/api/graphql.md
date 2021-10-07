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

The Canvas REST API will continue to be available.  New Canvas features will be
developed primarily in GraphQL and may not be back-ported to the REST API.

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

## Canvas API Gateway

It's not ONLY Canvas that is using GraphQL as it's primary API protocol
at Instructure.  All Canvas services with public-facing APIs are
moving (slowly) towards federating their APIs through a single [GraphQL gateway](https://community.canvaslms.com/t5/The-Product-Blog/From-the-Engineering-Deck-Instructure-amp-GraphQL/ba-p/477314).

This means that in the future you can access your data from multiple Instructure properties 
beyond Canvas at a single entrypoint, with a single auth pattern, and even in a single request.  
If this idea is entirely foreign to you, you can learn more about this kind of
API gateway in the docs of our tooling vendor, [Apollo](https://www.apollographql.com/docs/federation/).

### How do I connect to the API gateway?

You can interact with the API gateway in any browser directly,
similar to the Graphiql interface in Canvas proper.  Start
by visiting the API URL that matches your Canvas domain.

For example, if your institution uses "abcd.instructure.com" to
interact with Canvas,
you could visit the gateway at "https://abcd.api.instructure.com/graphql"

This will take you to a GraphQL playground interface,
but you'll quickly realize you can't do anything because
the API still needs to know who you are.  Your interface
will have an error message that says something like:

```json
{
  "error": "Response not successful: Received status code 400"
}
```

To use the interface fully, you'll need an Instructure Access Token,
which you can receive from the standard Canvas API.  In order to retrieve
a fresh "Instructure Access Token", you'll have to use your ["Canvas Access Token"](https://canvas.instructure.com/doc/api/file.oauth.html#accessing-canvas-api).
Yes, it's slightly confusing, we're thinking about better names.

```bash
curl 'https://<YOUR_CANVAS_DOMAIN>/api/v1/inst_access_tokens' \
  -X POST \
  -H "Accept: application/json" \
  -H 'Authorization: Bearer <YOUR_CANVAS_ACCESS_TOKEN>'
```

You should get a JSON response that contains a lengthy JWT for you:

```json
{
  "token": "<your-whole-inst-access-token-which-will-be-a-string-much-longer-than-this>"
}
```

That token is temporary (it will expire after an hour), and cannot be used directly against Canvas.
It's only useful as an access token for talking to an API gateway endpoint.  However,
any Canvas GraphQL query you might make can be made through the gateway with one of these
access tokens.

You can prove to yourself that this new token is valid by executing a simple query
against the API gateway directly (you can use the regional access URL of your choice):

```bash
curl 'https://<your-subdomain>.api.instructure.com/graphql' \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer <your-inst-access-token>' \
  --data-binary '{"query":"{ whoami { userUuid } }"}' --compressed
```

If you used the InstAccessToken correctly, you'll get a simple response including the UUID of
the user that created this token:

```json
{
  "data": {
    "whoami": {
      "userUuid":"<your-user-uuid>"
    }
  }
}
```

If you go back to your browser, which you previously pointed at one of the API
gateway endpoints, look in the lower left of the screen to find the
"HTTP Headers" panel.  Here you can put in your Instructure Access Token into
the authorization header by entering a JSON document that looks like:

```json
{
  "Authorization": "Bearer <your-inst-access-token>"
}
```

Now you should be able to author any GraphQL query you want
in the editor on the left side, and see the results displayed on the right side when
you hit the play button.  Try some of these queries:

Simple Hello World
```gql
{ hello }
```
Response:
```json
{
  "data": {
    "hello": "Hello world!"
  }
}
```

Two queries at once, one that tells you which user you are.
```gql
{
  hello
  whoami {
    userUuid
  }
}
```
Response:
```json
{
  "data": {
    "hello": "Hello world!",
    "whoami": {
      "userUuid": "<your-user-uuid>"
    }
  }
}
```

Two SERVICES at once, (the "account" entrypoint
is substantiated by Canvas, the other 2 are test entrypoints
provided by a different backend).  This is the shape of the idea for
interacting with systems like "New Quizzes".
```gql
{
  hello
  whoami {
    userUuid
  }
  account(id: <your-account-id>){
    id
    name
    sisId
  }
}
```

Response:
```json
{
  "data": {
    "hello": "Hello world!",
    "whoami": {
      "userUuid": "<your-user-uuid>"
    },
    "account": {
      "id": "<account-uuid>",
      "name": "<account-name>",
      "sisId": "<sis-id>"
    }
  }
}
```

#### FCQs (frequently confusing queries)

##### Is there any advantage to me in using the gateway rather than the Canvas  GraphQL  endpoint directly?

Not really, if you're just loading data from Canvas itself.  In the future, if you're interacting
with New Quizzes or other ancillary services, there will be graph entries present in the gateway
schema for those services that are NOT available through Canvas directly, so for those
cases using the gateway gives you access to a wider set of api endpoints.

##### Why can't I just use my Canvas access token against the gateway?

Your Canvas access tokens are long lived and give access to everything,
plus Canvas has to hear about them to confirm with the database what user
 they're attached to.  Instructure Access Tokens contain cryptographically signed payloads that
 any Instructure service (like new quizzes) can read to confirm who you are without
 having to consult Canvas (which helps avoid performance bottlenecks).  They also
 only are valid for a short time, so handing them around the network is less risky
 from a security standpoint.

##### What should I do if my Instructure Access Token stops working

They're designed to expire after one hour so the compromise of such a token is
a low-severity event.  Simply request another one from the Canvas
`/api/v1/inst_access_tokens` endpoint as shown above and keep going.

This implies that API clients should expect to be able to catch "4xx" responses from
the API gateway, recognize their token is expired, and "refresh" it by obtaining a new one.

##### What tools exist for helping me build a  GraphQL  API client?

Apollo maintains a [list of GraphQL libraries](https://graphql.org/code/#javascript-client) that are
useful for building clients.

##### Will Canvas (the web application) use the API Gateway?

Yes, and it already does.  Canvas uses the "Apollo Client" library
for it's GraphQL interactions, which in some cases we configure to talk
through the gateway rather than to the Canvas API directly, but for objects
in the Canvas graph the responses are identical.

If you're running Canvas yourself though, you do not have to use the API gateway,
Canvas clients will continue to talk to the Canvas-provided  GraphQL  endpoint just fine.

