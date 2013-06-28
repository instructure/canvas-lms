define [
  'Backbone'
  'jst/assignments/teacher_index/AssignmentListItem'
], (Backbone, template) ->

  class AssignmentListItemView extends Backbone.View
    tagName: "li"
    template: template
    toJSON: -> @model.toView()
