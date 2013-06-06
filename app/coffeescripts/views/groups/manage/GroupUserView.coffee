define [
  'underscore'
  'Backbone'
  'jst/groups/manage/groupUser'
], (_, {View}, template) ->

  class GroupUserView extends View

    @optionProperty 'canAssignToGroup'

    tagName: 'li'

    className: 'groupUser'

    template: template

    attach: ->
      @model.on 'change', @render, this

    toJSON: ->
      _.extend {}, this, super

