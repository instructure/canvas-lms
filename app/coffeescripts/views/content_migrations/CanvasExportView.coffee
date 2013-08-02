define [
  'Backbone'
  'jst/content_migrations/CanvasExport'
  'compiled/views/content_migrations/MigrationView'
], (Backbone, template, MigrationView) -> 
  class CanvasExportView extends MigrationView
    template: template

    @child 'chooseMigrationFile', '.chooseMigrationFile'
    @child 'dateShift', '.dateShift'
    @child 'selectContent', '.selectContent'
