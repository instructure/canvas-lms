define [
  'underscore'
  'Backbone'
  'jst/groups/manage/groupUser'
], (_, {View}, template) ->

  class GroupUserView extends View

    @optionProperty 'canAssignToGroup'
    @optionProperty 'canEditGroupAssignment'

    tagName: 'li'

    className: 'group-user'

    template: template

    attach: ->
      @model.on 'change', @render, this

    afterRender: ->
      @$el.data('model', @model)

    highlight: ->
      @$el.addClass 'group-user-highlight'
      setTimeout =>
        @$el.removeClass 'group-user-highlight'
      , 1000

    toJSON: ->
      _.extend {}, this, super
