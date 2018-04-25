/*
 * Copyright (C) 2013 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import $ from 'jquery'
import Assignment from 'compiled/models/Assignment'
import SubmissionDetailsDialog from 'compiled/SubmissionDetailsDialog'
import _ from 'underscore'
import tz from 'timezone'
import 'jst/SubmissionDetailsDialog'

QUnit.module('SubmissionDetailsDialog', {
  setup() {
    const defaults = {
      current_user_roles: ['teacher'],
      GRADEBOOK_OPTIONS: {has_grading_periods: true}
    }
    this.previousWindowENV = window.ENV
    Object.assign(window.ENV, defaults)
    this.assignment = new Assignment({id: 1})
    this.user = {
      assignment_1: {},
      id: 1,
      name: 'Test student'
    }
    this.options = {
      speed_grader_enabled: true,
      change_grade_url: 'magic'
    }
  },
  teardown() {
    window.ENV = this.previousWindowENV
    $('.ui-dialog').remove()
    return $('.submission_details_dialog').remove()
  }
})

test('speed_grader_enabled sets speedgrader url', function() {
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, {
    speed_grader_enabled: true,
    change_grade_url: ':assignment/:student'
  })
  ok(dialog.submission.speedGraderUrl)
  dialog.open()
  equal(dialog.dialog.find('.more-details-link').length, 1)
})

test('speedGraderUrl excludes student id when Anonymous Moderated Marking is ' +
'enabled and the assignment is anonymously graded', function() {
  this.options.anonymous_moderated_marking_enabled = true
  this.assignment.anonymous_grading = true
  this.options.context_url = 'http://some-fake-url'
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)

  notOk(dialog.submission.speedGraderUrl.match(/student_id/))
})

test('speedGraderUrl includes student id when Anonymous Moderated Marking is ' +
'enabled and the assignment is not anonymously graded', function() {
  this.options.anonymous_moderated_marking_enabled = true
  this.options.context_url = 'http://some-fake-url'
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)

  ok(dialog.submission.speedGraderUrl.match(/student_id/))
})

test('speedGraderUrl includes student id when Anonymous Moderated Marking is ' +
'disabled and the assignment is anonymously graded', function() {
  this.options.anonymous_moderated_marking_enabled = false
  this.assignment.anonymous_grading = true
  this.options.context_url = 'http://some-fake-url'
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)

  ok(dialog.submission.speedGraderUrl.match(/student_id/))
})

test('speedGraderUrl includes student id when Anonymous Moderated Marking is ' +
'disabled and the assignment is not anonymously graded', function() {
  this.options.anonymous_moderated_marking_enabled = false
  this.options.context_url = 'http://some-fake-url'
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)

  ok(dialog.submission.speedGraderUrl.match(/student_id/))
})

test('speed_grader_enabled as false does not set speedgrader url', function() {
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, {
    speed_grader_enabled: false,
    change_grade_url: ':assignment/:student'
  })
  equal(dialog.submission.speedGraderUrl, null)
  dialog.open()
  equal(dialog.dialog.find('.more-details-link').length, 0)
})

test('speedgrader url quotes the student id', function() {
  // Supply a value for context_url so we have a well-formed speedGraderUrl
  this.options.context_url = 'http://localhost';
  const submissionDetailsDialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options);

  const urlObject = new URL(submissionDetailsDialog.submission.speedGraderUrl);
  strictEqual(decodeURI(urlObject.hash), '#{"student_id":"1"}');
  submissionDetailsDialog.dialog.dialog('destroy');
})

test('lateness correctly passes through to the template', function() {
  this.assignment = new Assignment({
    id: 1,
    name: 'Test assignment',
    due_at: '2014-04-14T00:00:00Z'
  })
  this.user = {
    assignment_1: {
      submitted_at: '2014-04-20T00:00:00Z',
      late: true
    },
    id: 1,
    name: 'Test student'
  }
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)
  dialog.open()
  ok(
    dialog.dialog
      .find('.submission-details')
      .text()
      .match('LATE')
  )
})

test('renders radio buttons if individually graded group assignment', function() {
  this.assignment.group_category_id = '42'
  this.assignment.grade_group_students_individually = true
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)
  dialog.open()
  equal(dialog.dialog.find('input[type="radio"][name="comment[group_comment]"]').length, 2)
})

test('renders hidden checkbox if group graded group assignment', function() {
  this.assignment.group_category_id = '42'
  this.assignment.grade_group_students_individually = false
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, this.options)
  dialog.open()
  equal(dialog.dialog.find('input[type="radio"][name="comment[group_comment]"]').length, 0)
  const $chk = dialog.dialog.find('input[type="checkbox"][name="comment[group_comment]"]')
  equal($chk.length, 1)
  equal($chk.attr('checked'), 'checked')
})

QUnit.module('_submission_detail', {
  setup() {
    const defaults = {
      current_user_roles: ['teacher'],
      GRADEBOOK_OPTIONS: {has_grading_periods: true}
    }
    this.previousWindowENV = window.ENV
    Object.assign(window.ENV, defaults)
    this.assignment = new Assignment({id: 1})
    this.options = {
      speed_grader_enabled: true,
      change_grade_url: 'magic'
    }
  },
  teardown() {
    window.ENV = this.previousWindowENV
    $('.submission_details_dialog').remove()
  }
})

test('partial correctly makes url field if submission type is url', function() {
  this.user = {
    assignment_1: {
      submission_history: [
        {
          submission_type: 'online_url',
          url: 'www.cnn.com'
        }
      ]
    },
    id: 1,
    name: 'Test student'
  }
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, {
    speed_grader_enabled: true,
    change_grade_url: ':assignment/:student'
  })
  dialog.open()
  equal(dialog.dialog.find('.url-submission').length, 1)
})

test('partial correctly makes attachment fields if submission included attachments', function() {
  this.user = {
    assignment_1: {
      submission_history: [
        {
          submission_type: 'online_url',
          attachments: [{}, {}, {}]
        }
      ]
    },
    id: 1,
    name: 'Test student'
  }
  const dialog = new SubmissionDetailsDialog(this.assignment, this.user, {
    speed_grader_enabled: true,
    change_grade_url: ':assignment/:student'
  })
  dialog.open()
  equal(dialog.dialog.find('.submisison-attachment').length, 3)
})

QUnit.module('_grading_box', {
  setup() {
    const defaults = {
      current_user_roles: ['teacher'],
      GRADEBOOK_OPTIONS: {has_grading_periods: true}
    }
    this.previousWindowENV = window.ENV
    Object.assign(window.ENV, defaults)
    this.assignment = new Assignment({
      id: 1,
      name: 'Test assignment',
      due_at: '2013-10-01T10:01:00Z'
    })
    this.assignment.grading_type = 'points'
    this.user = {
      assignment_1: {submitted_at: '2013-10-01T00:00:00Z'},
      id: 1,
      name: 'Test student'
    }
    this.options = {
      speed_grader_enabled: false,
      change_grade_url: ':assignment/:student'
    }
  },
  teardown() {
    window.ENV = this.previousWindowENV
    $('.submission_details_dialog').remove()
  }
})

test("displays the grade as 'EX' if the submission is excused", function() {
  this.user.assignment_1.excused = true
  new SubmissionDetailsDialog(this.assignment, this.user, this.options).open()
  const inputText = $('#student_grading_1').val()
  deepEqual(inputText, 'EX')
})

test("allows teacher to change grade to 'Ex'", function() {
  this.assignment.grading_type = 'pass_fail'
  new SubmissionDetailsDialog(this.assignment, this.user, this.options).open()
  const excusedOptionText = $('.grading_value option')[3].text
  deepEqual(excusedOptionText, 'Excused')
})

test('is disabled for assignments locked for the given student', function() {
  this.user.assignment_1.gradeLocked = true
  new SubmissionDetailsDialog(this.assignment, this.user, this.options).open()
  equal($('#student_grading_1').prop('disabled'), true)
})

test('is enabled for assignments not locked for the given student', function() {
  this.user.assignment_1.gradeLocked = false
  new SubmissionDetailsDialog(this.assignment, this.user, this.options).open()
  equal($('#student_grading_1').prop('disabled'), false)
})

test('does not hide download links when grading_type is pass_fail and grade is present', function() {
  this.assignment.grading_type = 'pass_fail'
  this.user.assignment_1.submission_history = [
    {
      submission_type: 'online_upload',
      attachments: [
        {
          url: 'http://example.com/download',
          filename: 'foo.txt',
          display_name: 'Dummy Download',
          mimeClass: 'test-fake'
        }
      ]
    }
  ]
  this.user.assignment_1.grade = 'complete'
  new SubmissionDetailsDialog(this.assignment, this.user, this.options).open()
  ok($('.submisison-attachment').is(':visible'), 'submission download link is visible')
})
