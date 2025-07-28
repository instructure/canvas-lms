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

import AssignmentCellFormatter from '../AssignmentCellFormatter'
import {createGradebook, setFixtureHtml} from '../../../__tests__/GradebookSpecHelper'

describe('GradebookGrid AssignmentCellFormatter', () => {
  let fixture
  let columnDef
  let gradebook
  let formatter
  let student
  let submission
  let submissionState

  beforeEach(() => {
    fixture = document.createElement('div')
    document.body.appendChild(fixture)
    setFixtureHtml(fixture)

    const defaultGradingScheme = [
      ['A', 0.9],
      ['B', 0.8],
      ['C', 0.7],
      ['D', 0.6],
      ['F', 0.0],
    ]
    gradebook = createGradebook({default_grading_standard: defaultGradingScheme})
    gradebook.saveSettings = jest
      .fn()
      .mockImplementation((_context_id, gradebook_settings) => Promise.resolve(gradebook_settings))

    formatter = new AssignmentCellFormatter(gradebook)
    gradebook.setAssignments({
      2301: {id: '2301', name: 'Algebra 1', grading_type: 'points', points_possible: 10},
    })

    columnDef = {}
    student = {id: '1101', loaded: true, initialized: true}
    submission = {
      assignment_id: '2301',
      grade: '8',
      id: '2501',
      posted_at: null,
      score: 8,
      submission_type: 'online_text_entry',
      user_id: '1101',
      workflow_state: 'active',
    }
    submissionState = {hideGrade: false}

    const getSubmissionState = gradebook.submissionStateMap.getSubmissionState.bind(
      gradebook.submissionStateMap,
    )
    jest
      .spyOn(gradebook.submissionStateMap, 'getSubmissionState')
      .mockImplementation(getSubmissionState)
    gradebook.submissionStateMap.getSubmissionState.mockImplementation(sub => {
      if (sub === submission) return submissionState
      return getSubmissionState(sub)
    })
  })

  afterEach(() => {
    jest.restoreAllMocks()
    fixture.remove()
  })

  const renderCell = () => {
    fixture.innerHTML = formatter.render(
      0, // row
      0, // cell
      submission, // value
      columnDef, // column definition
      student, // dataContext
    )
    return fixture.querySelector('.gradebook-cell')
  }

  const getRenderedGrade = () => fixture.querySelector('.Grid__GradeCell__Content .Grade')

  const excuseSubmission = () => {
    submission.grade = null
    submission.rawGrade = null
    submission.score = null
    submission.excused = true
  }

  describe('#render()', () => {
    test('includes the "dropped" style when the submission is dropped', () => {
      submission.drop = true
      expect(renderCell().classList.contains('dropped')).toBe(true)
    })

    test('includes the "excused" style when the submission is excused', () => {
      excuseSubmission()
      expect(renderCell().classList.contains('excused')).toBe(true)
    })

    test('includes the "resubmitted" style when the current grade does not match the submission grade', () => {
      submission.grade_matches_current_submission = false
      expect(renderCell().classList.contains('resubmitted')).toBe(true)
    })

    test('excludes the "resubmitted" style when the submission is both resubmitted and late', () => {
      submission.grade_matches_current_submission = false
      submission.late = true
      expect(renderCell().classList.contains('resubmitted')).toBe(false)
    })

    test('includes the "missing" style when the submission is missing', () => {
      submission.missing = true
      expect(renderCell().classList.contains('missing')).toBe(true)
    })

    test('excludes the "missing" style when the submission is both dropped and missing', () => {
      submission.drop = true
      submission.missing = true
      expect(renderCell().classList.contains('missing')).toBe(false)
    })

    test('excludes the "missing" style when the submission is both excused and missing', () => {
      excuseSubmission()
      submission.missing = true
      expect(renderCell().classList.contains('missing')).toBe(false)
    })

    test('excludes the "missing" style when the submission is both resubmitted and missing', () => {
      submission.grade_matches_current_submission = false
      submission.missing = true
      expect(renderCell().classList.contains('missing')).toBe(false)
    })

    test('excludes the "missing" style when the submission is both missing and late', () => {
      submission.missing = true
      submission.late = true
      expect(renderCell().classList.contains('missing')).toBe(false)
    })

    test('includes the "late" style when the submission is late', () => {
      submission.late = true
      expect(renderCell().classList.contains('late')).toBe(true)
    })

    test('excludes the "late" style when the submission is both dropped and late', () => {
      submission.drop = true
      submission.late = true
      expect(renderCell().classList.contains('late')).toBe(false)
    })

    test('excludes the "late" style when the submission is both excused and late', () => {
      excuseSubmission()
      submission.late = true
      expect(renderCell().classList.contains('late')).toBe(false)
    })

    test('renders an empty cell when the student is not loaded', () => {
      student.loaded = false
      renderCell()
      expect(getRenderedGrade().innerHTML).toBe('')
    })

    test('renders an empty cell when the student is not initialized', () => {
      student.initialized = false
      renderCell()
      expect(getRenderedGrade().innerHTML).toBe('')
    })

    test('renders an empty cell when the submission is not defined', () => {
      submission = undefined
      renderCell()
      expect(getRenderedGrade().innerHTML).toBe('')
    })

    test('renders an empty cell when the submission state is not defined', () => {
      gradebook.submissionStateMap.getSubmissionState.mockImplementation(() => undefined)
      renderCell()
      expect(getRenderedGrade().innerHTML).toBe('')
    })

    test('renders an empty cell when the submission has a hidden grade', () => {
      submissionState.hideGrade = true
      renderCell()
      expect(getRenderedGrade().innerHTML).toBe('')
    })

    test('renders a grayed-out cell when the student enrollment is inactive', () => {
      student.isInactive = true
      const cell = renderCell()
      expect(cell.classList.contains('grayed-out')).toBe(true)
    })

    test('renders an uneditable cell when the student enrollment is concluded', () => {
      student.isConcluded = true
      const cell = renderCell()
      expect(cell.classList.contains('grayed-out')).toBe(true)
    })

    test('renders an uneditable cell when the submission has a hidden grade', () => {
      submissionState.hideGrade = true
      const cell = renderCell()
      expect(cell.classList.contains('grayed-out')).toBe(true)
    })

    test('renders an uneditable cell when the submission cannot be graded', () => {
      submissionState.locked = true
      const cell = renderCell()
      expect(cell.classList.contains('grayed-out')).toBe(true)
    })

    describe('when showing the updated similarity score', () => {
      beforeEach(() => {
        gradebook.options.show_similarity_score = true
      })

      describe('when the submission includes Turnitin data', () => {
        let plagiarismEntry

        beforeEach(() => {
          plagiarismEntry = {status: 'scored'}
          submission.turnitin_data = {submission_2501: plagiarismEntry}
        })

        test('includes a warning icon when plagiarism data is in an "error" state', () => {
          plagiarismEntry.status = 'error'
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-warning'),
          ).toBeTruthy()
        })

        test('includes a clock icon when plagiarism data is awaiting processing', () => {
          plagiarismEntry.status = 'pending'
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-clock'),
          ).toBeTruthy()
        })

        test('includes a solid circle when above 60% similarity', () => {
          plagiarismEntry.similarity_score = 75
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-empty'),
          ).toBeTruthy()
        })

        test('includes a half-filled circle when between 20% and 60% similarity', () => {
          plagiarismEntry.similarity_score = 45
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-oval-half'),
          ).toBeTruthy()
        })

        test('includes a "certified" icon when below 20% similarity', () => {
          plagiarismEntry.similarity_score = 10
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-certified'),
          ).toBeTruthy()
        })
      })

      describe('when the submission includes Vericite data', () => {
        let plagiarismEntry

        beforeEach(() => {
          plagiarismEntry = {status: 'scored'}
          submission.vericite_data = {provider: 'vericite', submission_2501: plagiarismEntry}
        })

        test('includes a warning icon when plagiarism data is in an "error" state', () => {
          plagiarismEntry.status = 'error'
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-warning'),
          ).toBeTruthy()
        })

        test('includes a clock icon when plagiarism data is awaiting processing', () => {
          plagiarismEntry.status = 'pending'
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-clock'),
          ).toBeTruthy()
        })

        test('includes a solid circle when above 60% similarity', () => {
          plagiarismEntry.similarity_score = 75
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-empty'),
          ).toBeTruthy()
        })

        test('includes a half-filled circle when between 20% and 60% similarity', () => {
          plagiarismEntry.similarity_score = 45
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-oval-half'),
          ).toBeTruthy()
        })

        test('includes a "certified" icon when below 20% similarity', () => {
          plagiarismEntry.similarity_score = 10
          expect(
            renderCell().querySelector('.Grid__GradeCell__OriginalityScore .icon-certified'),
          ).toBeTruthy()
        })
      })
    })

    test('does not render an icon in the OriginalityScore area when updated display is not enabled', () => {
      submission.turnitin_data = {submission_2501: {status: 'error'}}
      expect(renderCell().querySelector('.Grid__GradeCell__OriginalityScore')).toBeFalsy()
    })

    test('includes the "ungraded" class when the assignment is not graded', () => {
      gradebook.getAssignment('2301').submission_types = ['not_graded']
      expect(renderCell().classList.contains('ungraded')).toBe(true)
    })

    test('escapes html in the grade', () => {
      gradebook.getDefaultGradingScheme().data[0][0] = '<img src=null onerror=alert(1) >'
      gradebook.getAssignment('2301').grading_type = 'letter_grade'
      gradebook.updateEnterGradesAsSetting('2301', 'gradingScheme')
      submission.score = 10
      renderCell()
      expect(getRenderedGrade().innerHTML.trim()).toBe('&lt;img src=null onerror=alert(1) &gt;')
    })

    test('displays the grade as "Excused" when the submission is being excused', () => {
      const pendingGradeInfo = {
        enteredAs: 'excused',
        excused: true,
        grade: null,
        score: null,
        valid: true,
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      renderCell()
      expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
    })

    test('includes the "excused" style when the submission is being excused', () => {
      const pendingGradeInfo = {
        enteredAs: 'excused',
        excused: true,
        grade: null,
        score: null,
        valid: true,
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      expect(renderCell().classList.contains('excused')).toBe(true)
    })

    test('displays the grade as "–" (en dash) when the grade is being cleared', () => {
      const pendingGradeInfo = {
        enteredAs: null,
        excused: false,
        grade: null,
        score: null,
        valid: true,
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      renderCell()
      expect(getRenderedGrade().innerHTML.trim()).toBe('–')
    })

    test('does not display an invalid grade indicator when no grade is pending', () => {
      expect(renderCell().querySelectorAll('.Grid__GradeCell__InvalidGrade')).toHaveLength(0)
    })

    test('does not display an unposted grade indicator', () => {
      expect(renderCell().querySelectorAll('.Grid__GradeCell__UnpostedGrade')).toHaveLength(0)
    })

    describe('when post assignment grades tray is open', () => {
      beforeEach(() => {
        columnDef.postAssignmentGradesTrayOpenForAssignmentId = true
      })

      test('displays an unposted grade indicator when grade is graded and unposted', () => {
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('.Grid__GradeCell__UnpostedGrade')).toHaveLength(1)
      })

      test('displays an unposted grade indicator when a submission comment exists and is unposted', () => {
        submission.hasPostableComments = true
        expect(renderCell().querySelectorAll('.Grid__GradeCell__UnpostedGrade')).toHaveLength(1)
      })

      test('does not display an unposted grade indicator when grade is posted', () => {
        submission.posted_at = new Date()
        expect(renderCell().querySelectorAll('.Grid__GradeCell__UnpostedGrade')).toHaveLength(0)
      })

      test('does not display an unposted grade indicator when submission has no grade nor comment', () => {
        submission.workflow_state = 'unsubmitted'
        expect(renderCell().querySelectorAll('.Grid__GradeCell__UnpostedGrade')).toHaveLength(0)
      })

      test('does not display an unposted grade indicator when submission does not have a score nor postable comment', () => {
        submission.workflow_state = 'graded'
        submission.score = null
        submission.hasPostableComments = false
        expect(renderCell().querySelectorAll('.Grid__GradeCell__UnpostedGrade')).toHaveLength(0)
      })
    })

    describe('when a grade is pending', () => {
      let pendingGradeInfo

      beforeEach(() => {
        pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'A',
          score: 9.1,
          valid: true,
        }
      })

      test('displays the pending grade', () => {
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('A')
      })

      test('displays the pending grade when the submission otherwise needs grading', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('A')
      })

      test('escapes html in the pending grade', () => {
        pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: '<img src=null onerror=alert(1) >',
          score: 9.1,
          valid: true,
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('&lt;img src=null onerror=alert(1) &gt;')
      })

      test('displays an invalid grade indicator when the pending grade is invalid', () => {
        pendingGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: 'invalid',
          score: null,
          valid: false,
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        expect(renderCell().querySelectorAll('.Grid__GradeCell__InvalidGrade')).toHaveLength(1)
      })

      test('does not display an invalid grade indicator when the pending grade is valid', () => {
        pendingGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: null,
          score: null,
          valid: true,
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        expect(renderCell().querySelectorAll('.Grid__GradeCell__InvalidGrade')).toHaveLength(0)
      })
    })

    describe('when the grade is being cleared', () => {
      let pendingGradeInfo

      beforeEach(() => {
        pendingGradeInfo = {
          enteredAs: null,
          excused: false,
          grade: null,
          score: null,
          valid: true,
        }
      })

      test('renders "–" (en dash) when the submission is unsubmitted', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.submission_type = null
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('–')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })
    })

    describe('with a "points" assignment submission', () => {
      beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'points'
      })

      test('renders the score converted to a points string', () => {
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('8')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
      })
    })

    describe('with a "percent" assignment submission', () => {
      beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'percent'
      })

      test('renders the score converted to a percentage', () => {
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('80%')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
      })
    })

    describe('with a "letter grade" assignment submission', () => {
      beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'letter_grade'
        submission.score = 9
      })

      test('renders the score converted to a letter grade', () => {
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('A')
      })

      test('renders the grade when the assignment has no points possible', () => {
        gradebook.getAssignment('2301').points_possible = 0
        submission.grade = 'A'
        submission.score = 0
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('A')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
      })
    })

    describe('with a "complete/incomplete" assignment submission', () => {
      beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'pass_fail'
        submission.grade = 'Complete (i18n)'
        submission.rawGrade = 'complete'
        submission.score = 10
      })

      test('renders a checkmark when the grade is "complete"', () => {
        expect(renderCell().querySelectorAll('i.icon-check.Grade--complete')).toHaveLength(1)
      })

      test('renders an x-mark when the grade is "incomplete"', () => {
        submission.grade = 'Incomplete (i18n)'
        submission.rawGrade = 'incomplete'
        submission.score = 0
        expect(renderCell().querySelectorAll('i.icon-x.Grade--incomplete')).toHaveLength(1)
      })

      test('renders "–" (en dash) when the submission is unsubmitted', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.submission_type = null
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('–')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.score = null
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission is pending review', () => {
        submission.grade = null
        submission.rawGrade = null
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
      })

      test('uses the pending grade when present', () => {
        const pendingGradeInfo = {
          enteredAs: 'passFail',
          excused: false,
          grade: 'incomplete',
          score: 0,
          valid: true,
        }
        gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
        expect(renderCell().querySelectorAll('i.icon-x.Grade--incomplete')).toHaveLength(1)
      })
    })

    describe('with a "GPA Scale" assignment submission', () => {
      beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'gpa_scale'
        submission.score = 9
      })

      test('renders the score converted to a letter grade', () => {
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('A')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission is pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
      })
    })

    describe('with a quiz submission', () => {
      beforeEach(() => {
        gradebook.getAssignment('2301').grading_type = 'points'
        submission.submission_type = 'online_quiz'
      })

      test('renders the score converted to a points string', () => {
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('8')
      })

      test('renders the "needs grading" icon when the submission was graded and cleared', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'graded'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the "needs grading" icon when the submission was resubmitted', () => {
        submission.workflow_state = 'submitted'
        submission.grade_matches_current_submission = false
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the quiz icon when the submission is ungraded and pending review', () => {
        submission.grade = null
        submission.score = null
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders the quiz icon when the submission is partially graded and pending review', () => {
        submission.workflow_state = 'pending_review'
        expect(renderCell().querySelectorAll('i.icon-not-graded')).toHaveLength(1)
      })

      test('renders "Excused" when the submission is excused', () => {
        excuseSubmission()
        renderCell()
        expect(getRenderedGrade().innerHTML.trim()).toBe('Excused')
      })
    })
  })
})
