define [
  'Backbone'
  'jst/content_migrations/QTIZip'
  'compiled/views/content_migrations/MigrationView'
],(Backbone, template, MigrationView) -> 
  class QTIZipView extends MigrationView
    template: template

    @child 'chooseMigrationFile', '.chooseMigrationFile'
    @child 'questionBank', '.selectQuestionBank'
    @child 'overwriteAssessmentContent', '.overwriteAssessmentContent'
