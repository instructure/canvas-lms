# GraphQL Errors

The GraphQL spec describes a top-level errors key
(https://facebook.github.io/graphql/June2018/#sec-Errors).  It is useful
for fatal errors that prevent an operation from returning data.  The Ruby
GraphQL gem automatically populates `errors` whenever there is a
synatactical error, or when a resolver returns a `GraphQL::ExecutionError`.

## Mutation Errors

For fatal errors (like lack of permission), we return a
`GraphQL::ExecutionError` (populating the top-level errors field).

There are a number of reasons why we wouldn't want to use the top-level
errors field for user-facing errors (like validations).

* There are potentially many validation errors per model attribute, but
  once the system encounters one `GraphQL::ExecutionError` it will stop
  processing that mutation.
* Apollo client (and probably other GraphQL clients) have special treatment
  for the top-level errors field which is probably not ideal for
  displaying validation errors to the user.
* Validation errors are meant to be displayed to the user, whereas system
  errors are not likely to be shown.

Instead, the common solution for handling these types of errors is to
include an `errors` key as part of the mutation response.  There doesn't
yet seem to be any consensus around a common format for the shape of these
errors.

The primary source of validation errors in Canvas are the rails validations
defined in our models.  The simplest way to expose those would be to add an
`errors` key that is a list of {attribute, message} pairs.  Some
validations do not directly correspond to a GraphQL field (either because
it's not a field exposed in GraphQL, or the attribute has been renamed), so
we'll need way to either map those attribute names appropriately, or return
a generic object-wide error message (generic error messages could be
indicated by any error with a null attribute).

A different way to express errors would be to have a mutation-specific
error type for each mutation.  The error shape could then look something
like {attribute1 => [message1, message2], attribute2 => [message1], ...}.
The big downside to this approach is that consuming this form of errors
would require enumerating all possible attributes at query time which feels
burdensome.

## A Note on Inst UI

Inst UI form components take a "message" attribute that is used to display
errors.  We will want some kind of general purpose helper function that
extracts the validation errors from a mutation response and bundles them in
a format more consumable by Instructure UI.
