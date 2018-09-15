# Canvas API Deprecation
In the examples below, the deprecation dates should follow these rules:
  * The `NOTICE` date should be the date that the deprecation warning
    will first be visible in production.
  * To determine the `EFFECTIVE` date, add 90 days to the `NOTICE`
    date. If that day is a production release date, use that date. If that
    date is _not_ a production release date, use the next production release
    date after that date.
  * Both dates should be formatted as YYYY-MM-DD.

## API Method Deprecation
To deprecate an API method, use the `@deprecated_method` tag. You must provide
a `NOTICE` date and an `EFFECTIVE` date for the deprecation, along with a
description for the deprecation.

### Deprecate a method with a replacement
```ruby
# @deprecated_method NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
#   A description of the deprecated method and why we're deprecating it.
#   Use {api:FooController#bar_action Foo#bar_action} instead.
def foo_action
end

def bar_action
end
```

### Deprecate a method without a replacement
```ruby
  # @deprecated_method NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
  #   A description of the deprecated method and why we're deprecating it.
  def foo_action
  end

```

## API Model Deprecation
To deprecate an API model, add the `deprecated`, `deprecation_notice`,
`deprecation_effective`, and `deprecation_description` keys. These keys can be
applied at the base model level to deprecate the entire model, or they can be
applied at the property level to individually deprecate model properties.

### Deprecate an entire API model
```ruby
# @model Foo
#     {
#       "id": "Foo",
#       "description": "A description.",
#       "deprecated": true,
#       "deprecation_notice": "YYYY-MM-DD",
#       "deprecation_effective": "YYYY-MM-DD",
#       "deprecation_description": "A description of the deprecation.",
#       "properties": {
#         "bar": {
#           "description": "A property.",
#           "example": "baz",
#           "type": "string"
#         }
#       }
#     }
```

### Deprecate an API model property
```ruby
# @model Foo
#     {
#       "id": "Foo",
#       "description": "A description.",
#       "properties": {
#         "bar": {
#           "deprecated": true,
#           "deprecation_notice": "YYYY-MM-DD",
#           "deprecation_effective": "YYYY-MM-DD",
#           "deprecation_description": "A description of the deprecation.",
#           "description": "A property.",
#           "example": "baz",
#           "type": "string"
#         }
#       }
#     }
```

## API Argument Deprecation
To deprecate an API argument, rename the `@argument` tag to
`@deprecated_argument`. You must provide a `NOTICE` date and an `EFFECTIVE` date
for the deprecation, along with a description for the deprecation.

Before:
```ruby
# @argument foo [Required, String]
#   A description of the argument.
```

After:
```ruby
# @deprecated_argument foo [Required, String] NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
#   A description of the argument, along with a description of the deprecation.
```

## API Response Field Deprecation
To deprecate an API response field, rename the `@response_field` tag to
`@deprecated_response_field`. You must provide a `NOTICE` date and an
`EFFECTIVE` date for the deprecation, along with a description for the
deprecation.

Before:
```ruby
# @response_field foo
#   A description of the response field.
```

After:
```ruby
# @deprecated_response_field foo NOTICE YYYY-MM-DD EFFECTIVE YYYY-MM-DD
#   A description of the response field, along with a description of the
#   deprecation.
```
