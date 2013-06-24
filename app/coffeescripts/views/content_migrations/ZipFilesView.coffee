define [
  'Backbone'
  'jst/content_migrations/ZipFiles'
  'compiled/views/content_migrations/MigrationView'
],(Backbone, template, MigrationView) -> 
  class ZipFiles extends MigrationView
    template: template

    @child 'chooseMigrationFile', '.chooseMigrationFile'
    @child 'folderPicker', '.folderPicker'
