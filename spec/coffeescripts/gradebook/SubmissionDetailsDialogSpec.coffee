#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'jquery'
  'compiled/models/Assignment'
  'compiled/SubmissionDetailsDialog'
  'underscore'
  'timezone'
  'jst/SubmissionDetailsDialog'
], ($, Assignment, SubmissionDetailsDialog, _, tz) ->

  QUnit.module 'SubmissionDetailsDialog',
    setup: ->
      defaults =
        current_user_roles: [ "teacher" ]
        GRADEBOOK_OPTIONS:
          has_grading_periods: true
      @previousWindowENV = window.ENV

      _.extend(window.ENV, defaults)

      @assignment = new Assignment(id: 1)
      @user       = { assignment_1: {}, id: 1, name: 'Test student' }
      @options    = { speed_grader_enabled: true, change_grade_url: 'magic' }

    teardown: ->
      window.ENV = @previousWindowENV
      $(".ui-dialog").remove()
      $('.submission_details_dialog').remove()

  test 'speed_grader_enabled sets speedgrader url', ->
    dialog = new SubmissionDetailsDialog(@assignment, @user, {speed_grader_enabled: true, change_grade_url: ':assignment/:student'})
    ok dialog.submission.speedGraderUrl
    dialog.open()

    equal dialog.dialog.find('.more-details-link').length, 1

  test 'speed_grader_enabled as false does not set speedgrader url', ->
    dialog = new SubmissionDetailsDialog(@assignment, @user, { speed_grader_enabled: false, change_grade_url: ':assignment/:student' })
    equal dialog.submission.speedGraderUrl, null
    dialog.open()

    equal dialog.dialog.find('.more-details-link').length, 0

  test 'lateness correctly passes through to the template', ->
    @assignment = new Assignment(id: 1, name: 'Test assignment', due_at: "2014-04-14T00:00:00Z")
    @user       = { assignment_1: { submitted_at: "2014-04-20T00:00:00Z", late: true }, id: 1, name: 'Test student' }
    dialog = new SubmissionDetailsDialog(@assignment, @user, @options)
    dialog.open()

    ok dialog.dialog.find('.submission-details').text().match('LATE')

  test 'renders radio buttons if individually graded group assignment', ->
    @assignment.group_category_id = '42'
    @assignment.grade_group_students_individually = true
    dialog = new SubmissionDetailsDialog(@assignment, @user, @options)
    dialog.open()
    equal dialog.dialog.find('input[type="radio"][name="comment[group_comment]"]').length, 2

  test 'renders hidden checkbox if group graded group assignment', ->
    @assignment.group_category_id = '42'
    @assignment.grade_group_students_individually = false
    dialog = new SubmissionDetailsDialog(@assignment, @user, @options)
    dialog.open()
    equal dialog.dialog.find('input[type="radio"][name="comment[group_comment]"]').length, 0
    $chk = dialog.dialog.find('input[type="checkbox"][name="comment[group_comment]"]')
    equal $chk.length, 1
    equal $chk.attr('checked'), 'checked'

  QUnit.module '_submission_detail',
    setup: ->
      defaults =
        current_user_roles: [ "teacher" ]
        GRADEBOOK_OPTIONS:
          has_grading_periods: true
      @previousWindowENV = window.ENV

      _.extend(window.ENV, defaults)

      @assignment = new Assignment(id: 1)
      @options    = { speed_grader_enabled: true, change_grade_url: 'magic'}

    teardown: ->
      window.ENV = @previousWindowENV
      $('.submission_details_dialog').remove()

  test 'partial correctly makes url field if submission type is url', ->
    @user       = { assignment_1: { submission_history: [{ submission_type: "online_url", url: "www.cnn.com" }] }, id: 1, name: 'Test student' }
    dialog = new SubmissionDetailsDialog(@assignment, @user, {speed_grader_enabled: true, change_grade_url: ':assignment/:student'})
    dialog.open()

    equal dialog.dialog.find('.url-submission').length, 1

  test 'partial correctly makes attachment fields if submission included attachments', ->
    @user       = { assignment_1: { submission_history: [{ submission_type: "online_url", attachments: [{},{},{}] }] }, id: 1, name: 'Test student' }
    dialog = new SubmissionDetailsDialog(@assignment, @user, {speed_grader_enabled: true, change_grade_url: ':assignment/:student'})
    dialog.open()

    equal dialog.dialog.find('.submisison-attachment').length, 3

  QUnit.module '_grading_box',
    setup: ->
      defaults =
        current_user_roles: [ "teacher" ]
        GRADEBOOK_OPTIONS:
          has_grading_periods: true
      @previousWindowENV = window.ENV

      _.extend(window.ENV, defaults)

      @assignment = new Assignment(id: 1, name: 'Test assignment', due_at: '2013-10-01T10:01:00Z')
      @assignment.grading_type = 'points'
      @user       = { assignment_1: { submitted_at: "2013-10-01T00:00:00Z" }, id: 1, name: 'Test student' }
      @options    = { speed_grader_enabled: false, change_grade_url: ':assignment/:student' }
    teardown: ->
      window.ENV = @previousWindowENV
      $('.submission_details_dialog').remove()

  test "displays the grade as 'EX' if the submission is excused", ->
    @user.assignment_1.excused = true
    new SubmissionDetailsDialog(@assignment, @user, @options).open()
    inputText = $('#student_grading_1').val()
    deepEqual inputText, 'EX'

  test "allows teacher to change grade to 'Ex'", ->
    @assignment.grading_type = 'pass_fail'
    new SubmissionDetailsDialog(@assignment, @user, @options).open()
    excusedOptionText = $('.grading_value option')[3].text
    deepEqual excusedOptionText, 'Excused'

  test "is disabled for assignments locked for the given student", ->
    @user.assignment_1.gradeLocked = true
    new SubmissionDetailsDialog(@assignment, @user, @options).open()
    equal $('#student_grading_1').prop('disabled'), true

  test "is enabled for assignments not locked for the given student", ->
    @user.assignment_1.gradeLocked = false
    new SubmissionDetailsDialog(@assignment, @user, @options).open()
    equal $('#student_grading_1').prop('disabled'), false

  test "does not hide download links when grading_type is pass_fail and grade is present", ->
    @assignment.grading_type = 'pass_fail'
    @user.assignment_1.submission_history = [
      submission_type: 'online_upload'
      attachments: [
        url: 'http://example.com/download'
        filename: 'foo.txt'
        display_name: 'Dummy Download'
        mimeClass: 'test-fake'
      ]
    ]
    @user.assignment_1.grade = 'complete'
    new SubmissionDetailsDialog(@assignment, @user, @options).open()

    ok $('.submisison-attachment').is(':visible'), 'submission download link is visible'
