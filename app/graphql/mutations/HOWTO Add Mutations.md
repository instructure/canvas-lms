# HOWTO Add a Mutation

Mutations are used for creates/updates/deletes in GraphQL. Creating a mutation
is similar to adding a new Type.

Create a new mutation by inheriting from the `Mutations::BaseMutation` class.
`BaseMutation` does the following:

- creates a new mutation-specific input object.  Any arguments defined for the
  mutation will be fields on this input object.
- adds an `errors` resonse field (more on that below).
- passes the input object to `resolve` on execution.

After creating a new mutation class, add a field for the new mutation to
`Types::MutationType`.

## `resolve`

When a mutation is executed, the mutation class's `resolve` method is executed.
A successful mutation should return a hash containing keys for each response
field in the mutation.

The `BaseMutation#errors_for` can be used to return AR validation errors, e.g.:

    `return errors_for(assignment)`

## Batch Loading

Mutations generally do not benefit from batch loading.  Mutations run
sequentially (not in parallel like queries).  Because a mutation mutates
state, the cache maintained by graphql-batch is also cleared between each
mutation.  Feel free to use the standard AR association helpers instead of
batch loaders when writing a mutation.

## Error handling

There are two classes of errors to consider when working with mutations:

1. system errors: These should be handled with the usual
   GraphQL::ExecutionError workflow.
2. invalid user input: This is what the `errors` response field is for.  It
   should be considered exceedingly strange to check for validation errors in
   `resolve`  (typically you will want to get the validation errors from
   Active Record's normal validation stuff).

## Sharing Code

A createFoo and updateFoo mutation will probably be very similar.  See
`Mutations::CreateAssignment`/`Mutations::UpdateAssignment` for an example of
how to share common code.

## Mutation Audit Log

A mutation audit log entry is recorded for every output field of a mutation.
Log entries are indexed by the object's `asset_string`.  Sometimes it's
helpful to log against a different object (for example, since `PostPolicy`
object's are unfamiliar to user's of the audit log, those log entries are
recorded to the associated course/assignment instead.  If a mutation has a
response field `foo`, it can be overridden by defining a `foo_log_entry` class
method:

```
  def self.foo_log_entry(foo, _context)
    foo.bar # <-- will log to `bar_1234` instead of `foo_567'
  end
```

The context passed to that method is the graphql execution context.  (This can
be useful for retrieving an object that was deleted in a delete mutation--see
the code base for examples).

## delete Mutations

A delete mutation should *not* return the object that was deleted.  Returning
the deleted object would cause errors if a user selects fields on the response
that are tied to (formerly) associated objects.  Instead return something like
the deleted object's id.
