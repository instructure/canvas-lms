/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import AssignmentCellFormatter from 'jsx/gradezilla/default_gradebook/slick-grid/formatters/AssignmentCellFormatter'
import {createGradebook, setFixtureHtml} from '../../GradebookSpecHelper'

QUnit.module('AssignmentCellFormatter', suiteHooks => {
  let $fixture
  let gradebook
  let formatter
  let student
  let submission
  let submissionState

  suiteHooks.beforeEach(() => {
    $fixture = document.createElement('div')
    document.body.appendChild($fixture)
    setFixtureHtml($fixture)

    gradebook = createGradebook()
    formatter = new AssignmentCellFormatter(gradebook)
    gradebook.setAssignments({
      2301: {id: '2301', name: 'Algebra 1', grading_type: 'points', points_possible: 10}
    })

    student = {id: '1101', loaded: true, initialized: true}
    submission = {
      assignment_id: '2301',
      grade: '8',
      id: '2501',
      score: 8,
      submission_type: 'online_text_entry',
      user_id: '1101',
      workflow_state: 'active'
    }
    submissionState = {hideGrade: false}

    const getSubmissionState = gradebook.submissionStateMap.getSubmissionState.bind(
      gradebook.submissionStateMap
    )
    sinon.stub(gradebook.submissionStateMap, 'getSubmissionState').callsFake(getSubmissionState)
    gradebook.submissionStateMap.getSubmissionState.withArgs(submission).returns(submissionState)
  })

  suiteHooks.afterEach(() => {
    gradebook.submissionStateMap.getSubmissionState.restore()
    $fixture.remove()
  })

  function renderCell() {
    $fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      submission, // value
      null, // column definition
      student // dataContext
    )
    return $fixture.querySelector('.gradebook-cell')
  }

  function excuseSubmission() {
    submission.grade = null
    submission.score = null
    submission.excused = true
  }

  QUnit.module('#render()', () => {
    test('includes the "dropped" style when the submission is dropped', () => {
      submission.drop = true
      ok(renderCell().classList.contains('dropped'))
    })

    test('includes the "excused" style when the submission is excused', () => {
      excuseSubmission()
      ok(renderCell().classList.contains('excused'))
    })

    test('includes the "resubmitted" style when the current grade does not match the submission grade', () => {
      submission.grade_matches_current_submission = false
      ok(renderCell().classList.contains('resubmitted'))
    })

    test('includes the "missing" style when the submission is missing', () => {
      submission.missing = true
      ok(renderCell().classList.contains('missing'))
    })

    test('excludes the "missing" style when the submission is both dropped and missing', () => {
      submission.drop = true
      submission.missing = true
      notOk(renderCell().classList.contains('missing'))
    })

    test('excludes the "missing" style when the submission is both excused and missing', () => {
      excuseSubmission()
      submission.missing = true
      notOk(renderCell().classList.contains('missing'))
    })

    test('excludes the "missing" style when the submission is both resubmitted and missing', () => {
      submission.grade_matches_current_submission = false
      submission.missing = true
      notOk(renderCell().classList.contains('missing'))
    })

    test('includes the "late" style when the submission is late', () => {
      submission.late = true
      ok(renderCell().classList.contains('late'))
    })

    test('excludes the "late" style when the submission is both dropped and late', () => {
      submission.drop = true
      submission.late = true
      notOk(renderCell().classList.contains('late'))
    })

    test('excludes the "late" style when the submission is both excused and late', () => {
      excuseSubmission()
      submission.late = true
      notOk(renderCell().classList.contains('late'))
    })

    test('excludes the "late" style when the submission is both resubmitted and late', () => {
      submission.grade_matches_current_submission = false
      submission.late = true
      notOk(renderCell().classList.contains('late'))
    })

    test('excludes the "late" style when the submission is both missing and late', () => {
      submission.missing = true
      submission.late = true
      notOk(renderCell().classList.contains('late'))
    })

    test('renders an empty cell when the student is not loaded', () => {
      student.loaded = false
      strictEqual(renderCell().innerHTML, '')
    })

    test('renders an empty cell when the student is not initialized', () => {
      student.initialized = false
      strictEqual(renderCell().innerHTML, '')
    })

    test('renders an empty cell when the submission is not defined', () => {
      submission = undefined
      strictEqual(renderCell().innerHTML, '')
    })

    test('renders an empty cell when the submission state is not defined', () => {
      gradebook.submissionStateMap.getSubmissionState.withArgs(submission).returns(undefined)
      strictEqual(renderCell().innerHTML, '')
    })

    test('renders an empty cell when the submission has a hidden grade', () => {
      submissionState.hideGrade = true
      strictEqual(renderCell().innerHTML, '')
    })

    test('renders a grayed-out cell when the student enrollment is inactive', () => {
      student.isInactive = true
      const $cell = renderCell()
      ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"')
    })

    test('renders an uneditable cell when the student enrollment is concluded', () => {
      student.isConcluded = true
      const $cell = renderCell()
      ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"')
    })

    test('renders an uneditable cell when the submission has a hidden grade', () => {
      submissionState.hideGrade = true
      const $cell = renderCell()
      ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"')
    })

    test('renders an uneditable cell when the submission cannot be graded', () => {
      submissionState.locked = true
      const $cell = renderCell()
      ok($cell.classList.contains('grayed-out'), 'cell classes include "grayed-out"')
    })

    test('includes the "turnitin" class when the submission has Turnitin data', () => {
      submission.turnitin_data = {submission_2501: {state: 'acceptable'}}
      ok(renderCell().classList.contains('turnitin'))
    })

    test('renders the turnitin score when the submission has Turnitin data', () => {
      submission.turnitin_data = {submission_2501: {state: 'acceptable'}}
      strictEqual(
        renderCell().querySelectorAll('.gradebook-cell-turnitin.acceptable-score').length,
        1
      )
    })

    test('includes the "turnitin" class when the submission has Vericite data', () => {
      submission.vericite_data = {submission_2501: {state: 'acceptable'}}
      ok(renderCell().classList.contains('turnitin'))
    })

    test('renders the turnitin score when the submission has Vericite data', () => {
      submission.vericite_data = {submission_2501: {state: 'acceptable'}}
      strictEqual(
        renderCell().querySelectorAll('.gradebook-cell-turnitin.acceptable-score').length,
        1
      )
    })

    test('includes the "ungraded" class when the assignment is not graded', () => {
      gradebook.getAssignment('2301').submission_types = ['not_graded']
      ok(renderCell().classList.contains('ungraded'))
    })

    test('includes the "muted" class when the assignment is muted', () => {
      gradebook.getAssignment('2301').muted = true
      ok(renderCell().classList.contains('muted'))
    })

    QUnit.module('with a "points" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'points'
      })

      test('renders the score converted to a points string', () => {
        strictEqual(renderCell().innerHTML.trim(), '8')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })

      test('uses the updating grade data when the submission is updating', () => {
        const updatingSubmission = {
          assignmentId: '2301',
          enteredGrade: 'B',
          enteredScore: 8.9,
          excused: false,
          userId: '1101'
        }
        gradebook.setSubmissionUpdating(updatingSubmission, true)
        strictEqual(renderCell().innerHTML.trim(), '8.9')
      })

      test('renders "Excused" when the submission is being excused', () => {
        const updatingSubmission = {
          assignmentId: '2301',
          enteredGrade: null,
          enteredScore: null,
          excused: true,
          userId: '1101'
        }
        gradebook.setSubmissionUpdating(updatingSubmission, true)
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a "percent" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'percent'
      })

      test('renders the score converted to a percentage', () => {
        strictEqual(renderCell().innerHTML.trim(), '80%')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })

      test('uses the updating grade data when the submission is updating', () => {
        const updatingSubmission = {
          assignmentId: '2301',
          enteredGrade: 'B',
          enteredScore: 8.9,
          excused: false,
          userId: '1101'
        }
        gradebook.setSubmissionUpdating(updatingSubmission, true)
        strictEqual(renderCell().innerHTML.trim(), '89%')
      })

      test('renders "Excused" when the submission is being excused', () => {
        const updatingSubmission = {
          assignmentId: '2301',
          enteredGrade: null,
          enteredScore: null,
          excused: true,
          userId: '1101'
        }
        gradebook.setSubmissionUpdating(updatingSubmission, true)
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a "letter grade" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'letter_grade'
        submission.score = 9
      })

      test('renders the score converted to a letter grade', () => {
        strictEqual(renderCell().firstChild.wholeText.trim(), 'A')
      })

      test('renders the grade when the assignment has no points possible', () => {
        gradebook.getAssignment('2301').points_possible = 0
        submission.grade = 'A'
        submission.score = 0
        strictEqual(renderCell().firstChild.wholeText.trim(), 'A')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })

      test('uses the updating grade data when the submission is updating', () => {
        const updatingSubmission = {
          assignmentId: '2301',
          enteredGrade: 'A',
          enteredScore: 9.1,
          excused: false,
          userId: '1101'
        }
        gradebook.setSubmissionUpdating(updatingSubmission, true)
        strictEqual(renderCell().innerHTML.trim(), 'A')
      })

      test('renders "Excused" when the submission is being excused', () => {
        const updatingSubmission = {
          assignmentId: '2301',
          enteredGrade: null,
          enteredScore: null,
          excused: true,
          userId: '1101'
        }
        gradebook.setSubmissionUpdating(updatingSubmission, true)
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a "complete/incomplete" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'pass_fail'
        submission.grade = 'Complete (i18n)'
        submission.rawGrade = 'complete'
        submission.score = 10
      })

      test('renders a checkmark when the grade is "complete"', () => {
        strictEqual(renderCell().querySelectorAll('button i.icon-check').length, 1)
      })

      test('renders a checkmark when the grade is "incomplete"', () => {
        submission.grade = 'Incomplete (i18n)'
        submission.rawGrade = 'incomplete'
        submission.score = 0
        strictEqual(renderCell().querySelectorAll('button i.icon-x').length, 1)
      })

      test('renders an emdash "–" when the submission is unsubmitted', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.submission_type = null
        equal(renderCell().firstChild.wholeText.trim(), '–')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.workflow_state = 'graded'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission is pending review', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        equal(renderCell().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a "GPA Scale" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'gpa_scale'
        submission.score = 9
      })

      test('renders the score converted to a letter grade', () => {
        strictEqual(renderCell().innerHTML.trim(), 'A')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission is pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a quiz submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'points'
        submission.submission_type = 'online_quiz'
      })

      test('renders the score converted to a points string', () => {
        strictEqual(renderCell().innerHTML.trim(), '8')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the quiz icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the quiz icon when the submission is partially graded and pending review', () => {
        submission.workflow_state = 'pending_review'
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        strictEqual(renderCell().innerHTML.trim(), 'Excused')
      })
    })
  })
})
