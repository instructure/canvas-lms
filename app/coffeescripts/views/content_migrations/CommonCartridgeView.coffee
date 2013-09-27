define [
  'Backbone'
  'jst/content_migrations/CommonCartridge'
  'compiled/views/content_migrations/MigrationView'
],(Backbone, template, MigrationView) -> 
  class CommonCartridge extends MigrationView
    template: template

    @child 'chooseMigrationFile', '.chooseMigrationFile'
    @child 'questionBank', '.selectQuestionBank'
    @child 'dateShift', '.dateShift'
    @child 'selectContent', '.selectContent'
    @child 'overwriteAssessmentContent', '.overwriteAssessmentContent'
