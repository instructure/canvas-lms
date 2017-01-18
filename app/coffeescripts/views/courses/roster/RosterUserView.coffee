define [
  'i18n!roster'
  'jquery'
  'underscore'
  'Backbone'
  'jst/courses/roster/rosterUser'
  'compiled/views/courses/roster/EditSectionsView'
  'compiled/views/courses/roster/EditRolesView'
  'compiled/views/courses/roster/InvitationsView'
  'compiled/views/courses/roster/LinkToStudentsView'
  'compiled/str/underscore'
  'str/htmlEscape'
  'compiled/jquery.kylemenu'
  'jquery.disableWhileLoading'
], (I18n, $, _, Backbone, template, EditSectionsView, EditRolesView, InvitationsView, LinkToStudentsView, toUnderscore, h) ->

  editSectionsDialog = null
  editRolesDialog = null
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
      json.isInactive = @model.inactive()
      if !json.isInactive
        json.enrollments = _.reject json.enrollments, (en) -> en.enrollment_state == 'inactive' # if not _completely_ inactive, treat the inactive enrollments as deleted

      json.canRemoveUsers = _.all @model.get('enrollments'), (e) -> e.can_be_removed
      json.canResendInvitation = !json.isInactive

      if json.canRemoveUsers && !ENV.course.concluded
        json.canEditRoles = !(_.any(@model.get('enrollments'), (e) -> (e.type == 'ObserverEnrollment' && e.associated_user_id)))

      json.canEditSections = !json.isInactive && !(_.isEmpty(@model.sectionEditableEnrollments()))
      json.canLinkStudents = json.isObserver && !ENV.course.concluded
      json.canViewLoginIdColumn = ENV.permissions.manage_admin_users || ENV.permissions.manage_students
      json.canViewSisIdColumn = ENV.permissions.read_sis
      json.canManage =
        if _.any(['TeacherEnrollment', 'DesignerEnrollment', 'TaEnrollment'], (et) => @model.hasEnrollmentType(et))
          ENV.permissions.manage_admin_users
        else
          ENV.permissions.manage_students
      json.customLinks = @model.get('custom_links')

      if json.canViewLoginIdColumn
        json.canViewLoginId = true
        json.login_id = json.login_id

      if json.canViewSisIdColumn
        json.canViewSisId = true
        json.sis_id = json.sis_user_id

    observerJSON: (json) ->
      if json.isObserver
        observerEnrollments = _.filter json.enrollments, (en) -> en.type == 'ObserverEnrollment'
        json.enrollments = _.reject json.enrollments, (en) -> en.type == 'ObserverEnrollment'

        json.sections = _.map json.enrollments, (en) -> ENV.CONTEXTS['sections'][en.course_section_id]

        users = {}
        if observerEnrollments.length >= 1 && _.all(observerEnrollments, (enrollment) -> !enrollment.observed_user)
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

    editRoles: (e) ->
      editRolesDialog ||= new EditRolesView
      editRolesDialog.model = @model
      editRolesDialog.render().show()

    linkToStudents: (e) ->
      linkToStudentsDialog ||= new LinkToStudentsView
      linkToStudentsDialog.model = @model
      linkToStudentsDialog.render().show()

    deactivateUser: ->
      return unless confirm I18n.t('Are you sure you want to deactivate this user? They will be unable to participate in the course while inactive.')
      deferreds = []
      for en in @model.get('enrollments')
        if en.enrollment_state != 'inactive'
          url = "/api/v1/courses/#{ENV.course.id}/enrollments/#{en.id}?task=deactivate"
          en.enrollment_state = 'inactive'
          deferreds.push($.ajaxJSON(url, 'DELETE'))

      $('.roster-tab').disableWhileLoading(
        $.when(deferreds...)
          .done =>
            @render()
            $.flashMessage I18n.t('User successfully deactivated')
          .fail ->
            $.flashError I18n.t("Something went wrong while deactivating the user. Please try again later.")
      )

    reactivateUser: ->
      deferreds = []
      for en in @model.get('enrollments')
        url = "/api/v1/courses/#{ENV.course.id}/enrollments/#{en.id}/reactivate"
        en.enrollment_state = 'active'
        deferreds.push($.ajaxJSON(url, 'PUT'))

      $('.roster-tab').disableWhileLoading(
        $.when(deferreds...)
        .done =>
          @render()
          $.flashMessage I18n.t('User successfully re-activated')
        .fail ->
          $.flashError I18n.t("Something went wrong re-activating the user. Please try again later.")
      )

    removeFromCourse: (e) ->
      return unless confirm I18n.t('Are you sure you want to remove this user?')
      @$el.hide()
      success = =>
        # TODO: change the count on the search roles drop down
        $.flashMessage I18n.t('User successfully removed.')
        $previousRow = @$el.prev(':visible')
        $focusElement = if ($previousRow.length)
          $previousRow.find('.al-trigger')
        else
          # For some reason, VO + Safari sends the virtual cursor to the window
          # instead of to this element, this has the side effect of making the
          # flash message not read either in this case :(
          # Looking at the Tech Preview version of Safari, this isn't an issue
          # so it should start working once new Safari is released.
          $('#addUsers')
        $focusElement.focus()


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
