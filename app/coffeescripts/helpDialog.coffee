# also requires
# jquery.formSubmit
# jqueryui dialog
# jquery disableWhileLoading

define [
  'i18n!help_dialog'
  'jst/helpDialog'
  'jquery'
  'underscore'
  'INST'
  'str/htmlEscape'
  'compiled/fn/preventDefault'

  'jquery.instructure_misc_helpers'
  'jqueryui/dialog'
  'jquery.disableWhileLoading'
], (I18n, helpDialogTemplate, $, _, INST, htmlEscape, preventDefault) ->

  showEmail = not ENV.current_user_id

  helpDialog =
    defaultLinks: [
      {
        available_to: ['student']
        text: I18n.t 'instructor_question', 'Ask Your Instructor a Question'
        subtext: I18n.t 'instructor_question_sub', 'Questions are submitted to your instructor'
        url: '#teacher_feedback'
      },
      {
        available_to: ['user', 'student', 'teacher', 'admin']
        text: I18n.t 'search_the_canvas_guides', 'Search the Canvas Guides'
        subtext: I18n.t 'canvas_help_sub', 'Find answers to common questions'
        url: 'http://guides.instructure.com'
      },
      {
        available_to: ['user', 'student', 'teacher', 'admin']
        text: I18n.t 'report_problem', 'Report a Problem'
        subtext: I18n.t 'report_problem_sub', 'If Canvas misbehaves, tell us about it'
        url: '#create_ticket'
      }
    ]

    defaultTitle: I18n.t 'Help', "Help"

    initDialog: ->
      @$dialog = $('<div style="padding:0; overflow: visible;" />').dialog
        resizable: false
        width: 400
        title: @defaultTitle
        close: => @switchTo('#help-dialog-options')

      @$dialog.dialog('widget').delegate 'a[href="#teacher_feedback"],
                                          a[href="#create_ticket"],
                                          a[href="#help-dialog-options"]', 'click', preventDefault ({currentTarget}) =>
        @switchTo $(currentTarget).attr('href')

      @helpLinksDfd = $.getJSON('/help_links').done (links) =>
        # only show the links that are available to the roles of this user
        links = $.grep @defaultLinks.concat(links), (link) ->
          _.detect link.available_to, (role) ->
            role is 'user' or
            (ENV.current_user_roles and role in ENV.current_user_roles)
        locals =
          showEmail: showEmail
          helpLinks: links
          showBadBrowserMessage: INST.browser.ie
          browserVersion: INST.browser.version
          url: window.location

        @$dialog.html(helpDialogTemplate locals)
        @initTicketForm()
        $(this).trigger('ready')
      @$dialog.disableWhileLoading @helpLinksDfd
      @dialogInited = true

    initTicketForm: ->
      $form = @$dialog.find('#create_ticket').formSubmit
        disableWhileLoading: true
        required: ->
          requiredFields = ['error[subject]', 'error[comments]', 'error[user_perceived_severity]']
          requiredFields.push 'error[email]' if showEmail
          requiredFields
        success: =>
          @$dialog.dialog('close')
          $form.find(':input').val('')

    switchTo: (panelId) ->
      toggleablePanels = "#teacher_feedback, #create_ticket"
      @$dialog.find(toggleablePanels).hide()

      newHeight = @$dialog.find(panelId).show().outerHeight()
      @$dialog.animate({
        left : if toggleablePanels.match(panelId) then -400 else 0
        height: newHeight
      }, {
        step: =>
          #reposition vertically to reflect current height
          @$dialog.dialog('option', 'position', 'center')
        duration: 100
      })

      if newTitle = @$dialog.find("a[href='#{panelId}'] .text").text()
        newTitle = $("
          <a class='ui-dialog-header-backlink' href='#help-dialog-options'>
            #{I18n.t('Back', 'Back')}
          </a>
          <span>#{newTitle}</span>
        ")
      else
        newTitle = @defaultTitle
      @$dialog.dialog 'option', 'title', newTitle

    open: ->
      helpDialog.initDialog() unless helpDialog.dialogInited
      helpDialog.$dialog.dialog('open')
      helpDialog.initTeacherFeedback()

    initTeacherFeedback: ->
      currentUserIsStudent = ENV.current_user_roles and 'student' in ENV.current_user_roles
      if !@teacherFeedbackInited and currentUserIsStudent
        @teacherFeedbackInited = true
        coursesDfd = $.getJSON '/api/v1/courses.json'
        $form = null
        @helpLinksDfd.done =>
          $form = @$dialog.find("#teacher_feedback")
            .disableWhileLoading(coursesDfd)
            .formSubmit
              disableWhileLoading: true
              required: ['recipients[]', 'body']
              success: =>
                @$dialog.dialog('close')

        $.when(coursesDfd, @helpLinksDfd).done ([courses]) ->
          options = $.map courses, (c) ->
            "<option value='course_#{c.id}_admins' #{if ENV.context_id is c.id then 'selected' else ''}>
              #{htmlEscape(c.name)}
            </option>"
          $form.find('[name="recipients[]"]').html(options.join '')

    initTriggers: ->
      $('.help_dialog_trigger').click preventDefault @open

