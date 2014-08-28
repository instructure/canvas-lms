define [
  'i18n!roster'
  'jquery'
  'Backbone'
  'jst/courses/roster/index'
  'compiled/views/ValidatedMixin'
  'compiled/models/GroupCategory'
], (I18n, $, Backbone, template, ValidatedMixin, GroupCategory) ->

  class RosterView extends Backbone.View

    @mixin ValidatedMixin

    @child 'usersView', '[data-view=users]'

    @child 'inputFilterView', '[data-view=inputFilter]'

    @child 'roleSelectView', '[data-view=roleSelect]'

    @child 'createUsersView', '[data-view=createUsers]'

    @child 'resendInvitationsView', '[data-view=resendInvitations]'

    @child 'rosterTabsView', '[data-view=rosterTabs]'

    @optionProperty 'roles'

    @optionProperty 'permissions'

    @optionProperty 'course'


    template: template

    els:
      '#addUsers': '$addUsersButton'

    afterRender: ->
      # its a child view so it gets rendered automatically, need to stop it
      @createUsersView.hide()
      # its trigger would not be rendered yet, set it manually
      @createUsersView.setTrigger @$addUsersButton

    attach: ->
      @collection.on 'setParam deleteParam', @fetch
      @createUsersView.on 'close', @fetchOnCreateUsersClose

    fetchOnCreateUsersClose: =>
      @collection.fetch() if @createUsersView.hasUsers()

    fetch: =>
      @lastRequest?.abort()
      @lastRequest = @collection.fetch().fail @onFail

    course_id: ->
      ENV.context_asset_string.split('_')[1]

    canAddCategories: ->
      ENV.canManageCourse

    toJSON: -> this

    onFail: (xhr) =>
      return if xhr.statusText is 'abort'
      parsed = $.parseJSON xhr.responseText
      message = if parsed?.errors?[0].message is "3 or more characters is required"
        I18n.t('greater_than_three', 'Please enter a search term with three or more characters')
      else
        I18n.t('unknown_error', 'Something went wrong with your search, please try again.')
      @showErrors search_term: [{message}]

