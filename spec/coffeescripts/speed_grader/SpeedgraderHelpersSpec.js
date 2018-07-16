/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import fakeENV from 'helpers/fakeENV'
import SpeedgraderHelpers, {
  setupIsAnonymous,
  setupAnonymizableId,
  setupAnonymizableUserId,
  setupAnonymizableStudentId,
  setupAnonymizableAuthorId
} from 'speed_grader_helpers'

QUnit.module('SpeedGrader', {
  setup() {
    const fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = `
      <a id="assignment_submission_default_url" href="http://www.default.com"></a>
      <a id="assignment_submission_originality_report_url" href="http://www.report.com"></a>
      `
  },
  teardown() {
    fixtures.innerHTML = ''
  }
})

test('setupIsAnonymous is available on main object', () => {
  strictEqual(SpeedgraderHelpers.setupIsAnonymous, setupIsAnonymous)
})

test('setupAnonymizableId is available on main object', () => {
  strictEqual(SpeedgraderHelpers.setupAnonymizableId, setupAnonymizableId)
})

test('setupAnonymizableUserId is available on main object', () => {
  strictEqual(SpeedgraderHelpers.setupAnonymizableUserId, setupAnonymizableUserId)
})

test('setupAnonymizableStudentId is available on main object', () => {
  strictEqual(SpeedgraderHelpers.setupAnonymizableStudentId, setupAnonymizableStudentId)
})

test('setupAnonymizableAuthorId is available on main object', () => {
  strictEqual(SpeedgraderHelpers.setupAnonymizableAuthorId, setupAnonymizableAuthorId)
})

test('populateTurnitin sets correct URL for OriginalityReports', () => {
  const submission = {
    id: '7',
    grade: null,
    score: null,
    submitted_at: '2016-11-29T22:29:44Z',
    assignment_id: '52',
    user_id: '2',
    submission_type: 'online_upload',
    workflow_state: 'submitted',
    updated_at: '2016-11-29T22:29:44Z',
    grade_matches_current_submission: true,
    graded_at: null,
    turnitin_data: {
      attachment_103: {
        similarity_score: 0.8,
        state: 'acceptable',
        report_url: 'http://www.thebrickfan.com',
        status: 'scored'
      }
    },
    excused: null,
    versioned_attachments: [
      {
        attachment: {
          id: '103',
          context_id: '2',
          context_type: 'User',
          size: null,
          content_type: 'text/rtf',
          filename: '1480456390_119__Untitled.rtf',
          display_name: 'Untitled-2.rtf',
          workflow_state: 'pending_upload',
          viewed_at: null,
          view_inline_ping_url: '/users/2/files/103/inline_view',
          mime_class: 'doc',
          currently_locked: false,
          'crocodoc_available?': null,
          canvadoc_url: null,
          crocodoc_url: null,
          submitted_to_crocodoc: false,
          provisional_crocodoc_url: null
        }
      }
    ],
    late: false,
    external_tool_url: null,
    has_originality_report: true
  }
  const reportContainer = $('#assignment_submission_originality_report_url')
  const defaultContainer = $('#assignment_submission_default_url')
  const container = SpeedgraderHelpers.urlContainer(submission, defaultContainer, reportContainer)
  equal(container, reportContainer)
})

QUnit.module('SpeedgraderHelpers#buildIframe', {
  setup() {
    this.buildIframe = SpeedgraderHelpers.buildIframe
  }
})

test('sets src to given src', function() {
  const expected = '<iframe id="speedgrader_iframe" src="some/url?with=query"></iframe>'
  equal(this.buildIframe('some/url?with=query'), expected)
})

test('applies options as tag attrs', function() {
  const expected = '<iframe id="speedgrader_iframe" src="path" frameborder="0"></iframe>'
  const options = {frameborder: 0}
  equal(this.buildIframe('path', options), expected)
})

test('applies className options as class', function() {
  const expected = '<iframe id="speedgrader_iframe" src="path" class="test"></iframe>'
  const options = {className: 'test'}
  equal(this.buildIframe('path', options), expected)
})

QUnit.module('SpeedgraderHelpers#determineGradeToSubmit', {
  setup() {
    this.determineGrade = SpeedgraderHelpers.determineGradeToSubmit
    this.student = {submission: {score: 89}}
    this.grade = {
      val() {
        return '25'
      }
    }
  }
})

