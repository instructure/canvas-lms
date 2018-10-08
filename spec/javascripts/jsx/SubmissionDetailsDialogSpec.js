/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import fakeENV from 'helpers/fakeENV'
import SubmissionDetailsDialog from 'compiled/SubmissionDetailsDialog'

let assignment
let student
let options

QUnit.module('#SubmissionDetailsDialog', {
  setup() {
    fakeENV.setup()
    this.clock = sinon.useFakeTimers()
    sandbox.stub($, 'publish')
    ENV.GRADEBOOK_OPTIONS = {
      has_grading_periods: false
    }
    sandbox.stub($, 'ajaxJSON')

    assignment = {
      id: 1,
      grading_type: 'points',
      points_possible: 10
    }
    student = {
      assignment_1: {
        submission_history: []
      }
    }
    options = {change_grade_url: ''}
  },

  teardown() {
    this.clock.restore()
    fakeENV.teardown()
    $('.use-css-transitions-for-show-hide').remove()
    $('.ui-dialog').remove()
  }
})

test('flashWarning is called when score is 150% points possible', function() {
  const submissionsDetailsDialog = new SubmissionDetailsDialog(assignment, student, options)
  const flashWarningStub = sandbox.stub($, 'flashWarning')
  $('.submission_details_grade_form', submissionsDetailsDialog.dialog).trigger('submit')
  const callback = $.ajaxJSON.getCall(1).args[3]
  callback({score: 15, excused: false})
  this.clock.tick(510)
  ok(flashWarningStub.calledOnce)
})

test('display name by default', function() {
  const submissionDetailsDialog = new SubmissionDetailsDialog(assignment, student, options)
  const submissionData = {
    submission_comments: [
      {
        author: {
          id: '2'
        },
        author_id: '2',
        author_name: 'Some Author',
        comment: 'a comment',
        id: '27'
      }
    ]
  }
  submissionDetailsDialog.update(submissionData)

  strictEqual(document.querySelector('address').innerText.includes('Some Author'), true)
})

test("when anonymous hides student's name from address section", function() {
  options.anonymous = true
  const submissionDetailsDialog = new SubmissionDetailsDialog(assignment, student, options)
  const submissionData = {
    submission_comments: [
      {
        author: {
          id: '2'
        },
        author_id: '2',
        author_name: 'Some Author',
        comment: 'a comment',
        id: '27'
      }
    ]
  }
  submissionDetailsDialog.update(submissionData)

  strictEqual(document.querySelector('address').innerText.includes('Student'), true)
  submissionDetailsDialog.dialog.dialog('destroy')
})

test("when anonymous does not hide the user's name", function() {
  options.anonymous = true
  const submissionDetailsDialog = new SubmissionDetailsDialog(assignment, student, options)
  const submissionData = {
    submission_comments: [
      {
        author: {
          id: ENV.current_user_id
        },
        author_id: ENV.current_user_id,
        author_name: 'Some Author',
        comment: 'a comment',
        id: '27'
      }
    ]
  }
  submissionDetailsDialog.update(submissionData)

  strictEqual(document.querySelector('address').innerText.includes('Some Author'), true)
  submissionDetailsDialog.dialog.dialog('destroy')
})
