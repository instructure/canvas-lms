# Basic Usage
This will allow you to mock data for a graphql query (or mutation) that
semantically matches the data types for canvas's graphql API. For example, if
you queried for some data that should return a not null integer, this will
return data for that field that contains a random integer, or if a field is an
enum, it will randomly pick one of the enum values. This is a wrapper around the
apollo mocking library (https://www.apollographql.com/docs/graphql-tools/mocking/)

```javascript
async function example() {
  const query = gql`
    query ExampleQuery {
      course(id: "1") {
        name
        state
      }
    }
  `
  const result = await mockGraphqlQuery(query)
  console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "course": {
      "name": "Hello World",
      "state": "created"
    }
  }
}
```

# Overriding return data
You can modify the returned data of your query by using the `overrides` argument
in mockGraphqlQuery.

```javascript
async function example() {
  const query = gql`
    query ExampleQuery {
      course(id: "1") {
        course_name: name
        state
      }
    }
  `
  const overrides = [{
    Course: {
      name: 'Course 1',
      state: 'available'
    }
  }]
  const result = await mockGraphqlQuery(query, overrides)
  console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "course": {
      "course_name": "Course 1",
      "state": "available"
    }
  }
}
```

It is important to note that overrides work on the graphql type. Notice that the
above overrides was for `Course`, instead of `course` like in the query. This is
because `Course` is the actual graphql typename for that object. Similarly, when
overriding an aliased field like `course_name`, we still apply the override to
to the graphql name for that field, in this case `name`.

You can find the graphql typenames by looking at the `Documentation Explorer`
tab on the `/graphiql` page, or by looking at the `schema.graphql` file.

Because we are overriding the graphql types, any overrides we provide are going
to be used anywhere that type shows up in the given query. This is very helpful
for being able to mock data deep in a query without having to go through each
individual node to get there. For example:

```javascript
async function example() {
  const query = gql`
    query MyQuery {
      assignment(id: "1") {
        discussion {
          modules {
            name
          }
        }
        modules {
          name
        }
      }
    }
  `
  const overrides = [{
    Module: {name: 'Test Module'}
  }]
  const result = await mockGraphqlQuery(query, overrides)
  console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "assignment": {
      "discussion": {
        "modules": [
          {"name": "Test Module"},
          {"name": "Test Module"}
        ]
      },
      "modules": [
        {"name": "Test Module"},
        {"name": "Test Module"}
      ]
    }
  }
}
```

If you only want to mock data for a single type instead of everywhere it shows
up in the graphql query, you can do so by mocking the parent that contains the
data. For example:

```javascript
async function example() {
  const query = gql`
    query MyQuery {
      assignment(id: "1") {
        discussion {
          modules {
            name
          }
        }
        modules {
          name
        }
      }
    }
  `
  const overrides = [{
    Module: {name: 'Test Module 1'}
    Discussion: {
      modules: [{name: "Test Module 2"}]
    }
  }]
  const result = await mockGraphqlQuery(query, overrides)
  console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "assignment": {
      "discussion": {
        "modules": [
          {"name": "Test Module 2"}
        ]
      },
      "modules": [
        {"name": "Test Module 1"},
        {"name": "Test Module 1"}
      ]
    }
  }
}
```

# Overriding lists of data
By default, any list type returns a list with two mocked elements in it. We can
customize this by passing in our own list of overrides for a specific field, where
we can control the number of elements in the list and the specific overrides for
each individual element:

```javascript
async function example() {
  const query = gql`
    query ExampleQuery {
      course(id: "1") {
        assignmentsConnection {
          nodes {
            _id
            name
          }
        }
      }
    }
  `

  // We are saying that these overrides should have a list of three items, one
  // with no specific overrides, one with the _id overridden, and one with the
  // _id and name overwritten.
  const overrides = {
    Assignment: {
      nodes: [
        {},
        {_id: '1'},
        {_id: '2', name: 'Test Assignment'}
      ]
    }
  }

  const result = await mockGraphqlQuery(query)
  console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "course": {
      "assignmentsConnection": {
        "nodes": [
          {"_id": "1532", "name": "Hello World"},
          {"_id": "1", "name": "Hello World"},
          {"_id": "2", "name": "Test Assignment"}
        ]
      }
    }
  }
}
```

# Mocking results of interfaces
When querying an interface that could return different data types (for example
the `node` and `legacyNode` interfaces), you will need to be explicity about what
type of data you want back from the mocked query. This is done by adding a
`__typename` override to the interface:

```javascript
async function example() {
  const query = gql`
    query MyQuery {
      node(id: "abc123") {
        ... on User {
          name
        }
      }
    }
  `
  const overrides = [{
    Node: {__typename: 'User'}
  }]
  const result = await mockGraphqlQuery(query, overrides)
  console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "node": {
      "name": "Hello World"
    }
  }
}
```


# Passing in variables
You can also pass in variables to your query via the third argument to
mockGraphqlQuery. For example:

```javascript
const query = gql`
  query TestQuery($assignmentID: ID!) {
    assignment(id: $assignmentID) {
	  name
    }
  }
`
const variables = {assignmentID: '1'}
const result = await mockGraphqlQuery(query, [], variables)
console.log(JSON.stringify(result, null, 2))
```

```JSON
{
  "data": {
    "assignment": {
      "name": "Hello World"
    }
  }
}
```

# Mocking apollo queries (<MockedProvider>)
Here is an example of using mockGraphqlQuery in conjunction with Apollo's
`MockedProvider`. This can be tweaked to the needs of your specific test:

```javascript
import {createCache} from '@canvas/apollo'
import mockGraphqlQuery from 'graphql-query-mock'

const ASSIGNMENT_QUERY = gql`
  query AssignmentQuery($assignmentID: ID!) {
    assignment(id: $assignmentID) {
      name
    }
  }
`

async function makeMocks() {
  const variables = {assignmentID: '1'}
  const overrides = {Assignment: {name: 'foobarbaz'}}
  const result = await mockGraphqlQuery(ASSIGNMENT_QUERY, overrides, variables)

  return [
    {
      request: {
        query: ASSIGNMENT_QUERY,
        variables
      },
      result
    }
  ]
}

it('does a thing', async () => {
  const mocks = await makeMocks()
  const {getByText} = render(
    <MockedProvider mocks={mocks} cache={createCache()}>
      <AssignmentQueryComponent />
    </MockedProvider>
  )

  // Rest of unit test
})
```

# Using functions as mocks resolvers
Instead of setting values for overrides, you can pass in a function instead:
```javascript
const overrides = {
  User: () => ({
    _id: () => Math.floor(Math.random() * 10)
  })
}
const result = await mockGraphqlQuery(query, overrides)
```
