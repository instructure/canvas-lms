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

import React from 'react'
import sinon from 'sinon'
import AssignmentRowCell from '../AssignmentRowCell'
import {render} from '@testing-library/react'

describe('GradebookGrid AssignmentRowCell', () => {
  let props
  let wrapper

  function simulateKeyDown(keyCode, ref, shiftKey = false) {
    const event = new Event('keydown')
    event.which = keyCode
    event.shiftKey = shiftKey
    return ref.handleKeyDown(event)
  }

  beforeEach(() => {
    ENV.GRADEBOOK_OPTIONS = {assignment_missing_shortcut: true}

    props = {
      assignment: {
        gradingType: 'points',
        id: '2301',
        pointsPossible: 10,
      },
      editorOptions: {
        column: {
          assignmentId: '2301',
          field: 'assignment_2301',
          object: {
            grading_type: 'points',
            id: '2301',
            points_possible: 10,
          },
        },
        grid: {},
        item: {
          // student row object
          id: '1101',
          assignment_2301: {
            // submission
            user_id: '1101',
          },
        },
      },
      enterGradesAs: 'points',
      gradingScheme: [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0.0],
      ],
      isSubmissionTrayOpen: false,
      onGradeSubmission() {},
      onToggleSubmissionTrayOpen() {},
      submission: {
        assignmentId: '2301',
        enteredGrade: '6.8',
        enteredScore: 7.8,
        excused: false,
        id: '2501',
        userId: '1101',
      },
      submissionIsUpdating: false,
    }
  })

  describe('#render()', () => {
    describe('when the "enter grades as setting" is "points"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'points'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__PointsInput').length).toBe(1)
      })

      test('sets focus on the grade input', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__PointsInput input:focus')
        ).toBeInTheDocument()
      })

      test('disables the AssignmentGradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__PointsInput input').disabled
        ).toBe(true)
      })

      test('renders end text', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__EndText').length).toBe(1)
      })

      test('renders points possible in the end text', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.getByText('/10')).toBeInTheDocument()
      })

      test('renders nothing in the end text when the assignment has no points possible', () => {
        props.assignment.pointsPossible = 0
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.queryByText('/10')).toBeNull()
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(0)
      })

      test('does not render a SimilarityIndicator when no similarity data is present', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(0)
      })

      test('does not render a SimilarityIndicator when data is present but the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        props.submission.similarityInfo = {status: 'pending'}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(0)
      })

      test('renders a SimilarityIndicator when similarity data is present and the pending grade is not invalid', () => {
        props.submission.similarityInfo = {similarityScore: 60, status: 'scored'}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(1)
      })

      test('renders the GradeCell div with the "points" class', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell').classList.contains('points')
        ).toBe(true)
      })
    })

    describe('when the "enter grades as setting" is "percent"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'percent'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__PercentInput').length).toBe(1)
      })

      test('sets focus on the grade input', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__PercentInput input:focus')
        ).toBeInTheDocument()
      })

      test('disables the AssignmentGradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__PercentInput input').disabled
        ).toBe(true)
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(0)
      })

      test('does not render a SimilarityIndicator when no similarity data is present', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(0)
      })

      test('does not render a SimilarityIndicator when data is present but the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        props.submission.similarityInfo = {status: 'pending'}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(0)
      })

      test('renders a SimilarityIndicator when similarity data is present and the pending grade is not invalid', () => {
        props.submission.similarityInfo = {similarityScore: 60, status: 'scored'}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(1)
      })

      test('renders the GradeCell div with the "percent" class', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell').classList.contains('percent')
        ).toBe(true)
      })
    })

    describe('when the "enter grades as setting" is "gradingScheme"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'gradingScheme'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__GradingSchemeInput').length
        ).toBe(1)
      })

      test('sets focus on the grade input', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__GradingSchemeInput input:focus')
        ).toBeInTheDocument()
      })

      test('disables the AssignmentGradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__GradingSchemeInput input').disabled
        ).toBe(true)
      })

      test('does not render end text', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__EndText').length).toBe(0)
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__InvalidGrade').length).toBe(0)
      })

      test('does not render a SimilarityIndicator when no similarity data is present', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(0)
      })

      test('does not render a SimilarityIndicator when data is present but the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        props.submission.similarityInfo = {status: 'pending'}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(0)
      })

      test('renders a SimilarityIndicator when similarity data is present and the pending grade is not invalid', () => {
        props.submission.similarityInfo = {similarityScore: 60, status: 'scored'}
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__OriginalityScore').length
        ).toBe(1)
      })

      test('renders the GradeCell div with the "gradingScheme" class', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell').classList.contains('gradingScheme')
        ).toBe(true)
      })
    })

    describe('when the "enter grades as setting" is "passFail"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'passFail'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelectorAll('.Grid__GradeCell__CompleteIncompleteInput').length
        ).toBe(1)
      })

      test('sets focus on the button', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__CompleteIncompleteInput button:focus')
        ).toBeInTheDocument()
      })

      test('does not render end text', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll('.Grid__GradeCell__EndText').length).toBe(0)
      })

      test('renders the GradeCell div with the "passFail" class', () => {
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(
          wrapper.container.querySelector('.Grid__GradeCell').classList.contains('passFail')
        ).toBe(true)
      })
    })

    describe('#handleKeyDown()', () => {
      describe('with a AssignmentGradeInput', () => {
        beforeEach(() => {
          props.assignment.gradingType = 'points'
        })

        test('skips SlickGrid default behavior when tabbing from grade input', () => {
          const ref = React.createRef()
          wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
          ref.current.gradeInput.focus()
          const continueHandling = simulateKeyDown(9, ref.current, false) // tab to tray button trigger
          expect(continueHandling).toBe(false)
        })

        test('skips SlickGrid default behavior when shift-tabbing from tray button', () => {
          const ref = React.createRef()
          wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
          ref.current.trayButton.focus()
          const continueHandling = simulateKeyDown(9, ref.current, true) // shift+tab back to grade input
          expect(continueHandling).toBe(false)
        })

        test('does not skip SlickGrid default behavior when tabbing from tray button', () => {
          const ref = React.createRef()
          wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
          ref.current.trayButton.focus()
          const continueHandling = simulateKeyDown(9, ref.current, false) // tab out of grid
          expect(typeof continueHandling).toBe('undefined')
        })

        test('does not skip SlickGrid default behavior when shift-tabbing from grade input', () => {
          const ref = React.createRef()
          wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
          ref.current.gradeInput.focus()
          const continueHandling = simulateKeyDown(9, ref.current, true) // shift+tab out of grid
          expect(typeof continueHandling).toBe('undefined')
        })

        test('skips SlickGrid default behavior when pressing enter on tray button', () => {
          const ref = React.createRef()
          wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
          ref.current.trayButton.focus()
          const continueHandling = simulateKeyDown(13, ref.current) // enter on tray button (open tray)
          expect(continueHandling).toBe(false)
        })

        test('does not skip SlickGrid default behavior when pressing enter on grade input', () => {
          const ref = React.createRef()
          wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
          ref.current.gradeInput.focus()
          const continueHandling = simulateKeyDown(13, ref.current) // enter on grade input (commit editor)
          expect(typeof continueHandling).toBe('undefined')
        })

        describe('when the grade is invalid', () => {
          beforeEach(() => {
            props.pendingGradeInfo = {excused: false, grade: null, valid: false}
          })

          test('Tab on the invalid grade indicator skips SlickGrid default behavior', () => {
            const ref = React.createRef()
            wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
            ref.current.startContainerIndicator.focus()
            const continueHandling = simulateKeyDown(9, ref.current, false) // tab to tray button trigger
            expect(continueHandling).toBe(false)
          })

          test('Shift+Tab on the grade input skips SlickGrid default behavior', () => {
            const ref = React.createRef()
            wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
            ref.current.gradeInput.focus()
            const continueHandling = simulateKeyDown(9, ref.current, true) // shift+tab back to indicator
            expect(continueHandling).toBe(false)
          })

          test('Shift+Tab on the invalid grade indicator does not skip SlickGrid default behavior', () => {
            const ref = React.createRef()
            wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
            ref.current.startContainerIndicator.focus()
            const continueHandling = simulateKeyDown(9, ref.current, true) // shift+tab out of grid
            expect(typeof continueHandling).toBe('undefined')
          })
        })

        describe('when similarity data is present', () => {
          beforeEach(() => {
            props.submission.similarityInfo = {similarityScore: 60, status: 'scored'}
          })

          test('Tab on the similarity icon skips SlickGrid default behavior', () => {
            const ref = React.createRef()
            wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
            ref.current.startContainerIndicator.focus()
            const continueHandling = simulateKeyDown(9, ref.current, false) // tab to tray button trigger
            expect(continueHandling).toBe(false)
          })

          test('Shift+Tab on the grade input skips SlickGrid default behavior', () => {
            const ref = React.createRef()
            wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
            ref.current.gradeInput.focus()
            const continueHandling = simulateKeyDown(9, ref.current, true) // shift+tab back to indicator
            expect(continueHandling).toBe(false)
          })

          test('Shift+Tab on the similarity icon does not skip SlickGrid default behavior', () => {
            const ref = React.createRef()
            wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
            ref.current.startContainerIndicator.focus()
            const continueHandling = simulateKeyDown(9, ref.current, true) // shift+tab out of grid
            expect(typeof continueHandling).toBe('undefined')
          })
        })
      })
    })

    describe('#focus()', () => {
      test('sets focus on the text input, if one exists, for a AssignmentGradeInput', () => {
        props.assignment.gradingType = 'points'
        const ref = React.createRef()
        wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
        ref.current.focus()
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__PointsInput input:focus')
        ).toBeInTheDocument()
      })

      test('sets focus on the button for a AssignmentGradeInput if no text input exists', () => {
        props.enterGradesAs = 'passFail'
        const ref = React.createRef()
        wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
        ref.current.focus()
        expect(
          wrapper.container.querySelector('.Grid__GradeCell__CompleteIncompleteInput button:focus')
        ).toBeInTheDocument()
      })
    })

    describe('#componentDidUpdate()', () => {
      test('sets focus on the grade input when the submission finishes updating', () => {
        props.submissionIsUpdating = true
        const ref = React.createRef()
        wrapper = render(<AssignmentRowCell {...props} ref={ref} />)
        props.submissionIsUpdating = false
        wrapper.rerender(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelector('input:focus')).toBeInTheDocument()
      })

      test('does not set focus on the grade input when the submission has not finished updating', () => {
        props.submissionIsUpdating = true
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelector('input:focus')).toBeNull()
      })

      test('does not set focus on the grade input when the tray button has focus', () => {
        props.submissionIsUpdating = true
        wrapper = render(<AssignmentRowCell {...props} />)
        wrapper.getByRole('button', {name: 'Open submission tray'}).focus()
        expect(wrapper.container.querySelector('button:focus')).toBeInTheDocument()
      })
    })

    describe('"Toggle Tray" Button', () => {
      const buttonSelector = '.Grid__GradeCell__Options button'

      test('is rendered when the assignment grading type is "points"', () => {
        props.assignment.gradingType = 'points'
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll(buttonSelector).length).toBe(1)
      })

      test('is rendered when the "enter grades as" setting is "passFail"', () => {
        props.enterGradesAs = 'passFail'
        wrapper = render(<AssignmentRowCell {...props} />)
        expect(wrapper.container.querySelectorAll(buttonSelector).length).toBe(1)
      })

      test('calls onToggleSubmissionTrayOpen when clicked', () => {
        props.onToggleSubmissionTrayOpen = sinon.stub()
        wrapper = render(<AssignmentRowCell {...props} />)
        wrapper.container.querySelector(buttonSelector).click()
        expect(props.onToggleSubmissionTrayOpen.callCount).toBe(1)
      })

      test('calls onToggleSubmissionTrayOpen with the student id and assignment id', () => {
        props.onToggleSubmissionTrayOpen = sinon.stub()
        wrapper = render(<AssignmentRowCell {...props} />)
        wrapper.container.querySelector(buttonSelector).click()
        expect(props.onToggleSubmissionTrayOpen.getCall(0).args).toStrictEqual(['1101', '2301'])
      })
    })
  })
})
