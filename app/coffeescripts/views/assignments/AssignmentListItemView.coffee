define [
  'Backbone'
  'compiled/views/PublishIconView'
  'jst/assignments/teacher_index/AssignmentListItem'
], (Backbone, PublishIconView, template) ->

  class AssignmentListItemView extends Backbone.View
    tagName: "li"
    template: template

    @child 'publishIconView', '[data-view=publish-icon]'

    initialize: ->
      super
      @publishIconView = new PublishIconView(model: @model)
      @model.on('change:published', @upatePublishState)

    toJSON: ->
      @model.toView()

    upatePublishState: =>
      @$('.ig-row').toggleClass('ig-published', @model.get('published'))
