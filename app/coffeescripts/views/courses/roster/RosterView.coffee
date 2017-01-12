define [
  'i18n!roster'
  'jquery'
  'Backbone'
  'jst/courses/roster/index'
  'compiled/views/ValidatedMixin'
  'compiled/models/GroupCategory'
  'jsx/add_people/add_people_app'
], (I18n, $, Backbone, template, ValidatedMixin, GroupCategory, AddPeopleApp) ->

  class RosterView extends Backbone.View

    @mixin ValidatedMixin

    @child 'usersView', '[data-view=users]'

    @child 'inputFilterView', '[data-view=inputFilter]'

    @child 'roleSelectView', '[data-view=roleSelect]'

    @child 'resendInvitationsView', '[data-view=resendInvitations]'

    @child 'rosterTabsView', '[data-view=rosterTabs]'

    @optionProperty 'roles'

    @optionProperty 'permissions'

    @optionProperty 'course'


    template: template

    els:
      '#addUsers': '$addUsersButton'
      '#createUsersModalHolder': '$createUsersModalHolder'

    afterRender: ->
      @$addUsersButton.on('click', @showCreateUsersModal.bind(this))
      @addPeopleApp = new AddPeopleApp(@$createUsersModalHolder[0], {
        courseId: (ENV.course && ENV.course.id) || 0,
        defaultInstitutionName: ENV.ROOT_ACCOUNT_NAME || '',
        roles: ENV.ALL_ROLES || [],
        sections: ENV.SECTIONS || [],
        onClose: @fetchOnCreateUsersClose,
        theme: if ENV.use_high_contrast then 'a11y' else 'canvas'
      })

    attach: ->
      @collection.on 'setParam deleteParam', @fetch

    fetchOnCreateUsersClose: =>
      @collection.fetch() if @addPeopleApp.usersHaveBeenEnrolled()

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

    showCreateUsersModal: ->
      @addPeopleApp.open();
