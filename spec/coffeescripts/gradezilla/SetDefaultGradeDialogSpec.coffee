define [
  'jquery'
  'compiled/models/Assignment'
  'compiled/gradezilla/SetDefaultGradeDialog'
  'jst/SetDefaultGradeDialog'
], ($, Assignment, SetDefaultGradeDialog) ->

  QUnit.module 'SetDefaultGradeDialog',
    setup: ->
      @assignment = new Assignment(id: 1, points_possible: 10)

    teardown: ->
      $(".ui-dialog").remove()
      $(".use-css-transitions-for-show-hide").remove()
      $('#set_default_grade_form').remove()

  test '#gradeIsExcused returns true if grade is EX', ->
    dialog = new SetDefaultGradeDialog({ @assignment })
    dialog.show()
    deepEqual dialog.gradeIsExcused('EX'), true
    deepEqual dialog.gradeIsExcused('ex'), true
    deepEqual dialog.gradeIsExcused('eX'), true
    deepEqual dialog.gradeIsExcused('Ex'), true

  test '#gradeIsExcused returns false if grade is not EX', ->
    dialog = new SetDefaultGradeDialog({ @assignment })
    dialog.show()
    deepEqual dialog.gradeIsExcused('14'), false
    deepEqual dialog.gradeIsExcused('F'), false
    #this test documents that we do not consider 'excused' to return true
    deepEqual dialog.gradeIsExcused('excused'), false
