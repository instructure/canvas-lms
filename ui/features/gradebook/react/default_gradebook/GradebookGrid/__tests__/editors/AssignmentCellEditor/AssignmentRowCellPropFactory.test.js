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

import AssignmentRowCellPropFactory from '../../../editors/AssignmentCellEditor/AssignmentRowCellPropFactory'
import {createGradebook, setFixtureHtml} from '../../../../__tests__/GradebookSpecHelper'

describe('GradebookGrid AssignmentRowCellPropFactory', () => {
  let $container
  let gradebook

  describe('#getProps()', () => {
    let editorOptions

    function getProps() {
      const factory = new AssignmentRowCellPropFactory(gradebook)
      return factory.getProps(editorOptions)
    }

    beforeEach(() => {
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

      jest.spyOn(gradebook, 'updateRowAndRenderSubmissionTray').mockImplementation(() => {})
    })

    afterEach(() => {
      gradebook.destroy()
      $container.remove()
    })

    test('.assignment.id is the id on the assignment', () => {
      expect(getProps().assignment.id).toBe('2301')
    })

    test('.assignment.pointsPossible is the points possible on the assignment', () => {
      expect(getProps().assignment.pointsPossible).toBe(10)
    })

    test('.enterGradesAs is the "enter grades as" setting for the assignment', () => {
      gradebook.setEnterGradesAsSetting('2301', 'percent')
      expect(getProps().enterGradesAs).toBe('percent')
    })

    test('.gradeIsEditable is true when the grade for the submission is editable', () => {
      jest.spyOn(gradebook, 'isGradeEditable').mockReturnValue(true)
      expect(getProps().gradeIsEditable).toBe(true)
    })

    test('.gradeIsEditable is false when the grade for the submission is not editable', () => {
      jest.spyOn(gradebook, 'isGradeEditable').mockReturnValue(false)
      expect(getProps().gradeIsEditable).toBe(false)
    })

    test('.gradeIsVisible is true when the grade for the submission is visible', () => {
      jest.spyOn(gradebook, 'isGradeVisible').mockReturnValue(true)
      expect(getProps().gradeIsVisible).toBe(true)
    })

    test('.gradeIsVisible is false when the grade for the submission is not visible', () => {
      jest.spyOn(gradebook, 'isGradeVisible').mockReturnValue(false)
      expect(getProps().gradeIsVisible).toBe(false)
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
      expect(getProps().gradingScheme).toEqual(gradingScheme.data)
    })

    test('.isSubmissionTrayOpen is true when the tray is open for the current student and assignment', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2301')
      expect(getProps().isSubmissionTrayOpen).toBe(true)
    })

    test('.isSubmissionTrayOpen is false when the tray is closed', () => {
      gradebook.setSubmissionTrayState(false, '1101', '2301')
      expect(getProps().isSubmissionTrayOpen).toBe(false)
    })

    test('.isSubmissionTrayOpen is false when the tray is open for a different student', () => {
      gradebook.setSubmissionTrayState(true, '1102', '2301')
      expect(getProps().isSubmissionTrayOpen).toBe(false)
    })

    test('.isSubmissionTrayOpen is false when the tray is open for a different assignment', () => {
      gradebook.setSubmissionTrayState(true, '1101', '2302')
      expect(getProps().isSubmissionTrayOpen).toBe(false)
    })

    test('.onGradeSubmission is the .gradeSubmission Gradebook method', () => {
      expect(getProps().onGradeSubmission).toBe(gradebook.gradeSubmission)
    })

    test('.onToggleSubmissionTrayOpen toggles the tray', () => {
      getProps().onToggleSubmissionTrayOpen()
      expect(gradebook.getSubmissionTrayState().open).toBe(true)
    })

    test('.onToggleSubmissionTrayOpen toggles the tray using .toggleSubmissionTrayOpen', () => {
      jest.spyOn(gradebook, 'toggleSubmissionTrayOpen')
      getProps().onToggleSubmissionTrayOpen()
      expect(gradebook.toggleSubmissionTrayOpen).toHaveBeenCalledTimes(1)
    })

    test('.onToggleSubmissionTrayOpen toggles the tray for the current student', () => {
      getProps().onToggleSubmissionTrayOpen()
      expect(gradebook.getSubmissionTrayState().studentId).toBe('1101')
    })

    test('.onToggleSubmissionTrayOpen toggles the tray for the current assignment', () => {
      getProps().onToggleSubmissionTrayOpen()
      expect(gradebook.getSubmissionTrayState().assignmentId).toBe('2301')
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
      expect(getProps().pendingGradeInfo).toEqual({
        ...pendingGradeInfo,
        assignmentId: '2301',
        userId: '1101',
      })
    })

    test('.pendingGradeInfo is null when no pending grade exists', () => {
      expect(getProps().pendingGradeInfo).toBe(null)
    })

    test('.student is the student associated with the row of the cell', () => {
      expect(getProps().student).toEqual(gradebook.students['1101'])
    })

    test('.submission.assignmentId is the assignment id', () => {
      expect(getProps().submission.assignmentId).toBe('2301')
    })

    test('.submission.enteredGrade is the entered grade on the submission', () => {
      expect(getProps().submission.enteredGrade).toBe('7.8')
    })

    test('.submission.enteredScore is the entered score on the submission', () => {
      expect(getProps().submission.enteredScore).toBe(7.8)
    })

    test('.submission.excused is true when the submission is excused', () => {
      gradebook.getSubmission('1101', '2301').excused = true
      expect(getProps().submission.excused).toBe(true)
    })

    test('.submission.excused is false when the value is undefined on the submission', () => {
      gradebook.getSubmission('1101', '2301').excused = undefined
      expect(getProps().submission.excused).toBe(false)
    })

    test('.submission.grade is the final grade on the submission', () => {
      expect(getProps().submission.grade).toBe('6.8')
    })

    test('.submission.id is the submission id', () => {
      expect(getProps().submission.id).toBe('2501')
    })

    test('.submission.rawGrade is the raw grade on the submission', () => {
      expect(getProps().submission.rawGrade).toBe('6.8')
    })

    test('.submission.score is the final score on the submission', () => {
      expect(getProps().submission.score).toBe(6.8)
    })

    test('.submission.userId is the student id', () => {
      expect(getProps().submission.userId).toBe('1101')
    })

    describe('.submission.similarityInfo', () => {
      test('is null when not showing similarity scores in Gradebook', () => {
        expect(getProps().submission.similarityInfo).toBe(null)
      })

      describe('when showing similarity scores in Gradebook', () => {
        beforeEach(() => {
          jest.spyOn(gradebook, 'showSimilarityScore').mockReturnValue(true)
        })

        afterEach(() => {
          gradebook.showSimilarityScore.mockRestore()
        })

        test('is null when the submission has no similarity data', () => {
          expect(getProps().submission.similarityInfo).toBe(null)
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

          jest.spyOn(gradebook, 'getSubmission').mockReturnValue(submission)
          expect(getProps().submission.similarityInfo).toEqual({
            status: 'scored',
            similarityScore: 75,
          })
          gradebook.getSubmission.mockRestore()
        })
      })
    })

    test('.submissionIsUpdating is true when a valid pending grade exists', () => {
      gradebook.addPendingGradeInfo(
        {assignmentId: '2301', userId: '1101'},
        {enteredAs: 'points', excused: false, grade: 'A', score: 10, valid: true},
      )
      expect(getProps().submissionIsUpdating).toBe(true)
    })

    test('.submissionIsUpdating is false when an invalid pending grade exists', () => {
      gradebook.addPendingGradeInfo(
        {assignmentId: '2301', userId: '1101'},
        {enteredAs: null, excused: false, grade: null, score: null, valid: false},
      )
      expect(getProps().submissionIsUpdating).toBe(false)
    })

    test('.submissionIsUpdating is false when no pending grade exists', () => {
      expect(getProps().submissionIsUpdating).toBe(false)
    })
  })
})
