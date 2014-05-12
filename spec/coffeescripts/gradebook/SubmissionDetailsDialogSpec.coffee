define [
  'jquery'
  'compiled/models/Assignment'
  'compiled/SubmissionDetailsDialog'
  'jst/SubmissionDetailsDialog'
], ($, Assignment, SubmissionDetailsDialog) ->

  module 'SubmissionDetailsDialog',

    setup: ->
      @assignment = new Assignment(id: 1)
      @user       = { assignment_1: {}, id: 1, name: 'Test student' }
      @options    = { speed_grader_enabled: true, change_grade_url: 'magic' }

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

  test 'lateness correctly passes through to the template', ->
    @assignment = new Assignment(id: 1, name: 'Test assignment', due_at: "2014-04-14T00:00:00Z")
    @user       = { assignment_1: { submitted_at: "2014-04-20T00:00:00Z", late: true }, id: 1, name: 'Test student' }
    dialog = new SubmissionDetailsDialog(@assignment, @user, @options)
    dialog.open()

    ok dialog.dialog.find('.submission-details').text().match('LATE')
