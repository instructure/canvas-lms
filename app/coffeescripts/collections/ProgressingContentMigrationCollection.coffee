define [
  'underscore'
  'compiled/collections/ContentMigrationIssueCollection'
  'compiled/models/ContentMigrationProgress'
  'compiled/models/ProgressingContentMigration'
  'compiled/collections/PaginatedCollection'
], (_, MigrationIssueCollection, MigrationProgress, ProgressingContentMigration, PaginatedCollection) -> 
  class ProgressingContentMigrationCollection extends PaginatedCollection
    model: ProgressingContentMigration
    @optionProperty 'course_id'
    url: -> "/api/v1/courses/#{@course_id}/content_migrations"

    # Ensures the order of this collection is ranked by created_at date
    # We are returning 1, -1 and 0 because 'created_at' is date time
    # that can't be returns directly.
    comparator: (a, b) -> 
      if b.get('created_at') > a.get('created_at')
        1
      else if b.get('created_at') < a.get('created_at')
        -1
      else
        0
