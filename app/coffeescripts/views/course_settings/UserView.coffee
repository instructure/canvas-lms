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
], (I18n, $, _, Backbone, EditSectionsView, InvitationsView, LinkToStudentsView, User, userViewTemplate, toUnderscore, h) ->

  editSectionsDialog = null
  linkToStudentsDialog = null
  invitationDialog = null

  class UserView extends Backbone.View

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

    getUserData: (id) ->
      $.get("/api/v1/courses/#{ENV.COURSE_ID}/users/#{id}", include:['enrollments'])

    data: ->
      dfd = $.Deferred()
      dfds = []
      data = $.extend @model.toJSON(),
        url: "#{ENV.COURSE_ROOT_URL}/users/#{@model.get('id')}"
        permissions: ENV.PERMISSIONS
        isObserver: @model.hasEnrollmentType('ObserverEnrollment')
        isPending: @model.pending()
      for en in data.enrollments
        en.pending = @model.pending()
        en.typeClass = toUnderscore en.type
        section = ENV.CONTEXTS['sections'][en.course_section_id]
        en.sectionTitle = h section.name if section
      if data.isObserver
        users = {}
        for en in data.enrollments
          users[en.associated_user_id] ||= en.enrollment_state in ['creation_pending', 'invited'] if en.associated_user_id
        data.enrollments = []
        for id, pending of users
          dfds.push @getUserData(id).done (user) =>
            ob = {pending}
            ob.sectionTitle = I18n.t('observing_user', '*Observing*: %{user_name}', wrapper: '<i>$1</i>', user_name: user.name)
            for en in user.enrollments
              section = ENV.CONTEXTS['sections'][en.course_section_id]
              ob.sectionTitle += h(I18n.t('#support.array.words_connector') + section.name) if section
            data.enrollments.push ob
      # if a dfd fails (e.g. observee was removed from course), we still want
      # the observer to render (possibly with other observees)
      $.whenAll(dfds...).then ->
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
      editSectionsDialog.off 'updated'
      editSectionsDialog.on 'updated', @reload
      editSectionsDialog.render().show()

    linkToStudents: (e) ->
      linkToStudentsDialog ||= new LinkToStudentsView
      linkToStudentsDialog.model = @model
      linkToStudentsDialog.off 'updated'
      linkToStudentsDialog.on 'updated', @reload
      linkToStudentsDialog.render().show()

    removeFromCourse: (e) ->
      return unless confirm I18n.t('links.unenroll_user_course', 'Remove User from Course')
      @$el.hide()
      success = =>
        for e in @model.get('enrollments')
          e_type = e.typeClass.split('_')[0]
          c.innerText = parseInt(c.innerText) - 1 for c in $(".#{e_type}_count")
      failure = =>
        @$el.show()
      deferreds = _.map @model.get('enrollments'), (e) ->
        $.ajaxJSON "#{ENV.COURSE_ROOT_URL}/unenroll/#{e.id}", 'DELETE'
      $.when(deferreds...).then success, failure

    handleMenuEvent : (e) =>
      e.preventDefault()
      method = $(e.currentTarget).data 'event'
      @[method].call this, e
