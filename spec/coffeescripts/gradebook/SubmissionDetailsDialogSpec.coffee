define [
  'jquery'
  'compiled/models/Assignment'
  'compiled/models/User'
  'compiled/SubmissionDetailsDialog'
  'jst/SubmissionDetailsDialog'
], ($, Assignment, User, SubmissionDetailsDialog) ->

  module 'SubmissionDetailsDialog',

    setup: ->
      @assignment = new Assignment(id: 1)
      @user       = new User(assignment_1: {}, id: 1, name: 'Test student')

    teardown: ->
      $('.submission_details_dialog').remove()

  test 'speed_grader_enabled sets speedgrader url', ->
    dialog = new SubmissionDetailsDialog(@assignment, @user, speed_grader_enabled: true, change_grade_url: ':assignment/:student')
    ok dialog.submission.speedGraderUrl
    dialog.open()

    equal dialog.dialog.find('.more-details-link').length, 1

  test 'speed_grader_enabled as false does not set speedgrader url', ->
    dialog = new SubmissionDetailsDialog(@assignment, @user, speed_grader_enabled: false, change_grade_url: ':assignment/:student')
    equal dialog.submission.speedGraderUrl, null
    dialog.open()

    equal dialog.dialog.find('.more-details-link').length, 0
