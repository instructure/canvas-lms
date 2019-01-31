GraphQL Batch Loaders
=====================

## Motivation

In a Canvas REST API end-point.  N+1 Queries are commonly found, but easy to
avoid.  When a controller action runs, we know what data is being requested and
can preload appriopriately.

As a GraphQL type resolver executes, it is too late to preload data.  Consider
the following query:

```
query assignmentsAndGroupSets {
  course(id: "1") {
    assignmentsConnection {
      nodes {
        id
        groupSet {  # N+1 !?
          name
        }
      }
    }
  }
}
```

When resolving the `groupSet` field above, the only context we have is an
individual assignment.  It's not possible to use the normal
`scope.preload(...)` approach of preventing N+1 queries.

To solve this problem, instead of returning an ActiveRecord instance in the
`groupSet` resolver, we use the `graphql-batch` gem to return a deferred value.

Example:

```ruby
# bad example
def group_set
  assignment.group_set  # this will result in N+1 queries
end

# good example
def group_set
  Loaders::AssociationLoader.for(Assignment, :group_category).
    load(assignment).
    then(&:group_category)
end

# short (but still good) example
def group_set
  # a helper method is provided since this is such a common use-case
  load_association(:group_category)
end

# bad example (async confusion)
def group_set
  group_set = nil

  Loaders::AssociationLoader.for(Assignment, :group_category).
    load(assignment).
    then {
      group_set = assignment.group_category
    }

  group_set # this will still be nil when at this point
  # (you must return a promise when dealing with loaders)
end
```

See [graphql-batch](https://github.com/Shopify/graphql-batch) for more
information.

## Available Batch Loaders

`Loaders::AssociationLoader` can be used for any instances that would have used
`.preloads` or `ActiveRecord::Associations::Preloader.new` in the past (it uses
those methods under the hood).

`Loaders::IDLoader` and `Loaders::ForeignKeyLoader` can be used to batch-load
records by id.

It may also be necessary to write your own batch loader from time to time.

## How To Write a New Batch Loader

Writing a new batch loader is easy.  At a minimum, you must define a class that
inherits from `GraphQL::Batch::Loader` which defines a `perform` method (and
probably a constructor).

Example:

```ruby
class CustomLoader < GraphQL::Batch::Loader
  def initialize(*args)
    # constructor arguments can be used to provide information in the perform
    # method.  they also define "buckets" for batching
  end

  def perform(objects)
    results = do_something_to_batch_load_data
    objects.each { |o|
      # fulfill provides the value for the deferred object we returned in
      # our resolver
      fulfill(o, results[o])
    }
  end
end
```
