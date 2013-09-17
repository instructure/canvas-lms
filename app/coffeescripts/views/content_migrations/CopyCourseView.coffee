define [
  'Backbone'
  'underscore'
  'jst/content_migrations/CopyCourse'
  'compiled/views/content_migrations/MigrationView'
],(Backbone, _, template, MigrationView) -> 
  class CopyCourseView extends MigrationView
    template: template

    @child 'courseFindSelect', '.courseFindSelect'
    @child 'dateShift', '.dateShift'
    @child 'selectContent', '.selectContent'

    initialize: ->
      super
      @courseFindSelect.on 'course_changed', (course) =>
        @dateShift.updateNewDates(course)
