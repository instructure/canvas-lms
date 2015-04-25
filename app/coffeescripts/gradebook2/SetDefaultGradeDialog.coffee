define [
  'i18n!gradebook2'
  'jquery'
  'jst/SetDefaultGradeDialog'
  'underscore'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.ba-tinypubsub'
  'compiled/jquery/fixDialogButtons'

  # this is a partial needed by the 'SetDefaultGradeDialog' template
  # since you cant declare a dependency in a handlebars file, we need to do it here
  'jst/_grading_box'

], (I18n, $, setDefaultGradeDialogTemplate, _) ->

  PAGE_SIZE = 50

  class SetDefaultGradeDialog
    constructor: ({@assignment, @students, @context_id, @selected_section}) ->
      @initDialog()

    initDialog: =>
      templateLocals =
        assignment: @assignment
        showPointsPossible: (@assignment.points_possible || @assignment.points_possible == '0') && @assignment.grading_type != "gpa_scale"
        url: "/courses/#{@context_id}/gradebook/update_submission"
        inputName: 'default_grade'
      templateLocals["assignment_grading_type_is_#{@assignment.grading_type}"] = true
      @$dialog = $(setDefaultGradeDialogTemplate(templateLocals))
      @$dialog.dialog(
        resizable: false
        width: 350
        open: => @$dialog.find(".grading_box").focus()
        close: => @$dialog.remove()
      ).fixDialogButtons()

      $form = @$dialog
      $(".ui-dialog-titlebar-close").focus()
      $form.submit (e) =>
        e.preventDefault()
        submittingDfd = $.Deferred()
        $form.disableWhileLoading(submittingDfd)

        formData = $form.getFormData()

        students = getStudents()
        pages = (students.splice 0, PAGE_SIZE while students.length)

        postDfds = pages.map (page) =>
          studentParams = getParams(page, formData.default_grade)
          params = _.extend {}, studentParams,
            dont_overwrite_grades: not formData.overwrite_existing_grades
          $.ajaxJSON $form.attr("action"), "POST", params

        $.when(postDfds...).then (responses...) =>
          responses = [responses] if postDfds.length == 1
          submissions = getSubmissions(responses)
          $.publish 'submissions_updated', [submissions]
          alert(I18n.t 'alerts.scores_updated'
          ,
            one: '1 Student score updated'
            other: '%{count} Student scores updated'
          ,
            count: submissions.length)
          submittingDfd.resolve()
          $("#set_default_grade").focus()
          @$dialog.remove()

      getStudents = =>
        if @selected_section
          _(@students).filter (s) =>
            _.include(s.sections, @selected_section)
        else
          _(@students).values()

      getParams = (page, grade) =>
        _.chain(page)
         .map (s) =>
           prefix = "submissions[submission_#{s.id}]"
           [["#{prefix}[assignment_id]", @assignment.id],
            ["#{prefix}[user_id]", s.id],
            ["#{prefix}[grade]", grade]]
         .flatten(true)
         .object()
         .value()

      getSubmissions = (responses) =>
        _.chain(responses)
         .map ([response, __]) ->
           [s.submission for s in response]
         .flatten().value()