test('returns grade.val when use_existing_score is false', function() {
  equal(this.determineGrade(false, this.student, this.grade), '25')
})

test('returns existing submission when use_existing_score is true', function() {
  equal(this.determineGrade(true, this.student, this.grade), '89')
})

QUnit.module('SpeedgraderHelpers#iframePreviewVersion', {
  setup() {
    this.previewVersion = SpeedgraderHelpers.iframePreviewVersion
  }
})

test('returns empty string if submission is null', function() {
  equal(this.previewVersion(null), '')
})

test('returns empty string if submission contains no currentSelectedIndex', function() {
  equal(this.previewVersion({}), '')
})

test('returns currentSelectedIndex if version is null', function() {
  const submission = {
    currentSelectedIndex: 0,
    submission_history: [{submission: {version: null}}, {submission: {version: 2}}]
  }
  equal(this.previewVersion(submission), '&version=0')
})

test('returns currentSelectedIndex if version is the same', function() {
  const submission = {
    currentSelectedIndex: 0,
    submission_history: [{submission: {version: 0}}, {submission: {version: 1}}]
  }
  equal(this.previewVersion(submission), '&version=0')
})

test('returns version if its different', function() {
  const submission = {
    currentSelectedIndex: 0,
    submission_history: [{submission: {version: 1}}, {submission: {version: 2}}]
  }
  equal(this.previewVersion(submission), '&version=1')
})

test('returns correct version for a given index', function() {
  const submission = {
    currentSelectedIndex: 1,
    submission_history: [{submission: {version: 1}}, {submission: {version: 2}}]
  }
  equal(this.previewVersion(submission), '&version=2')
})

test("returns '' if a currentSelectedIndex is not a number", function() {
  const submission = {
    currentSelectedIndex: 'one',
    submission_history: [{submission: {version: 1}}, {submission: {version: 2}}]
  }
  equal(this.previewVersion(submission), '')
})

test('returns currentSelectedIndex if version is not a number', function() {
  const submission = {
    currentSelectedIndex: 1,
    submission_history: [{submission: {version: 'one'}}, {submission: {version: 'two'}}]
  }
  equal(this.previewVersion(submission), '&version=1')
})

QUnit.module('SpeedgraderHelpers#setRightBarDisabled', {
  setup() {
    this.fixtureNode = document.getElementById('fixtures')
    this.testArea = document.createElement('div')
    this.testArea.id = 'test_area'
    this.fixtureNode.appendChild(this.testArea)
    this.startingHTML =
      '<input type="text" id="grading-box-extended"><textarea id="speedgrader_comment_textarea"></textarea><button id="add_attachment"></button><button id="media_comment_button"></button><button id="comment_submit_button"></button>'
  },
  teardown() {
    this.fixtureNode.innerHTML = ''
  }
})

test('it properly disables the elements we care about in the right bar', function() {
  this.testArea.innerHTML = this.startingHTML
  SpeedgraderHelpers.setRightBarDisabled(true)
  equal(
    this.testArea.innerHTML,
    '<input type="text" id="grading-box-extended" class="ui-state-disabled" aria-disabled="true" readonly="readonly" disabled=""><textarea id="speedgrader_comment_textarea" class="ui-state-disabled" aria-disabled="true" readonly="readonly" disabled=""></textarea><button id="add_attachment" class="ui-state-disabled" aria-disabled="true" readonly="readonly" disabled=""></button><button id="media_comment_button" class="ui-state-disabled" aria-disabled="true" readonly="readonly" disabled=""></button><button id="comment_submit_button" class="ui-state-disabled" aria-disabled="true" readonly="readonly" disabled=""></button>'
  )
})

test('it properly enables the elements we care about in the right bar', function() {
  this.testArea.innerHTML = this.startingHTML
  SpeedgraderHelpers.setRightBarDisabled(false)
  equal(this.testArea.innerHTML, this.startingHTML)
})

QUnit.module('SpeedgraderHelpers#classNameBasedOnStudent', {
  setup() {
    this.student = {
      submission_state: null,
      submission: {submitted_at: '2016-10-13 12:22:39'}
    }
  }
})

