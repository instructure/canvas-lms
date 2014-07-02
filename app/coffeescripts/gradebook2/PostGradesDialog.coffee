define [
  'i18n!modules'
  'jquery'
  'underscore'
  'Backbone'
  'timezone'
  'compiled/views/DialogBaseView'
  'jst/gradebook2/post_grades_dialog'
  'jst/gradebook2/post_grades_summary'
  'jst/gradebook2/post_grades_needs_grading'
  'jst/gradebook2/post_grades_ungraded_count'
  'compiled/handlebars_helpers'
  'compiled/jquery.rails_flash_notifications'
  'jqueryui/effects/slide'
  'jquery.instructure_date_and_time'
  'jquery.toJSON'
], (I18n, $, _, Backbone, tz, DialogBaseView, dialog_template, summary_template, needs_grading_template, ungraded_count_template) ->

  class PostGradesDialog extends DialogBaseView
    
    initialize: (model, sis_app_url) ->
      super

      model.bind('change:assignments_to_post', =>
        $(".assignments_to_post_count").html(model.assignments_to_post().length)
      )
      model.bind('change:missing_not_unique', =>
        $(".assignment-error-count").html(model.get('missing_not_unique'))
        if @model.get('missing_not_unique') == 0
          $('#assignment-error-text').hide()
          @postSummaryPage()
        else
          $('#assignment-error-text').show()
          $('#assignment-error-text').addClass('text-error')
          $('#assignment-error-text').removeClass('text-info')
      )

      @model = model
      @sis_app_url = sis_app_url

      if @model.missing_and_not_unique().length > 0
        @page = 'assignmentErrors'
      else
        @page = 'postSummary'

    events:
      'click #needs-grading':      'needsGrading',
      'click .ignore-assignment' : 'ignoreAssignment'
      'click .clickableRow' :      'goToUrl'

    dialogOptions:
      id: 'post-grades-container'
      title: I18n.t "post_grades_dialog_title", "Post Grades to SIS"
      maxHeight: 450
      maxWidth: 650
      minHeight: 450
      minWidth: 650
      width: 650
      height: 450
      resizable: false
      buttons: []

    initDialog: ->
      super

    render: () ->
      super

      if @model.assignments_with_errors_count() > 0
        @page = "assignmentErrors"

      switch @page
        when "assignmentErrors"
          @dialog.dialog(
            buttons: [
              text: I18n.t '#buttons.ignore_all', 'Ignore All'
              'class' : 'ignore_all'
              click: (e) =>
                e.preventDefault
                @model.ignore_all()
                @page = 'postSummary'
                @render()
            ])
          @assignmentErrorsPage()
        when "postSummary"
          @dialog.dialog(
            buttons: [
              text: I18n.t '#button.post', 'Post Grades'
              'class' : 'post_grades btn-primary'
              click : (e) =>
                e.preventDefault
                @saveAssignments()
                @postGrades()
            ]
          )
          @postSummaryPage()
        when "needsGrading"
          @dialog.dialog(
            buttons: [
              text: I18n.t '#button.go_back', 'Go Back'
              'class' : 'go_back'
              click : (e) =>
                e.preventDefault
                @page = 'postSummary'
                @render()

            ]
          )
          @needsGradingPage()
      @datePicker()
      this

    ignoreAssignment: (e) ->
      e.preventDefault()
      assignment_id = "" + $(e.target).closest('form').data('assignment-id')
      @model.ignore_assignment(assignment_id)
      @model.set(missing_not_unique: @model.assignments_with_errors_count())
      $('#assignment-error-'+assignment_id).hide();
      if @model.get('missing_not_unique') == 0
        @page = "postSummary"
        @render()

    needsGrading: (e) =>
      e.preventDefault()
      @page = 'needsGrading'
      @render()

    needsGradingPage: ->
      @$el.html needs_grading_template(
        needs_grading: @model.ungraded_submissions()
      )

    assignmentErrorsPage: ->
      @$el.html dialog_template(
        assignments_to_post: @model.assignments_to_post()
        assignments: @model.assignment_list()
        missing_not_unique: @model.missing_and_not_unique()
        needs_grading: @model.ungraded_submissions()
        needs_grading_count: @model.ungraded_submissions().length
      )
      dialog = this
      $('.assignment-name', @$el).change ->
        $textbox = $(this)
        $circle = $textbox.closest('.input-container').prev()
        name = $textbox.val()

        dialog.showErrorCircle($circle, name == '')

        # Update the @model assignment with new name
        assignment_id = parseInt($textbox.closest('form.passback-form').data('assignment-id'))
        dialog.model.update_assignment(assignment_id, name: name)

    postSummaryPage: ->
      @$el.html summary_template(
        assignments_to_post: @model.assignments_to_post()
        needs_grading: @model.ungraded_submissions()
        needs_grading_count: @model.ungraded_submissions().length
      )
      @postUngraded()

    goToUrl: (e) ->
      e.preventDefault()
      window.location = $(e.currentTarget).data('url')

    postUngraded: ->
      if @model.ungraded_submissions().length > 0
        $('#ungraded_count', @$el).html ungraded_count_template(
          needs_grading_count: @model.ungraded_submissions().length
        )

    showErrorCircle: ($circle, show = true) ->
      if show
        $circle.addClass('data-circle-error').removeClass('data-circle-clean')
      else
        $circle.addClass('data-circle-clean').removeClass('data-circle-error')

    datePicker: ->
      dialog = this
      $('.date_field', @$el).datetime_field(addHiddenInput: true).change ->
        $picker = $(this)

        # Convert the date to a Date object with proper Timezone conversion
        due_at_string = $picker.val()
        due_at = null
        error_circle = true
        if due_at_string != ''
          raw_date = new Date($picker.next().val())
          unfudge = $.unfudgeDateForProfileTimezone(raw_date)
          if unfudge?
            due_at = unfudge.toISOString()
            error_circle = false

        # Show or hide the red circle, depending on validity of date          
        $circle = $picker.closest('.input-container').prev()
        dialog.showErrorCircle($circle, error_circle)

        # Update the @model assignment with new due_at date
        assignment_id = parseInt($picker.closest('form.passback-form').data('assignment-id'))
        dialog.model.update_assignment(assignment_id, due_at: due_at)

    saveAssignments: ->
      assignments = @model.missing_and_not_unique()
      # saveAssignmentsToCanvas(assignments)

    sendGradesToSISApp: (grades_json, url) ->
      $.ajax url,
        type: 'POST'
        data: JSON.stringify(grades_json)
        contentType: 'application/json; charset=utf-8'
        error: (data) ->
          $.flashError('An error occurred posting your grades. ' + "HTTP Error " + data.status + " : " + data.statusText)
        success: (data) ->
          $.flashMessage('Assignments are being posted.')

    postGrades: ->
      json_to_post = {}
      json_to_post['canvas_domain'] = document.location.origin
      json_to_post['assignments'] = _.map(@model.get('assignments_to_post'), (assignment) -> assignment.id)
      if @model.get('section_id')
        json_to_post['section_id'] = @model.get('section_id')
        url = @sis_app_url + '/grades/section/' + @model.get('section_id')
        @sendGradesToSISApp(json_to_post, url)
        @close()
      else if @model.get('course_id')
        json_to_post['course_id'] = @model.get('course_id')
        url = @sis_app_url + '/grades/course/' + @model.get('course_id')
        @sendGradesToSISApp(json_to_post, url)
        @close()
      else
        # Odd, the course/section has no SIS ID
        $.flashError("Grades can't be posted because this course or section was not imported from your SIS.")
        @close()











