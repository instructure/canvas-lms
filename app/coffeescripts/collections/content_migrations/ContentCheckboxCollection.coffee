define [
  'Backbone'
  'compiled/models/content_migrations/ContentCheckbox'
], (Backbone, CheckboxModel) -> 
  class ContentCheckboxCollection extends Backbone.Collection
    @optionProperty 'courseID'
    @optionProperty 'migrationID'
    @optionProperty 'isTopLevel'
    @optionProperty 'ariaLevel'

    # This is the default url. This can change for sub-level checkbox collections
    url: -> "/api/v1/courses/#{@courseID}/content_migrations/#{@migrationID}/selective_data"
    model: CheckboxModel
