define [
  'compiled/collections/PaginatedCollection'
], (PaginatedCollection) -> 
  class ContentMigrationIssueCollection extends PaginatedCollection
    @optionProperty 'course_id'
    @optionProperty 'content_migration_id'

    url: -> "/api/v1/courses/#{@course_id}/content_migrations/#{@content_migration_id}/migration_issues"

