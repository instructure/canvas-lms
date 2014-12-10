define [
  'i18n!groups'
  'underscore'
  'Backbone'
  'jst/groups/manage/groupUser'
], (I18n, _, {View}, template) ->

  class GroupUserView extends View

    @optionProperty 'canAssignToGroup'
    @optionProperty 'canEditGroupAssignment'

    tagName: 'li'

    className: 'group-user'

    template: template
    attributes:
      "data-tooltip": "top"

    els:
      '.al-trigger': '$userActions'

    closeMenu: ->
      @$userActions.data('kyleMenu')?.$menu.popup 'close'

    attach: ->
      @model.on 'change', @render, this

    afterRender: ->
      @$el.attr("title", I18n.t('Sections: %{sections}', sections: @model.get('sections')))
      @$el.data('model', @model)

    highlight: ->
      @$el.addClass 'group-user-highlight'
      setTimeout =>
        @$el.removeClass 'group-user-highlight'
      , 1000

    toJSON: ->
      _.extend {groupId: @model.get('group')?.id}, this, super

    isLeader: ->
      @model.get('group')?.get?('leader')?.id == @model.get('id')
