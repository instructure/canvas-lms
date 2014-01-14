define [
  'ember'
  'compiled/gradebook2/GradebookHeaderMenu'
  'compiled/gradebook2/AssignmentGroupWeightsDialog'
  'compiled/gradebook2/UploadDialog'
], (Ember, GradebookHeaderMenu, AssignmentGroupWeightsDialog,  UploadDialog) ->

  # http://emberjs.com/api/classes/Ember.View.html
  # http://emberjs.com/guides/views/

  ScreenreaderGradebookView = Ember.View.extend

    setupDialog: (->
      @agDialog = new AssignmentGroupWeightsDialog({context: ENV.GRADEBOOK_OPTIONS, assignmentGroups:[]})
    ).on('didInsertElement')

    removeDialog: (->
      @agDialog.$dialog.dialog('destroy')
    ).on('willDestroyElement')

    actions:
      openDialog: (dialogType) ->
        con = @controller
        options =
          assignment: con.get('selectedAssignment')
          students: con.studentsHash()
          selected_section: con.get('selectedSection')?.id
          context_id: ENV.GRADEBOOK_OPTIONS.context_id
          context_url: ENV.GRADEBOOK_OPTIONS.context_url

        dialogs =
          'upload': UploadDialog::init
          'assignment_details': GradebookHeaderMenu::showAssignmentDetails
          'message_students': GradebookHeaderMenu::messageStudentsWho
          'set_default_grade': GradebookHeaderMenu::setDefaultGrade
          'curve_grades': GradebookHeaderMenu::curveGrades

        if dialogType is 'ag_weights'
          options =
            context: ENV.GRADEBOOK_OPTIONS
            assignmentGroups: con.get('assignment_groups').toArray()
          @agDialog.update(options)
          @agDialog.$dialog.dialog('open')
        else
          dialogs[dialogType]?.call(this, options)

