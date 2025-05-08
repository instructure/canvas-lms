# GraphQL Connections in Canvas

This document explains how to work with GraphQL connections in Canvas, including pagination and the totalCount pattern.

## Basic Connections

Canvas follows the [Relay connection](http://graphql-ruby.org/relay/connections.html) spec for pagination. By convention, all paginated fields should have "Connection" as a suffix (e.g., "AssignmentsConnection").

### Basic Usage Example

```graphql
{
  course(id: "1") {
    assignmentsConnection(
      first: 10,      # page size
      after: "XYZ"    # endCursor from previous page
    ) {
      nodes {
        id
        name
      }
      pageInfo {
        endCursor     # use this for the next request's `after` value
        hasNextPage
      }
    }
  }
}
```

## Adding totalCount to Connections

Some connection types support a `totalCount` field in `pageInfo` that provides the total number of items in the connection, regardless of pagination limits. This is useful for displaying "Page X of Y" pagination interfaces.

### Example with totalCount

```graphql
{
  assignment(id: "1") {
    submissionsConnection(first: 10) {
      nodes {
        id
        state
      }
      pageInfo {
        hasNextPage
        totalCount    # total number of submissions (ignoring pagination)
      }
    }
  }
}
```

### How to Add totalCount to a Connection Type

1. **Add TotalCountConnection to the Type**

   Add `connection_type_class TotalCountConnection` to the target GraphQL type:

   ```ruby
   class AssignmentType < ApplicationObjectType
     connection_type_class TotalCountConnection
   end
   ```

2. **Test Thoroughly**

   **CRITICAL: Test extensively before deploying**

   Required tests:
   - Test with various data types (AR relations, arrays, etc.)
   - Test performance impact with large datasets
   - Test with complex queries (joins, subqueries, etc.)
   - Test error scenarios
   - Test with sharded data (Canvas-specific)

### Performance Considerations

#### When totalCount is Calculated

- **Lazy evaluation**: Only calculated when totalCount field is requested
- **Memoized**: Cached within the same PageInfo object to prevent duplicate queries
- **Error handling**: Returns `nil` on calculation errors (logged to Rails logger)

#### Performance Impact

**Low impact scenarios:**
- Small datasets (less than 1000 records)
- Simple queries without complex joins
- Already optimized ActiveRecord relations

**High impact scenarios:**
- Large datasets (greater than 10,000 records)
- Complex queries with multiple joins
- Queries involving cross-shard data access

### Currently Enabled Connections

As of this implementation, totalCount is enabled on:

- **SubmissionType connections** - For SpeedGrader submission counting
- **CommentBankItemType connections** - For comment bank item counting
- **SubmissionCommentType connections** - For submission comment counting

### Common Pitfalls

1. **Sharding Issues**: Canvas uses database sharding. Some queries may not work correctly across shards.

2. **Complex Query Performance**: COUNT queries can be expensive with complex WHERE clauses or JOINs.

3. **Array vs ActiveRecord::Relation**: Ensure your connection returns the expected data type.

### Conservative Philosophy

This implementation follows a "test first, enable second" approach:

1. **Explicit opt-in required** - No connections get totalCount automatically
2. **Validate each use case** - Test every connection type individually
3. **Document performance impact** - Measure and document the cost
4. **Monitor in production** - Watch for performance regressions

## Getting Help

If you encounter issues or need totalCount on a new connection:

1. **Search existing usage** - Look at SubmissionType, CommentBankItemType, etc.
2. **Test thoroughly** - Follow the testing guidelines above
3. **Consider performance** - Measure impact on realistic data
4. **Document your findings** - Update this file with lessons learned

Remember: **It's better to not have totalCount than to have a slow API.**