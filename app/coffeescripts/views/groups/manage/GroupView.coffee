define [
  'i18n!GroupView'
  'underscore'
  'Backbone'
  'jst/groups/manage/group'
  'jquery.ajaxJSON'
  'compiled/jquery.rails_flash_notifications'
], (I18n, _, {View}, template) ->

  class GroupView extends View

    tagName: 'li'

    className: 'group well'

    template: template

    @optionProperty 'expanded'

    @child 'groupUsersView', '[data-view=groupUsers]'

    events:
      'click .expand-group': 'expand'
      'click .contract-group': 'contract'
      'click .delete-group': 'deleteGroup'

    attach: ->
      @model.on 'destroy', @remove, this

    deleteGroup: (e) =>
      e.preventDefault()
      return unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this group?')
      @model.destroy
        success: -> $.flashMessage I18n.t('flash.removed', 'Group successfully removed.')
        failure: -> $.flashError I18n.t('flash.removeError', 'Unable to remove the group. Please try again later.')

    toJSON: ->
      json = super
      json.summary = I18n.t "summary", { one: "1 student", other: "%{count} students"}, count: json.members_count
      json

    afterRender: ->
      @toggleVisibility()

    toggleVisibility: ->
      if @expanded
        @$('.expand-group').addClass 'hidden'
        @$('.contract-group').removeClass 'hidden'
        @groupUsersView.$el.removeClass 'hidden'
      else
        @$('.expand-group').removeClass 'hidden'
        @$('.contract-group').addClass 'hidden'
        @groupUsersView.$el.addClass 'hidden'

    expand: (e) ->
      e.preventDefault()
      @expanded = true
      @toggleVisibility()

    contract: (e) ->
      e.preventDefault()
      @expanded = false
      @toggleVisibility()
