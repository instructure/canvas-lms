define [
  'jquery'
  'Backbone'
  'jst/content_migrations/subviews/SelectContentCheckbox'
], ($, Backbone, template) -> 
  class SelectContentCheckbox extends Backbone.View
    template: template

    events: 
      'click #selectContentCheckbox' : 'updateModel'

    updateModel: (event) -> 
      if($(event.target).is(':checked'))
        @model.set 'selective_import', true
      else
        @model.set 'selective_import', false
