I18n.scoped 'gradebook2', (I18n) ->
  class @GradebookHeaderMenu
    constructor: (@assignment, @$trigger, @gradebook) ->
      templateLocals =
        assignmentUrl: "#{@gradebook.options.context_url}/assignments/#{@assignment.id}"
        speedGraderUrl: "#{@gradebook.options.context_url}/gradebook/speed_grader?assignment_id=#{@assignment.id}"
      @$menu = $(Template 'GradebookHeaderMenu', templateLocals).insertAfter(@$trigger)
      @$trigger.kyleMenu(noButton:true)
      @$menu
        # need it to be a child of #gradebook_grid (not the header cell) to get over overflow:hidden obstacles.
        .appendTo('#gradebook_grid')
        .delegate('a', 'click', (event) =>
          action = @[$(event.target).data('action')]
          if action
            action()
            false
        )
        .bind('popupopen popupclose', (event) => @$trigger.toggleClass 'ui-menu-trigger-menu-is-open', event.type == 'popupopen')
        .bind('popupopen',  =>
          @$menu.find("[data-action=#{action}]").showIf(condition) for action, condition of {
            showAssignmentDetails: @gradebook.allSubmissionsLoaded
            messageStudentsWho:    @gradebook.allSubmissionsLoaded
            setDefaultGrade:       @gradebook.allSubmissionsLoaded
            curveGrades:           @gradebook.allSubmissionsLoaded && @assignment.grading_type != 'pass_fail' && @assignment.points_possible
            downloadSubmissions:   "#{@assignment.submission_types}".match(/(online_upload|online_text_entry|online_url)/)
            reuploadSubmissions:   @assignment.submissions_downloads > 0
          }
        )
        .popup('open')

    showAssignmentDetails: =>
      $('<div>TODO: show assignment stats, is doing what we were doing best? look at: http://www.highcharts.com/demo/scatter/grid</div>').dialog()

    messageStudentsWho: =>
      students = ($.extend({ id: student.id, name: student.name}, student["assignment_#{@assignment.id}"]) for i, student of @gradebook.students)
      window.messageStudents
        options: [
          {text: I18n.t("students_who.havent_submitted_yet", "Haven't submitted yet")}
          {text: I18n.t("students_who.scored_less_than", "Scored less than"), cutoff: true}
          {text: I18n.t("students_who.scored_more_than", "Scored more than"), cutoff: true}
        ]
        title: @assignment.name
        points_possible: @assignment.points_possible
        students: students
        callback: (selected, cutoff, students) ->
          students = $.grep students, ($student, idx) ->
            student = $student.user_data
            if selected == I18n.t("not_submitted_yet", "Haven't submitted yet")
              !student.submitted_at
            else if selected == I18n.t("scored_less_than", "Scored less than")
              student.score? and student.score != "" and cutoff? and student.score < cutoff
            else if selected == I18n.t("scored_more_than", "Scored more than")
              student.score? and student.score != "" and cutoff? and student.score > cutoff
          $.map students, (student) -> student.user_data.id
    
    setDefaultGrade: =>
      new SetDefaultGradeDialog(@assignment, @gradebook)
    
    curveGrades: =>
      new CurveGradesDialog(@assignment, @gradebook)

    downloadSubmissions: =>
      url = $.replaceTags @gradebook.options.download_assignment_submissions_url, "assignment_id", @assignment.id
      INST.downloadSubmissions url
      @assignment.submissions_downloads = (@assignment.submissions_downloads ?= 0) + 1

    reuploadSubmissions: =>
      unless @$re_upload_submissions_form
        GradebookHeaderMenu::$re_upload_submissions_form = $(Template('re_upload_submissions_form'))
          .dialog
            width: 400
            modal: true
            resizable: false
            autoOpen: false
          .submit ->
            data = $(this).getFormData()
            if !data.submissions_zip
              false
            else if !data.submissions_zip.match(/\.zip$/)
              $(this).formErrors submissions_zip: I18n.t('errors.upload_as_zip', "Please upload files as a .zip")
              false
      url = $.replaceTags @gradebook.options.re_upload_submissions_url, "assignment_id", @assignment.id
      @$re_upload_submissions_form.attr('action', url).dialog('open')

