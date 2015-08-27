define [
  'i18n!roster'
  'jquery'
  'underscore'
  'Backbone'
  'jst/courses/roster/rosterUser'
  'compiled/views/courses/roster/EditSectionsView'
  'compiled/views/courses/roster/InvitationsView'
  'compiled/views/courses/roster/LinkToStudentsView'
  'compiled/str/underscore'
  'str/htmlEscape'
  'compiled/jquery.kylemenu'
], (I18n, $, _, Backbone, template, EditSectionsView, InvitationsView, LinkToStudentsView, toUnderscore, h) ->

  editSectionsDialog = null
  linkToStudentsDialog = null
  invitationDialog = null

  class RosterUserView extends Backbone.View

    tagName: 'tr'

    className: 'rosterUser al-hover-container'

    template: template

    events:
      'click .admin-links [data-event]': 'handleMenuEvent'
      'focus *': 'focus'
      'blur *': 'blur'

    attach: ->
      @model.on 'change', @render, this

    initialize: (options) ->
      super
      # assumes this model only has enrollments for 1 role
      @model.currentRole = @model.get('enrollments')[0]?.role

      @$el.attr 'id', "user_#{options.model.get('id')}"
      @$el.addClass e.role for e in @model.get('enrollments')

    toJSON: ->
      json = super
      @permissionsJSON json
      @observerJSON json
      json

    permissionsJSON: (json) ->
      json.url = "#{ENV.COURSE_ROOT_URL}/users/#{@model.get('id')}"
      json.isObserver = @model.hasEnrollmentType('ObserverEnrollment')
      json.isPending = @model.pending(@model.currentRole)
      json.canEditSections = not _.isEmpty @model.sectionEditableEnrollments()
      json.canLinkStudents = json.isObserver && !ENV.course.concluded
      json.canViewLoginIdColumn = ENV.permissions.manage_admin_users or ENV.permissions.manage_students
      json.canViewLoginId =
      json.canManage =
        if _.any(['TeacherEnrollment', 'DesignerEnrollment', 'TaEnrollment'], (et) => @model.hasEnrollmentType(et))
          ENV.permissions.manage_admin_users
        else
          ENV.permissions.manage_students


    observerJSON: (json) ->
      if json.isObserver
        observerEnrollments = _.filter json.enrollments, (en) -> en.type == 'ObserverEnrollment'
        json.enrollments = _.reject json.enrollments, (en) -> en.type == 'ObserverEnrollment'
        json.sections = _.map json.enrollments, (en) -> ENV.CONTEXTS['sections'][en.course_section_id]

        users = {}
        if observerEnrollments.length == 1 && !observerEnrollments[0].observed_user
          users[''] = {name: I18n.t('nobody', 'nobody')}
        else
          for en in observerEnrollments
            continue unless en.observed_user
            user = en.observed_user
            users[user.id] ||= user

        for id, user of users
          ob = {role: I18n.t('observing_user', 'Observing: %{user_name}', user_name: user.name)}
          json.enrollments.push ob

    resendInvitation: (e) ->
      invitationDialog ||= new InvitationsView
      invitationDialog.model = @model
      invitationDialog.render().show()

    editSections: (e) ->
      editSectionsDialog ||= new EditSectionsView
      editSectionsDialog.model = @model
      editSectionsDialog.render().show()

    linkToStudents: (e) ->
      linkToStudentsDialog ||= new LinkToStudentsView
      linkToStudentsDialog.model = @model
      linkToStudentsDialog.render().show()

    removeFromCourse: (e) ->
      return unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this user?')
      @$el.hide()
      success = =>
        # TODO: change the count on the search roles drop down
        $.flashMessage I18n.t('flash.removed', 'User successfully removed.')
      failure = =>
        @$el.show()
        $.flashError I18n.t('flash.removeError', 'Unable to remove the user. Please try again later.')
      deferreds = _.map @model.get('enrollments'), (e) ->
        $.ajaxJSON "#{ENV.COURSE_ROOT_URL}/unenroll/#{e.id}", 'DELETE'
      $.when(deferreds...).then success, failure

    handleMenuEvent : (e) =>
      @blur()
      e.preventDefault()
      method = $(e.currentTarget).data 'event'
      @[method].call this, e

    focus: =>
      @$el.addClass('al-hover-container-active table-hover-row')

    blur: =>
      @$el.removeClass('al-hover-container-active table-hover-row')
