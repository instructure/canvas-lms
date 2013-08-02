define [
  'compiled/collections/ContentMigrationIssueCollection'
], (ContentMigrationIssueCollection) -> 
  module 'ContentMigrationIssueCollection',

  test "generates the correct fetch url", -> 
    course_id = 5
    content_migration_id = 10

    cmiCollection = new ContentMigrationIssueCollection [],
                      course_id: course_id
                      content_migration_id: content_migration_id
    equal cmiCollection.url(), "/api/v1/courses/#{course_id}/content_migrations/#{content_migration_id}/migration_issues"
                        
