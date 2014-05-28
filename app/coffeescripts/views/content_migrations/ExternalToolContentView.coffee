define [
  'Backbone'
  'jst/content_migrations/ExternalToolContent'
  'compiled/views/content_migrations/MigrationView'
],(Backbone, template, MigrationView) ->
  class ExternalToolContentView extends MigrationView
    template: template

    @child 'externalToolLaunch', '.externalToolLaunch'
    @child 'selectContent', '.selectContent'
