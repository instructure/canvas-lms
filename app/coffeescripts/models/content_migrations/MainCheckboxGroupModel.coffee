define [
  'Backbone'
  'compiled/models/ProgressingContentMigration'
], (Backbone, ProgressingMigration) -> 
  class MainCheckboxGroupModel extends Backbone.Model

    # Set the migrationModel. If this model comes from a collection, check
    # the collection for a migration model else see if the user passed one 
    # in. You must pass a progressing migration model in.
    initialize: (attr, options) -> 
      super
      @migrationModel = @collection?.migrationModel || attr.migrationModel
      unless @migrationModel instanceof ProgressingMigration
        throw "Must provide a ProgressingContextMigration model"