test('returns graded for graded', function() {
  this.student.submission_state = 'graded'
  const state = SpeedgraderHelpers.classNameBasedOnStudent(this.student)
  deepEqual(state, {
    raw: 'graded',
    formatted: 'graded'
  })
})

test("returns 'not graded' for not_graded", function() {
  this.student.submission_state = 'not_graded'
  const state = SpeedgraderHelpers.classNameBasedOnStudent(this.student)
  deepEqual(state, {
    raw: 'not_graded',
    formatted: 'not graded'
  })
})

test('returns graded for not_gradeable', function() {
  this.student.submission_state = 'not_gradeable'
  const state = SpeedgraderHelpers.classNameBasedOnStudent(this.student)
  deepEqual(state, {
    raw: 'not_gradeable',
    formatted: 'graded'
  })
})

test("returns 'not submitted' for not_submitted", function() {
  this.student.submission_state = 'not_submitted'
  const state = SpeedgraderHelpers.classNameBasedOnStudent(this.student)
  deepEqual(state, {
    raw: 'not_submitted',
    formatted: 'not submitted'
  })
})

test('returns resubmitted data for graded_then_resubmitted', function() {
  this.student.submission_state = 'resubmitted'
  const state = SpeedgraderHelpers.classNameBasedOnStudent(this.student)
  deepEqual(state, {
    raw: 'resubmitted',
    formatted: 'graded, then resubmitted (Oct 13, 2016 at 12:22pm)'
  })
})

QUnit.module('SpeedgraderHelpers#submissionState', {
  setup() {
    this.student = {submission: {grade_matches_current_submission: true}}
    this.grading_role = 'teacher'
  }
})

test('returns graded if grade matches current submission', function() {
  this.student.submission.grade_matches_current_submission = true
  this.student.submission.grade = 10
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'graded')
})

test("returns resubmitted if grade doesn't match current submission", function() {
  this.student.submission.grade = 10
  this.student.submission.grade_matches_current_submission = false
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'resubmitted')
})

test('returns not submitted if submission.workflow_state is unsubmitted', function() {
  this.student.submission.workflow_state = 'unsubmitted'
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'not_submitted')
})

test("returns not_gradeable if provisional_grader and student doesn't need provision grade", function() {
  this.student.submission.workflow_state = 'submitted'
  this.student.submission.submitted_at = '2016-10-13 12:22:39'
  this.student.submission.provisional_grade_id = null
  this.student.needs_provisional_grade = false
  const result = SpeedgraderHelpers.submissionState(this.student, 'provisional_grader')
  equal(result, 'not_gradeable')
})

test("returns not_gradeable if moderator and student doesn't need provision grade", function() {
  this.student.submission.workflow_state = 'submitted'
  this.student.submission.submitted_at = '2016-10-13 12:22:39'
  this.student.submission.provisional_grade_id = null
  this.student.needs_provisional_grade = false
  const result = SpeedgraderHelpers.submissionState(this.student, 'moderator')
  equal(result, 'not_gradeable')
})

test('returns not_graded if submitted but no grade', function() {
  this.student.submission.workflow_state = 'submitted'
  this.student.submission.submitted_at = '2016-10-13 12:22:39'
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'not_graded')
})

test('returns not_graded if pending_review', function() {
  this.student.submission.workflow_state = 'pending_review'
  this.student.submission.submitted_at = '2016-10-13 12:22:39'
  this.student.submission.grade = 123
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'not_graded')
})

test('returns graded if final_provisional_grade.grade exists', function() {
  this.student.submission.submitted_at = '2016-10-13 12:22:39'
  this.student.submission.final_provisional_grade = {grade: 123}
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'graded')
})

test('returns graded if submission excused', function() {
  this.student.submission.submitted_at = '2016-10-13 12:22:39'
  this.student.submission.excused = true
  const result = SpeedgraderHelpers.submissionState(this.student, this.grading_role)
  equal(result, 'graded')
})

test('returns the proper submission url', () => {
  $('#fixtures').append(
    '<a id="assignment_submission_resubmit_to_turnitin_url" href="http://www.resubmit.com"></a>'
  )
  const submission = {user_id: 1}
  const result = SpeedgraderHelpers.plagiarismResubmitUrl(submission)
  equal(result, 'http://www.resubmit.com')
})

