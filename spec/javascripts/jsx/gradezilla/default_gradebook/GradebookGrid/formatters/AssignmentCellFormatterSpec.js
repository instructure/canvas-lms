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

import AssignmentCellFormatter from 'jsx/gradezilla/default_gradebook/GradebookGrid/formatters/AssignmentCellFormatter'
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

    const defaultGradingScheme = [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]]
    gradebook = createGradebook({default_grading_standard: defaultGradingScheme})
    sinon.stub(gradebook, 'saveSettings')

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

  function getRenderedGrade() {
    return $fixture.querySelector('.Grid__AssignmentRowCell__Content .Grade')
  }

  function excuseSubmission() {
    submission.grade = null
    submission.rawGrade = null
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
      renderCell()
      strictEqual(getRenderedGrade().innerHTML, '')
    })

    test('renders an empty cell when the student is not initialized', () => {
      student.initialized = false
      renderCell()
      strictEqual(getRenderedGrade().innerHTML, '')
    })

    test('renders an empty cell when the submission is not defined', () => {
      submission = undefined
      renderCell()
      strictEqual(getRenderedGrade().innerHTML, '')
    })

    test('renders an empty cell when the submission state is not defined', () => {
      gradebook.submissionStateMap.getSubmissionState.withArgs(submission).returns(undefined)
      renderCell()
      strictEqual(getRenderedGrade().innerHTML, '')
    })

    test('renders an empty cell when the submission has a hidden grade', () => {
      submissionState.hideGrade = true
      renderCell()
      strictEqual(getRenderedGrade().innerHTML, '')
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

    test('escapes html in the grade', () => {
      gradebook.getDefaultGradingScheme().data[0][0] = '<img src=null onerror=alert(1) >'
      gradebook.getAssignment('2301').grading_type = 'letter_grade'
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme');
      submission.score = 10
      renderCell()
      equal(getRenderedGrade().innerHTML.trim(), '&lt;img src=null onerror=alert(1) &gt;')
    })

    test('displays the grade as "Excused" when the submission is being excused', () => {
      const pendingGradeInfo = {
        enteredAs: 'excused',
        excused: true,
        grade: null,
        score: null,
        valid: true
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      renderCell()
      equal(getRenderedGrade().innerHTML.trim(), 'Excused')
    })

    test('includes the "excused" style when the submission is being excused', () => {
      const pendingGradeInfo = {
        enteredAs: 'excused',
        excused: true,
        grade: null,
        score: null,
        valid: true
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      ok(renderCell().classList.contains('excused'))
    })

    test('displays the grade as "–" (en dash) when the grade is being cleared', () => {
      const pendingGradeInfo = {
        enteredAs: null,
        excused: false,
        grade: null,
        score: null,
        valid: true
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      renderCell()
      equal(getRenderedGrade().innerHTML.trim(), '–')
    })

    test('does not display an invalid grade indicator when no grade is pending', () => {
      strictEqual(renderCell().querySelectorAll('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
    })

    QUnit.module('when a grade is pending', contextHooks => {
      let pendingGradeInfo

      contextHooks.beforeEach(() => {
        pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'A',
          score: 9.1,
          valid: true
        }
      })

      test('displays the pending grade', () => {
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'A')
      })

      test('displays the pending grade when the submission otherwise needs grading', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'A')
      })

      test('escapes html in the pending grade', () => {
        pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: '<img src=null onerror=alert(1) >',
          score: 9.1,
          valid: true
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), '&lt;img src=null onerror=alert(1) &gt;')
      })

      test('displays an invalid grade indicator when the pending grade is invalid', () => {
        pendingGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: 'invalid',
          score: null,
          valid: false
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        strictEqual(renderCell().querySelectorAll('.Grid__AssignmentRowCell__InvalidGrade').length, 1)
      })

      test('does not display an invalid grade indicator when the pending grade is valid', () => {
        pendingGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: null,
          score: null,
          valid: true
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        strictEqual(renderCell().querySelectorAll('.Grid__AssignmentRowCell__InvalidGrade').length, 0)
      })
    })

    QUnit.module('when the grade is being cleared', contextHooks => {
      let pendingGradeInfo

      contextHooks.beforeEach(() => {
        pendingGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: null,
          score: null,
          valid: true
        }
      })

      test('renders "–" (en dash) when the submission is unsubmitted', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.submission_type = null
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), '–')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        strictEqual(renderCell().querySelectorAll('i.icon-not-graded').length, 1)
      })
    })

    QUnit.module('with a "points" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'points'
      })

      test('renders the score converted to a points string', () => {
        renderCell()
        strictEqual(getRenderedGrade().innerHTML.trim(), '8')
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
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a "percent" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'percent'
      })

      test('renders the score converted to a percentage', () => {
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), '80%')
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
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a "letter grade" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'letter_grade'
        submission.score = 9
      })

      test('renders the score converted to a letter grade', () => {
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'A')
      })

      test('renders the grade when the assignment has no points possible', () => {
        gradebook.getAssignment('2301').points_possible = 0
        submission.grade = 'A'
        submission.score = 0
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'A')
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
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'Excused')
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
        strictEqual(renderCell().querySelectorAll('i.icon-check.Grade--complete').length, 1)
      })

      test('renders a checkmark when the grade is "incomplete"', () => {
        submission.grade = 'Incomplete (i18n)'
        submission.rawGrade = 'incomplete'
        submission.score = 0
        strictEqual(renderCell().querySelectorAll('i.icon-x.Grade--incomplete').length, 1)
      })

      test('renders "–" (en dash) when the submission is unsubmitted', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.submission_type = null
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), '–')
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
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'Excused')
      })

      test('uses the pending grade when present', () => {
        const pendingGradeInfo = {
          enteredAs: 'passFail',
          excused: false,
          grade: 'incomplete',
          score: 0,
          valid: true
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        strictEqual(renderCell().querySelectorAll('i.icon-x.Grade--incomplete').length, 1)
      })
    })

    QUnit.module('with a "GPA Scale" assignment submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'gpa_scale'
        submission.score = 9
      })

      test('renders the score converted to a letter grade', () => {
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'A')
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
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'Excused')
      })
    })

    QUnit.module('with a quiz submission', contextHooks => {
      contextHooks.beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'points'
        submission.submission_type = 'online_quiz'
      })

      test('renders the score converted to a points string', () => {
        renderCell()
        strictEqual(getRenderedGrade().innerHTML.trim(), '8')
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
        renderCell()
        equal(getRenderedGrade().innerHTML.trim(), 'Excused')
      })
    })
  })
})
