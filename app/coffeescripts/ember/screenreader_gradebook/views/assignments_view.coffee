define [
  'ember'
  'compiled/gradebook2/GradebookHeaderMenu'
  'compiled/gradebook2/AssignmentGroupWeightsDialog'
  'compiled/SubmissionDetailsDialog'
], (Ember, GradebookHeaderMenu, AssignmentGroupWeightsDialog, SubmissionDetailsDialog) ->

  AssignmentsView = Ember.View.extend
    templateName: 'assignments'

    setupDialog: (->
      @agDialog = new AssignmentGroupWeightsDialog({context: ENV.GRADEBOOK_OPTIONS, assignmentGroups:[], mergeFunction: @mergeObjects})
    ).on('didInsertElement')

    removeDialog: (->
      @agDialog.$dialog.dialog('destroy')
    ).on('willDestroyElement')

    mergeObjects: (old_ag, new_ag) ->
      Ember.setProperties(old_ag, new_ag)

    actions:
      openDialog: (dialogType) ->
        con = @controller
        assignment = con.get('selectedAssignment')
        options =
          assignment: assignment
          students: con.studentsThatCanSeeAssignment(assignment)
          selected_section: con.get('selectedSection')?.id
          context_id: ENV.GRADEBOOK_OPTIONS.context_id
          context_url: ENV.GRADEBOOK_OPTIONS.context_url
          speed_grader_enabled: ENV.GRADEBOOK_OPTIONS.speed_grader_enabled
          change_grade_url: ENV.GRADEBOOK_OPTIONS.change_grade_url

        dialogs =
          'assignment_details': GradebookHeaderMenu::showAssignmentDetails
          'message_students': GradebookHeaderMenu::messageStudentsWho
          'set_default_grade': GradebookHeaderMenu::setDefaultGrade
          'curve_grades': GradebookHeaderMenu::curveGrades
          'submission': SubmissionDetailsDialog.open

        switch dialogType
          when 'ag_weights'
            options =
              context: ENV.GRADEBOOK_OPTIONS
              assignmentGroups: con.get('assignment_groups').toArray()
            @agDialog.update(options)
            @agDialog.$dialog.dialog('open')
          when 'submission'
            dialogs[dialogType]?.call(this, con.get('selectedAssignment'), con.get('selectedStudent'), options)
          else
            dialogs[dialogType]?.call(this, options)

