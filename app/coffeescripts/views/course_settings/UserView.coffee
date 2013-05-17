define [
  'i18n!course_settings'
  'jquery'
  'underscore'
  'Backbone'
  'compiled/views/course_settings/EditSectionsView'
  'compiled/views/course_settings/InvitationsView'
  'compiled/views/course_settings/LinkToStudentsView'
  'compiled/models/User'
  'jst/courses/settings/UserView'
  'compiled/str/underscore'
  'str/htmlEscape'
  'compiled/jquery.whenAll'
  'compiled/jquery.kylemenu'
  'compiled/jquery.rails_flash_notifications'
], (I18n, $, _, Backbone, EditSectionsView, InvitationsView, LinkToStudentsView, User, userViewTemplate, toUnderscore, h) ->

  editSectionsDialog = null
  linkToStudentsDialog = null
  invitationDialog = null

  class UserView extends Backbone.View
    initialize: (attributes, options) ->
      super
      @role = attributes['role']
      @role_tag = attributes['role_tag']

    tagName: 'li'

    className: 'user admin-link-hover-area'

    events:
      'click .admin-links [data-event]': 'handleMenuEvent'

    render: =>
      @$el.disableWhileLoading @data().done (data) =>
        @$el.addClass data.typeClass
        @$el.attr 'id', "user_#{data.id}"
        @$el.attr 'title',  if data.isPending
                              I18n.t 'pending', 'pending acceptance'
                            else
                              "#{data.name}: #{data.login_id}"
        @$el.html userViewTemplate(data)
      this

    data: ->
      dfd = $.Deferred()
      data = $.extend @model.toJSON(),
        url: "#{ENV.COURSE_ROOT_URL}/users/#{@model.get('id')}"
        isObserver: @model.hasEnrollmentType('ObserverEnrollment', @role)
        isDesigner: @model.hasEnrollmentType('DesignerEnrollment', @role)
        isPending: @model.pending(@role)
      data.canRemove =
        if _.any(['TeacherEnrollment', 'DesignerEnrollment', 'TaEnrollment'], (et) => @model.hasEnrollmentType(et, @role))
          ENV.PERMISSIONS.manage_admin_users
        else
          ENV.PERMISSIONS.manage_students
      data.enrollments = _.filter data.enrollments, (en) => en.role == @role

      for en in data.enrollments when ! data.isDesigner
        en.pending = @model.pending()
        en.typeClass = toUnderscore en.type
        section = ENV.CONTEXTS['sections'][en.course_section_id]
        en.sectionTitle = h section.name if section
      if data.isObserver
        users = {}

        for en in data.enrollments
          if en.observed_user && _.any(en.observed_user.enrollments)
            user = en.observed_user
            user.pending = en.enrollment_state in ['creation_pending', 'invited']
            users[user.id] ||= user

        data.enrollments = []
        for id, user of users
          ob = {pending: user.pending}
          ob.sectionTitle = I18n.t('observing_user', '*Observing*: %{user_name}', wrapper: '<i>$1</i>', user_name: user.name)
          for en in user.enrollments
            section = ENV.CONTEXTS['sections'][en.course_section_id]
            ob.sectionTitle += h(I18n.t('#support.array.words_connector') + section.name) if section
          data.enrollments.push ob

      dfd.resolve(data)
      dfd.promise()

    reload: =>
      @$el.disableWhileLoading @model.fetch
        data: ENV.USER_PARAMS
        success: => @render()

    resendInvitation: (e) ->
      invitationDialog ||= new InvitationsView
      invitationDialog.model = @model
      invitationDialog.render().show()

    editSections: (e) ->
      editSectionsDialog ||= new EditSectionsView
      editSectionsDialog.model = @model
      editSectionsDialog.role = @role
      editSectionsDialog.off 'updated'
      editSectionsDialog.on 'updated', @reload
      editSectionsDialog.render().show()

    linkToStudents: (e) ->
      linkToStudentsDialog ||= new LinkToStudentsView
      linkToStudentsDialog.model = @model
      linkToStudentsDialog.role = @role
      linkToStudentsDialog.off 'updated'
      linkToStudentsDialog.on 'updated', @reload
      linkToStudentsDialog.render().show()

    removeFromCourse: (e) ->
      return unless confirm I18n.t('delete_confirm', 'Are you sure you want to remove this user?')
      @$el.hide()
      success = =>
        $(c).text(parseInt($(c).text()) - 1) for c in $(".#{@role_tag}_count")
        $.flashMessage I18n.t('flash.removed', 'User successfully removed.')
      failure = =>
        @$el.show()
        $.flashError I18n.t('flash.removeError', 'Unable to remove the user. Please try again later.')
      deferreds = _.map @model.allEnrollmentsWithRole(@role), (e) ->
        $.ajaxJSON "#{ENV.COURSE_ROOT_URL}/unenroll/#{e.id}", 'DELETE'
      $.when(deferreds...).then success, failure

    handleMenuEvent : (e) =>
      e.preventDefault()
      method = $(e.currentTarget).data 'event'
      @[method].call this, e
