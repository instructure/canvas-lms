define [
  'compiled/collections/AssignmentCollection'
  'compiled/views/CollectionView'
  'compiled/views/assignments/AssignmentListItemView'
  'jst/assignments/teacher_index/AssignmentGroupListItem'
], (AssignmentCollection, CollectionView, AssignmentListItemView, template) ->

  class AssignmentGroupListItemView extends CollectionView

    tagName: "li"
    itemView: AssignmentListItemView
    template: template

    initialize: ->
      @collection = new AssignmentCollection @model.get('assignments')
      super

    toJSON: -> @model.toJSON()
