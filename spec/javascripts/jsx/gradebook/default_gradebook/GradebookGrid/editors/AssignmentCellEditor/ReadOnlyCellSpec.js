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
import {mount} from 'enzyme'
import ReadOnlyCell from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/AssignmentCellEditor/ReadOnlyCell'

QUnit.module('GradebookGrid ReadOnlyCell', suiteHooks => {
  let $container
  let props
  let wrapper

  function mountComponent() {
    return mount(<ReadOnlyCell {...props} />, {attachTo: $container})
  }

  function simulateKeyDown(keyCode, shiftKey = false) {
    const event = new Event('keydown')
    event.which = keyCode
    event.shiftKey = shiftKey
    return wrapper.instance().handleKeyDown(event)
  }

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

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

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  QUnit.module('#render()', () => {
    function getRenderedGrade() {
      return wrapper.find('.Grid__GradeCell__Content').text()
    }

    test('sets focus on the tray button', () => {
      wrapper = mountComponent()
      strictEqual(wrapper.instance().trayButton, document.activeElement)
    })

    test('renders "Excused" when the submission is excused', () => {
      props.submission.grade = null
      props.submission.score = null
      props.submission.excused = true
      wrapper = mountComponent()
      equal(getRenderedGrade(), 'Excused')
    })

    test('renders "–" (en dash) when the submission has no grade', () => {
      props.submission.grade = null
      props.submission.score = null
      wrapper = mountComponent()
      equal(getRenderedGrade(), '–')
    })

    test('renders no text when the grade is not visible', () => {
      props.gradeIsVisible = false
      wrapper = mountComponent()
      strictEqual(getRenderedGrade(), '')
    })

    test('renders the score converted to a points string  "enterGradesAs" is "points"', () => {
      wrapper = mountComponent()
      strictEqual(getRenderedGrade(), '7.8')
    })

    test('renders the score converted to a percentage when "enterGradesAs" is "percent"', () => {
      props.enterGradesAs = 'percent'
      wrapper = mountComponent()
      equal(getRenderedGrade(), '78%')
    })

    test('renders the score converted to a letter grade when "enterGradesAs" is "gradingScheme"', () => {
      props.enterGradesAs = 'gradingScheme'
      wrapper = mountComponent()
      equal(getRenderedGrade(), 'C')
    })

    QUnit.module('when "enterGradesAs" is "passFail"', contextHooks => {
      contextHooks.beforeEach(() => {
        props.enterGradesAs = 'passFail'
      })

      test('renders a checkmark when the grade is "complete"', () => {
        props.submission.rawGrade = 'complete'
        wrapper = mountComponent()
        strictEqual(wrapper.find('IconCheckMarkSolid').length, 1)
      })

      test('renders an x-mark when the grade is "incomplete"', () => {
        props.submission.rawGrade = 'incomplete'
        wrapper = mountComponent()
        strictEqual(wrapper.find('IconEndSolid').length, 1)
      })
    })
  })

  QUnit.module('#handleKeyDown()', () => {
    test('skips SlickGrid default behavior when pressing enter on tray button', () => {
      wrapper = mountComponent()
      const continueHandling = simulateKeyDown(13) // enter on tray button (open tray)
      strictEqual(continueHandling, false)
    })
  })

  QUnit.module('#gradeSubmission()', () => {
    test('has no effect', () => {
      wrapper = mountComponent()
      wrapper.instance().gradeSubmission()
      ok(true, 'satisfies the AssignmentCellEditor API')
    })
  })

  QUnit.module('#focus()', () => {
    test('sets focus on the tray button', () => {
      wrapper = mountComponent()
      wrapper.instance().focus()
      strictEqual(wrapper.instance().trayButton, document.activeElement)
    })
  })

  QUnit.module('#isValueChanged()', () => {
    test('returns false', () => {
      wrapper = mountComponent()
      strictEqual(wrapper.instance().isValueChanged(), false)
    })
  })

  QUnit.module('"Toggle Tray" Button', () => {
    test('calls onToggleSubmissionTrayOpen when clicked', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub()
      wrapper = mountComponent()
      wrapper.find('.Grid__GradeCell__Options button').simulate('click')
      strictEqual(props.onToggleSubmissionTrayOpen.callCount, 1)
    })

    test('calls onToggleSubmissionTrayOpen with the student id and assignment id', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub()
      wrapper = mountComponent()
      wrapper.find('.Grid__GradeCell__Options button').simulate('click')
      deepEqual(props.onToggleSubmissionTrayOpen.getCall(0).args, ['1101', '2301'])
    })
  })
})
