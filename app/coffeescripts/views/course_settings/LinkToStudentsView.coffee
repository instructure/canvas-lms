define [
  'i18n!course_settings'
  'jquery'
  'underscore'
  'compiled/views/DialogBaseView'
  'jst/courses/settings/LinkToStudentsView'
  'compiled/jquery.whenAll'
  'jquery.disableWhileLoading'
], (I18n, $, _, DialogBaseView, linkToStudentsViewTemplate) ->

  class LinkToStudentsView extends DialogBaseView

    dialogOptions:
      id: 'link_students'
      title: I18n.t 'titles.link_to_students', 'Link to Students'

    render: ->
      data = @model.toJSON()
      data.studentsUrl = ENV.SEARCH_URL
      @$el.html linkToStudentsViewTemplate data

      dfd = $.Deferred()
      @disable dfd.promise()
      dfds = []

      @students = []
      @$('#student_input').contextSearch
        contexts: ENV.CONTEXTS
        placeholder: I18n.t 'link_students_placeholder', 'Enter a student name'
        change: (tokens) =>
          @students = _.map tokens, (id) -> parseInt id
        selector:
          baseData:
            type: 'user'
            context: "course_#{ENV.COURSE_ID}_students"
            exclude: [@model.get('id')]
            skip_visibility_checks: true
          preparer: (postData, data, parent) ->
            row.noExpand = true for row in data
          browser:
            data:
              per_page: 100
              type: 'user'
      input = @$('#student_input').data('token_input')
      input.$fakeInput.css('width', '100%')

      for e in @model.get('enrollments') when e.associated_user_id
        dfds.push @getUserData(e.associated_user_id).done (user) ->
          input.addToken
            value: user.id
            text: user.name
            data: user

      # if a dfd fails (e.g. observee was removed from course), we still want
      # the observer dialog to render (possibly with other observees)
      $.whenAll(dfds...).always -> dfd.resolve(data)
      this

    getUserData: (id) ->
      $.get("/api/v1/courses/#{ENV.COURSE_ID}/users/#{id}", include:['enrollments'])

    update: (e) =>
      e.preventDefault()

      dfds = []
      enrollments = @model.get('enrollments')
      enrollment = enrollments[0]
      unlinkedEnrolls = _.filter enrollments, (en) -> !en.associated_user_id # keep the original observer enrollment around
      currentLinks = _.compact _.pluck(enrollments, 'associated_user_id')
      newLinks = _.difference @students, currentLinks
      removeLinks = _.difference currentLinks, @students

      if newLinks.length
        newDfd = $.Deferred()
        dfds.push newDfd.promise()
        dfdsDone = 0

      # create new links
      for id in newLinks
        @getUserData(id).done (user) =>
          udfds = []
          sections = _.map user.enrollments, (en) -> en.course_section_id
          for sId in sections
            url = "/api/v1/sections/#{sId}/enrollments"
            data =
              enrollment:
                user_id: @model.get('id')
                associated_user_id: user.id
                type: enrollment.type
                limit_privileges_to_course_section: enrollment.limit_priveleges_to_course_section
            udfds.push $.ajaxJSON url, 'POST', data
          $.when(udfds...).done ->
            dfdsDone += 1
            if dfdsDone == newLinks.length
              newDfd.resolve()

      # delete old links
      unenrolls = _.filter enrollments, (en) -> _.include removeLinks, en.associated_user_id
      for en in unenrolls
        url = "#{ENV.COURSE_ROOT_URL}/unenroll/#{en.id}"
        dfds.push $.ajaxJSON url, 'DELETE'

      @disable($.when(dfds...)
        .done =>
          @trigger 'updated'
          $.flashMessage I18n.t('flash.links', 'Student links successfully updated')
        .fail ->
          $.flashError I18n.t('flash.linkError', "Something went wrong updating the user's student links. Please try again later.")
        .always => @close())

    disable: (dfds) ->
      @$el.disableWhileLoading dfds, buttons: {'.btn-primary .ui-button-text': I18n.t('updating', 'Updating...')}