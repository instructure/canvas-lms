define [
  'Backbone'
  'jst/modules/item_types/SelectFileView'
], (Backbone, template) ->
  class SelectFileView extends Backbone.View
    template: template
