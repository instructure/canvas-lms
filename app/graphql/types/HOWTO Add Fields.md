# Adding Fields in GraphQL

## TL;DR

* Only add fields as they are needed
* Avoid `_id` columns
* Batch load any associations
* Check permissions as needed

## Basics

See the GraphQL Ruby [Field Guide](http://graphql-ruby.org/fields/introduction).

Add doc strings for fields when appropriate.  Don't add doc strings for
exceptionally obvious columns like name / id / description.

**TODO**: doc string style guide?

### Nullability

The return type of each field declares whether or not the field can return
null.  It is an error for a field to return null when the type signature says
otherwise.  Be cautious when declaring not-null:

* the underlying data store should have a not null constraint (or you should
  return a default value if it's not defined)
* even then, consider the likelihood of that field needing to be null in the
  future (changing a previously not-null column to nullable is a breaking
  change).

### Type

Field return types should be as specific as possible.  If a field has a finite
set of values (e.g. workflow_state), an enum should be used instead of a
string.

[Custom Scalars](https://graphql-ruby.org/type_definitions/scalars.html#custom-scalars)
are occasionally useful, but note that client support is limited (Apollo client
has no support for custom scalars at this time).

### Pagination and Lists

Most lists should be paginated.  Canvas follows the [Relay
connection](http://graphql-ruby.org/relay/connections.html) spec for
pagination.  By convention, all paginated fields should have "Connection" as a
suffix (e.g., "AssignmentsConnection").

Pagination is not necessary for lists that can't have un-bounded growth (like a
list of allowable submission types, for example).


## Only add fields as they are needed

**Don't add fields to the schema before they are needed by a feature.**  We may
want to model the data differently in the schema than how it is presented in
the REST API or database.

When adding a new type or field to GraphQL, don't duplicate everything from the
REST api.  Just add what you need.  This allows us to put the proper thought in
to each change and makes code review easier.

## Add edges, not ids

A GraphQL Schema should form a graph.  Instead of adding a `foo_id` column, add
a field that returns the object that id is referencing:

```ruby
  field :submission_id, ID, null: true              # don't do this
  field :submission, SubmissionType, null: true     # <----- good
```

## Batch load associations

To avoid N+1 queries, all database queries should be batched.  For simple cases
(like loading an association), this can be done with `load_association`.  See
`app/graphql/loaders/README.md` for more info.

```ruby
  def user
    object.user    # <-- BAD.  will result in N+1 queries
  end

  def user
    load_association(:user)  # GOOD. batches all calls into one query
  end

  def foo
    if object.course.grants_right? :manage  # `course` will cause a N+1 query
      ...
    end
  end

  def foo
    # `load_association` is doing this under the hood, you will sometimes need
    # to call the Batch Loaders directly
    Loaders::AssociationLoader.for(Enrollment, :course).load(object).then do
      if object.course.grants_right? :manage  # course is now batch-loaded
        ...
      end
    end
  end
```

## Check Permissions

Most fields are accessible to any user that has read access on an object, but
sometimes additional permission checks are needed (for example, not all users
can view another user's e-mail address).

Return `nil` for fields that a user doesn't have permission to access.

Refer to the REST API and/or legacy controllers to determine whether or not
the field you're adding might need additional permission checks.
