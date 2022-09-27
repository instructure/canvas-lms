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

import AssignmentRowCellPropFactory from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/AssignmentCellEditor/AssignmentRowCellPropFactory'
import {
  createGradebook,
  setFixtureHtml,
} from 'ui/features/gradebook/react/default_gradebook/__tests__/GradebookSpecHelper'

QUnit.module('GradebookGrid AssignmentRowCellPropFactory', () => {
  let $container
  let gradebook

  QUnit.module('#getProps()', hooks => {
    let editorOptions

    function getProps() {
      const factory = new AssignmentRowCellPropFactory(gradebook)
      return factory.getProps(editorOptions)
    }

    hooks.beforeEach(() => {
      $container = document.body.appendChild(document.createElement('div'))
      setFixtureHtml($container)

      gradebook = createGradebook({context_id: '1201'})
      gradebook.gradebookGrid.gridSupport = {
        helper: {
          commitCurrentEdit() {},
          focus() {},
        },
      }

      gradebook.students['1101'] = {id: '1101', isConcluded: false}
      gradebook.setAssignments({
        2301: {grading_type: 'points', id: '2301', points_possible: 10},
      })
      gradebook.updateSubmission({
        assignment_id: '2301',
        entered_grade: '7.8',
        entered_score: 7.8,
        excused: false,
        grade: '6.8',
        id: '2501',
        score: 6.8,
        user_id: '1101',
      })

      editorOptions = {
        column: {
          assignmentId: '2301',
        },
        item: {id: '1101'},
      }

      sinon.stub(gradebook, 'updateRowAndRenderSubmissionTray') // no rendering needed for these tests
    })

    hooks.afterEach(() => {
      gradebook.destroy()
      $container.remove()
    })

    test('.assignment.id is the id on the assignment', () => {
      equal(getProps().assignment.id, '2301')
    })

    test('.assignment.pointsPossible is the points possible on the assignment', () => {
      strictEqual(getProps().assignment.pointsPossible, 10)
    })

    test('.enterGradesAs is the "enter grades as" setting for the assignment', () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      equal(getProps().enterGradesAs, 'percent')
    })

    test('.gradeIsEditable is true when the grade for the submission is editable', () => {
      sinon.stub(gradebook, 'isGradeEditable').withArgs('1101', '2301').returns(true)
      strictEqual(getProps().gradeIsEditable, true)
    })

    test('.gradeIsEditable is false when the grade for the submission is not editable', () => {
      sinon.stub(gradebook, 'isGradeEditable').withArgs('1101', '2301').returns(false)
      strictEqual(getProps().gradeIsEditable, false)
    })

    test('.gradeIsVisible is true when the grade for the submission is visible', () => {
      sinon.stub(gradebook, 'isGradeVisible').withArgs('1101', '2301').returns(true)
      strictEqual(getProps().gradeIsVisible, true)
    })

    test('.gradeIsVisible is false when the grade for the submission is not visible', () => {
      sinon.stub(gradebook, 'isGradeVisible').withArgs('1101', '2301').returns(false)
      strictEqual(getProps().gradeIsVisible, false)
    })

    test('.gradingScheme is the grading scheme for the assignment', () => {
      const gradingScheme = {
        id: '2801',
        data: [
          ['😂', 0.9],
          ['🙂', 0.8],
          ['😐', 0.7],
          ['😢', 0.6],
          ['💩', 0],
        ],
        title: 'Emoji Grades',
      }
      gradebook.getAssignment('2301').grading_standard_id = '2801'
      gradebook.courseContent.gradingSchemes = [gradingScheme]
      deepEqual(getProps().gradingScheme, gradingScheme.data)
    })

    test('.isSubmissionTrayOpen is true when the tray is open for the current student and assignment', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      strictEqual(getProps().isSubmissionTrayOpen, true)
    })

    test('.isSubmissionTrayOpen is false when the tray is closed', () => {
      gradebook.setSubmissionTrayState(false, '1101', '2301')
      strictEqual(getProps().isSubmissionTrayOpen, false)
    })

    test('.isSubmissionTrayOpen is true when the tray is open for a different student', () => {
      gradebook.setSubmissionTrayState(true, '1102', '2301')
      strictEqual(getProps().isSubmissionTrayOpen, false)
    })

    test('.isSubmissionTrayOpen is true when the tray is open for a different assignment', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2302')
      strictEqual(getProps().isSubmissionTrayOpen, false)
    })

    test('.onGradeSubmission is the .gradeSubmission Gradebook method', () => {
      strictEqual(getProps().onGradeSubmission, gradebook.gradeSubmission)
    })

    test('.onToggleSubmissionTrayOpen toggles the tray', () => {
      getProps().onToggleSubmissionTrayOpen()
      strictEqual(gradebook.getSubmissionTrayState().open, true)
    })

    test('.onToggleSubmissionTrayOpen toggles the tray using .toggleSubmissionTrayOpen', () => {
      sinon.stub(gradebook, 'toggleSubmissionTrayOpen')
      getProps().onToggleSubmissionTrayOpen()
      strictEqual(gradebook.toggleSubmissionTrayOpen.callCount, 1)
    })

    test('.onToggleSubmissionTrayOpen toggles the tray for the current student', () => {
      getProps().onToggleSubmissionTrayOpen()
      strictEqual(gradebook.getSubmissionTrayState().studentId, '1101')
    })

    test('.onToggleSubmissionTrayOpen toggles the tray for the current assignment', () => {
      getProps().onToggleSubmissionTrayOpen()
      strictEqual(gradebook.getSubmissionTrayState().assignmentId, '2301')
    })

    test('.pendingGradeInfo is included when a valid pending grade exists', () => {
      const pendingGradeInfo = {
        enteredAs: 'points',
        excused: false,
        grade: 'A',
        score: 10,
        valid: true,
      }
      gradebook.addPendingGradeInfo({assignmentId: '2301', userId: '1101'}, pendingGradeInfo)
      deepEqual(getProps().pendingGradeInfo, {
        ...pendingGradeInfo,
        assignmentId: '2301',
        userId: '1101',
      })
    })

    test('.pendingGradeInfo is null when no pending grade exists', () => {
      strictEqual(getProps().pendingGradeInfo, null)
    })

    test('.student is the student associated with the row of the cell', () => {
      deepEqual(getProps().student, gradebook.students['1101'])
    })

    test('.submission.assignmentId is the assignment id', () => {
      strictEqual(getProps().submission.assignmentId, '2301')
    })

    test('.submission.enteredGrade is the entered grade on the submission', () => {
      strictEqual(getProps().submission.enteredGrade, '7.8')
    })

    test('.submission.enteredScore is the entered score on the submission', () => {
      strictEqual(getProps().submission.enteredScore, 7.8)
    })

    test('.submission.excused is true when the submission is excused', () => {
      gradebook.getSubmission('1101', '2301').excused = true
      strictEqual(getProps().submission.excused, true)
    })

    test('.submission.excused is false when the value is undefined on the submission', () => {
      gradebook.getSubmission('1101', '2301').excused = undefined
      strictEqual(getProps().submission.excused, false)
    })

    test('.submission.grade is the final grade on the submission', () => {
      strictEqual(getProps().submission.grade, '6.8')
    })

    test('.submission.id is the submission id', () => {
      strictEqual(getProps().submission.id, '2501')
    })

    test('.submission.rawGrade is the raw grade on the submission', () => {
      strictEqual(getProps().submission.rawGrade, '6.8')
    })

    test('.submission.score is the final score on the submission', () => {
      strictEqual(getProps().submission.score, 6.8)
    })

    test('.submission.userId is the student id', () => {
      strictEqual(getProps().submission.userId, '1101')
    })

    QUnit.module('.submission.similarityInfo', () => {
      test('is null when not showing similarity scores in Gradebook', () => {
        strictEqual(getProps().submission.similarityInfo, null)
      })

      QUnit.module('when showing similarity scores in Gradebook', showSimilarityScoreHooks => {
        showSimilarityScoreHooks.beforeEach(() => {
          sinon.stub(gradebook, 'showSimilarityScore').returns(true)
        })

        showSimilarityScoreHooks.afterEach(() => {
          gradebook.showSimilarityScore.restore()
        })

        test('is null when the submission has no similarity data', () => {
          strictEqual(getProps().submission.similarityInfo, null)
        })

        test('is set to the first entry returned by extractSimilarityInfo if data is present', () => {
          const submission = {
            assignment_id: '2301',
            entered_grade: '7.8',
            entered_score: 7.8,
            excused: false,
            grade: '6.8',
            id: '2501',
            score: 6.8,
            submission_type: 'online_text_entry',
            turnitin_data: {
              submission_2501: {status: 'scored', similarity_score: 75},
            },
            user_id: '1101',
          }

          sinon.stub(gradebook, 'getSubmission').returns(submission)
          deepEqual(getProps().submission.similarityInfo, {status: 'scored', similarityScore: 75})
          gradebook.getSubmission.restore()
        })
      })
    })

    test('.submissionIsUpdating is true when a valid pending grade exists', () => {
      gradebook.addPendingGradeInfo(
        {assignmentId: '2301', userId: '1101'},
        {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true}
      )
      strictEqual(getProps().submissionIsUpdating, true)
    })

    test('.submissionIsUpdating is false when an invalid pending grade exists', () => {
      gradebook.addPendingGradeInfo(
        {assignmentId: '2301', userId: '1101'},
        {enteredAs: null, excused: false, grade: null, score: null, valid: false}
      )
      strictEqual(getProps().submissionIsUpdating, false)
    })

    test('.submissionIsUpdating is false when no pending grade exists', () => {
      strictEqual(getProps().submissionIsUpdating, false)
    })
  })
})
