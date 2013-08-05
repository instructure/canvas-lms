define [
  'Backbone'
  'jst/assignments/teacher_index/NeverDrop'
], (Backbone, neverDropTemplate) ->

  class NeverDrop extends Backbone.View
    className: 'never_drop_rule'
    template: neverDropTemplate
