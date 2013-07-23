define [
  'Backbone'
  'jst/assignments/NeverDrop'
], (Backbone, neverDropTemplate) ->

  class NeverDrop extends Backbone.View
    className: 'never_drop_rule'
    template: neverDropTemplate
