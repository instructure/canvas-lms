I18n.scoped 'gradebook2', (I18n) ->
  class @SetDefaultGradeDialog
    constructor: (@assignment, @gradebook) ->
      @initDialog()
    
    initDialog: =>
      templateLocals = 
        assignment: @assignment
        showPointsPossible: @assignment.points_possible || @assignment.points_possible == '0'
        url: "/courses/#{@gradebook.options.context_id}/gradebook/update_submission"
      templateLocals["assignment_grading_type_is_#{@assignment.grading_type}"] = true
      @$dialog = $(Template('SetDefaultGradeDialog', templateLocals))
      @$dialog.dialog(
        resizable: false
        width: 350
        open: => @$dialog.find(".grading_box").focus()
        close: => @$dialog.remove()
      ).fixDialogButtons()
      @$dialog.formSubmit
        disableWhileLoading: true
        processData: (data) =>
          for idx, student of @gradebook.students when !student["assignment_#{@assignment.id}"].score? || data.overwrite_existing_grades
            data["submissions[submission_#{idx}][assignment_id]"] = @assignment.id
            data["submissions[submission_#{idx}][user_id]"] = student.id
            data["submissions[submission_#{idx}][grade]"] = data.default_grade
          if idx is 0
            alert I18n.t('alerts.none_to_update', "None to Update")
            return false
          data
        success: (data) =>
          # fix
          submissions = (datum.submission for datum in data)
          $.publish 'submissions_updated', [submissions]
          alert(I18n.t('alerts.scores_updated', {'one': '1 Student score updated', 'other': '%{count} Student scores updated'}, {'count': data.length}));
          @$dialog.remove()
