define [
  'Backbone'
  'jst/content_migrations/MoodleZip'
  'compiled/views/content_migrations/MigrationView'
], (Backbone, template, MigrationView) -> 
  class MoodleZip extends MigrationView
    template: template

    @child 'chooseMigrationFile', '.chooseMigrationFile'
    @child 'questionBank', '.selectQuestionBank'
    @child 'dateShift', '.dateShift'
    @child 'selectContent', '.selectContent'
