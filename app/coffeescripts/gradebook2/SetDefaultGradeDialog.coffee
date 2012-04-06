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

  class SetDefaultGradeDialog
    constructor: (@assignment, @gradebook) ->
      @initDialog()

    initDialog: =>
      templateLocals =
        assignment: @assignment
        showPointsPossible: @assignment.points_possible || @assignment.points_possible == '0'
        url: "/courses/#{@gradebook.options.context_id}/gradebook/update_submission"
      templateLocals["assignment_grading_type_is_#{@assignment.grading_type}"] = true
      @$dialog = $(setDefaultGradeDialogTemplate(templateLocals))
      @$dialog.dialog(
        resizable: false
        width: 350
        open: => @$dialog.find(".grading_box").focus()
        close: => @$dialog.remove()
      ).fixDialogButtons()
      @$dialog.formSubmit
        disableWhileLoading: true
        processData: (data) =>
          studentsAffected = 0
          hasNoScore = (student) => !student["assignment_#{@assignment.id}"].score?
          canOverwrite = data.overwrite_existing_grades
          inSection = (student) => if @gradebook.sectionToShow
            _.include(student.sections, @gradebook.sectionToShow)
          else
            true
          updateData = (idx, student) =>
            studentsAffected = studentsAffected + 1
            data["submissions[submission_#{idx}][assignment_id]"] = @assignment.id
            data["submissions[submission_#{idx}][user_id]"] = student.id
            data["submissions[submission_#{idx}][grade]"] = data.default_grade

          updateData(idx, student) for idx, student of @gradebook.students when (hasNoScore(student) or canOverwrite) and inSection(student)

          if studentsAffected is 0
            alert I18n.t('alerts.none_to_update', "None to Update")
            return false
          data
        success: (data) =>
          # fix
          submissions = (datum.submission for datum in data)
          $.publish 'submissions_updated', [submissions]
          alert(I18n.t('alerts.scores_updated', {'one': '1 Student score updated', 'other': '%{count} Student scores updated'}, {'count': data.length}))
          @$dialog.remove()