test("prevents the button's default action", () => {
  $('#fixtures').append('<button id="resubmit-button">Click Here</button>')
  const ajaxStub = sinon.stub()
  ajaxStub.returns({
    status: 200,
    data: {}
  })
  const previousAjaxJson = $.ajaxJSON
  $.ajaxJSON = ajaxStub
  const event = {
    preventDefault: sinon.spy(),
    target: document.getElementById('resubmit-button')
  }
  SpeedgraderHelpers.plagiarismResubmitHandler(event, 'http://www.test.com')
  ok(event.preventDefault.called)
  $.ajaxJSON = previousAjaxJson
})

test("changes the button's text to 'Resubmitting...'", () => {
  $('#fixtures').append('<button id="resubmit-button">Click Here</button>')
  const ajaxStub = sinon.stub()
  ajaxStub.returns({
    status: 200,
    data: {}
  })
  const previousAjaxJson = $.ajaxJSON
  $.ajaxJSON = ajaxStub
  const event = {
    preventDefault: sinon.spy(),
    target: $('#resubmit-button')
  }
  SpeedgraderHelpers.plagiarismResubmitHandler(event, 'http://www.test.com')
  equal($('#resubmit-button').text(), 'Resubmitting...')
  $.ajaxJSON = previousAjaxJson
})

test('disables the button', () => {
  $('#fixtures').append('<button id="resubmit-button">Click Here</button>')
  const ajaxStub = sinon.stub()
  ajaxStub.returns({
    status: 200,
    data: {}
  })
  const previousAjaxJson = $.ajaxJSON
  $.ajaxJSON = ajaxStub
  const event = {
    preventDefault: sinon.spy(),
    target: $('#resubmit-button')
  }
  SpeedgraderHelpers.plagiarismResubmitHandler(event, 'http://www.test.com')
  equal($('#resubmit-button').attr('disabled'), 'disabled')
  $.ajaxJSON = previousAjaxJson
})

test('Posts to the resubmit URL', () => {
  $('#fixtures').append('<button id="resubmit-button">Click Here</button>')
  const previousAjaxJson = $.ajaxJSON
  $.ajaxJSON = sinon.spy()
  const event = {
    preventDefault: sinon.spy(),
    target: document.getElementById('resubmit-button')
  }
  SpeedgraderHelpers.plagiarismResubmitHandler(event, 'http://www.test.com')
  ok($.ajaxJSON.called)
  $.ajaxJSON = previousAjaxJson
})

QUnit.module('SpeedgraderHelpers.setupIsAnonymous', suiteHooks => {
  suiteHooks.afterEach(() => {
    fakeENV.teardown()
  })

  test('returns true when assignment has anonymize_students set to true', () => {
    strictEqual(setupIsAnonymous({anonymize_students: true}), true)
    fakeENV.teardown()
  })

  test('returns false when assignment has anonymize_students set to false', () => {
    strictEqual(setupIsAnonymous({anonymize_students: false}), false)
  })
})

QUnit.module('SpeedgraderHelpers.setupAnonymizableId', () => {
  test('returns anonymizable_id when anonymous', () => {
    strictEqual(setupAnonymizableId(true), 'anonymous_id')
  })

  test('returns id when anonymous', () => {
    strictEqual(setupAnonymizableId(false), 'id')
  })
})

QUnit.module('SpeedgraderHelpers.setupAnonymizableUserId', () => {
  test('returns anonymizable_id when anonymous', () => {
    strictEqual(setupAnonymizableUserId(true), 'anonymous_id')
  })

  test('returns user_id when not anonymous', () => {
    strictEqual(setupAnonymizableUserId(false), 'user_id')
  })
})

QUnit.module('SpeedgraderHelpers.setupAnonymizableStudentId', () => {
  test('returns anonymizable_id when anonymous', () => {
    strictEqual(setupAnonymizableStudentId(true), 'anonymous_id')
  })

  test('returns student_id when not anonymous', () => {
    strictEqual(setupAnonymizableStudentId(false), 'student_id')
  })
})

QUnit.module('SpeedgraderHelpers.setupAnonymizableAuthorId', () => {
  test('returns anonymizable_id when anonymous', () => {
    strictEqual(setupAnonymizableAuthorId(true), 'anonymous_id')
  })

  test('returns author_id when not anonymous', () => {
    strictEqual(setupAnonymizableAuthorId(false), 'author_id')
  })
})
