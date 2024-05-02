/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import ReadOnlyCell from '../ReadOnlyCell'
import {render} from '@testing-library/react'

describe('GradebookGrid ReadOnlyCell', () => {
  let props
  let wrapper
  let ref

  function mountComponent() {
    ref = React.createRef()
    wrapper = render(<ReadOnlyCell {...props} ref={ref} />)
  }

  function simulateKeyDown(keyCode, shiftKey = false) {
    const event = new Event('keydown')
    event.which = keyCode
    event.shiftKey = shiftKey
    return ref.current.handleKeyDown(event)
  }

  beforeEach(() => {
    props = {
      assignment: {
        gradingType: 'points',
        id: '2301',
        pointsPossible: 10,
      },
      enterGradesAs: 'points',
      gradeIsVisible: true,
      gradingScheme: [
        ['A', 0.9],
        ['B', 0.8],
        ['C', 0.7],
        ['D', 0.6],
        ['F', 0.0],
      ],
      isSubmissionTrayOpen: false,
      onToggleSubmissionTrayOpen() {},
      student: {
        id: '1101',
      },
      submission: {
        assignmentId: '2301',
        excused: false,
        grade: '6.8',
        id: '2501',
        rawGrade: '6.8',
        score: 7.8,
        userId: '1101',
      },
    }
  })

  afterEach(() => {
    wrapper.unmount()
  })

  describe('#render()', () => {
    test('sets focus on the tray button', () => {
      mountComponent()
      expect(ref.current.trayButton).toBe(document.activeElement)
    })

    test('renders "Excused" when the submission is excused', () => {
      props.submission.grade = null
      props.submission.score = null
      props.submission.excused = true
      mountComponent()
      expect(wrapper.getByText('Excused')).toBeInTheDocument()
    })

    test('renders "–" (en dash) when the submission has no grade', () => {
      props.submission.grade = null
      props.submission.score = null
      mountComponent()
      expect(wrapper.getByText('–')).toBeInTheDocument()
    })

    test('renders no text when the grade is not visible', () => {
      props.gradeIsVisible = false
      mountComponent()
      expect(wrapper.container.querySelector('.Grid__GradeCell__Content')).toBeEmptyDOMElement()
    })

    test('renders the score converted to a points string  "enterGradesAs" is "points"', () => {
      mountComponent()
      expect(wrapper.getByText('7.8')).toBeInTheDocument()
    })

    test('renders the score converted to a percentage when "enterGradesAs" is "percent"', () => {
      props.enterGradesAs = 'percent'
      mountComponent()
      expect(wrapper.getByText('78%')).toBeInTheDocument()
    })

    test('renders the score converted to a letter grade when "enterGradesAs" is "gradingScheme"', () => {
      props.enterGradesAs = 'gradingScheme'
      mountComponent()
      expect(wrapper.getByText('C')).toBeInTheDocument()
    })

    describe('when "enterGradesAs" is "passFail"', () => {
      beforeEach(() => {
        props.enterGradesAs = 'passFail'
      })

      test('renders a checkmark when the grade is "complete"', () => {
        props.submission.rawGrade = 'complete'
        mountComponent()
        expect(wrapper.container.querySelectorAll('svg[name="IconCheckMark"]')).toHaveLength(1)
      })

      test('renders an x-mark when the grade is "incomplete"', () => {
        props.submission.rawGrade = 'incomplete'
        mountComponent()
        expect(wrapper.container.querySelectorAll('svg[name="IconEnd"]')).toHaveLength(1)
      })
    })
  })

  describe('#handleKeyDown()', () => {
    test('skips SlickGrid default behavior when pressing enter on tray button', () => {
      mountComponent()
      const continueHandling = simulateKeyDown(13) // enter on tray button (open tray)
      expect(continueHandling).toBe(false)
    })
  })

  describe('#gradeSubmission()', () => {
    test('has no effect', () => {
      mountComponent()
      ref.current.gradeSubmission()
    })
  })

  describe('#focus()', () => {
    test('sets focus on the tray button', () => {
      mountComponent()
      ref.current.focus()
      expect(wrapper.container.querySelector('button:focus')).toBeInTheDocument()
    })
  })

  describe('#isValueChanged()', () => {
    test('returns false', () => {
      mountComponent()
      expect(ref.current.isValueChanged()).toBe(false)
    })
  })

  describe('"Toggle Tray" Button', () => {
    test('calls onToggleSubmissionTrayOpen when clicked', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub()
      mountComponent()
      wrapper.container.querySelector('.Grid__GradeCell__Options button').click()
      expect(props.onToggleSubmissionTrayOpen.callCount).toBe(1)
    })

    test('calls onToggleSubmissionTrayOpen with the student id and assignment id', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub()
      mountComponent()
      wrapper.container.querySelector('.Grid__GradeCell__Options button').click()
      expect(props.onToggleSubmissionTrayOpen.getCall(0).args).toStrictEqual(['1101', '2301'])
    })
  })
})
