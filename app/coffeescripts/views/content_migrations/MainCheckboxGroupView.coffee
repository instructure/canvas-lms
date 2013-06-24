define [
  'Backbone'
  'jst/content_migrations/MainCheckboxGroup'
], (Backbone, template) -> 
  class MainCheckboxGroupView extends Backbone.View
    template: template

    events: 
      'change [type=checkbox]' : 'updateMigration'

    initialize: -> 
      super
      @migrationModel = @model.migrationModel

    # Updates the migration to either remove or add 
    # the properties set by clicking the checkbox
    #
    # @api private

    updateMigration: (event) -> 
      if($(event.target).is(':checked'))
        @setMigrationCopy(true)
      else
        @setMigrationCopy(false)

    # Preserves all existing data in the "copy" hash. Adds/removes 
    # the option you want
    # 
    # @api private

    setMigrationCopy: (value) -> 
      copy = @migrationModel.get('copy') || {}
      if value
        copy[@property()] = value
      else
        delete copy[@property()]

      @migrationModel.set 'copy', copy 

    # Extracts the property value from the nested "copy" hash. 
    #
    # @api private

    property: -> 
      unparsedProperty = @model.get('property')
      property = unparsedProperty.match(/(?:\[)(.*)(?:\])/)[1] # Regex to get between [ and ]
      property
      

