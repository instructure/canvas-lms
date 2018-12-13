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
import {mount} from 'enzyme'
import AssignmentRowCell from 'jsx/gradezilla/default_gradebook/GradebookGrid/editors/AssignmentCellEditor/AssignmentRowCell'

QUnit.module('GradebookGrid AssignmentRowCell', suiteHooks => {
  let $container
  let props
  let wrapper

  function mountComponent() {
    return mount(<AssignmentRowCell {...props} />, {attachTo: $container})
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
        pointsPossible: 10
      },
      editorOptions: {
        column: {
          assignmentId: '2301',
          field: 'assignment_2301',
          object: {
            grading_type: 'points',
            id: '2301',
            points_possible: 10
          }
        },
        grid: {},
        item: {
          // student row object
          id: '1101',
          assignment_2301: {
            // submission
            user_id: '1101'
          }
        }
      },
      enterGradesAs: 'points',
      gradingScheme: [['A', 0.9], ['B', 0.8], ['C', 0.7], ['D', 0.6], ['F', 0.0]],
      isSubmissionTrayOpen: false,
      onGradeSubmission() {},
      onToggleSubmissionTrayOpen() {},
      submission: {
        assignmentId: '2301',
        enteredGrade: '6.8',
        enteredScore: 7.8,
        excused: false,
        id: '2501',
        userId: '1101'
      },
      submissionIsUpdating: false
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  QUnit.module('#render()', () => {
    test('assigns a reference to its child SubmissionCell container', () => {
      wrapper = mountComponent()
      const $el = wrapper.getDOMNode()
      ok(
        $el.contains(wrapper.instance().contentContainer),
        'component node contains the referenced container node'
      )
    })

    QUnit.module('when the "enter grades as setting" is "points"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'points'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').length, 1)
      })

      test('sets focus on the grade input', () => {
        wrapper = mountComponent()
        const node = wrapper.find('AssignmentGradeInput input').at(0)
        strictEqual(node.getDOMNode(), document.activeElement)
      })

      test('disables the AssignmentGradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').prop('disabled'), true)
      })

      test('renders end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__EndText').length, 1)
      })

      test('renders points possible in the end text', () => {
        wrapper = mountComponent()
        equal(wrapper.find('.Grid__GradeCell__EndText').text(), '/10')
      })

      test('renders nothing in the end text when the assignment has no points possible', () => {
        props.assignment.pointsPossible = 0
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__EndText').text(), '')
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 0)
      })

      test('renders the GradeCell div with the "points" class', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell').hasClass('points'), true)
      })
    })

    QUnit.module('when the "enter grades as setting" is "percent"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'percent'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').length, 1)
      })

      test('sets focus on the grade input', () => {
        wrapper = mountComponent()
        const node = wrapper.find('AssignmentGradeInput input').at(0)
        strictEqual(node.getDOMNode(), document.activeElement)
      })

      test('disables the AssignmentGradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').prop('disabled'), true)
      })

      test('renders end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__EndText').length, 1)
      })

      test('renders nothing in the end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__EndText').text(), '')
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 0)
      })

      test('renders the GradeCell div with the "percent" class', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell').hasClass('percent'), true)
      })
    })

    QUnit.module('when the "enter grades as setting" is "gradingScheme"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'gradingScheme'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').length, 1)
      })

      test('sets focus on the grade input', () => {
        wrapper = mountComponent()
        const node = wrapper.find('AssignmentGradeInput input').at(0)
        strictEqual(node.getDOMNode(), document.activeElement)
      })

      test('disables the AssignmentGradeInput when the submission is updating', () => {
        props.submissionIsUpdating = true
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').prop('disabled'), true)
      })

      test('does not render end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__EndText').length, 0)
      })

      test('renders an InvalidGradeIndicator when the pending grade is invalid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 1)
      })

      test('does not render an InvalidGradeIndicator when the pending grade is valid', () => {
        props.pendingGradeInfo = {excused: false, grade: null, valid: true}
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 0)
      })

      test('does not render an InvalidGradeIndicator when no pending grade is present', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__InvalidGrade').length, 0)
      })

      test('renders the GradeCell div with the "gradingScheme" class', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell').hasClass('gradingScheme'), true)
      })
    })

    QUnit.module('when the "enter grades as setting" is "passFail"', hooks => {
      hooks.beforeEach(() => {
        props.enterGradesAs = 'passFail'
      })

      test('renders a AssignmentGradeInput', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('AssignmentGradeInput').length, 1)
      })

      test('sets focus on the button', () => {
        wrapper = mountComponent()
        const node = wrapper.find('AssignmentGradeInput button').at(0)
        strictEqual(node.getDOMNode(), document.activeElement)
      })

      test('does not render end text', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell__EndText').length, 0)
      })

      test('renders the GradeCell div with the "passFail" class', () => {
        wrapper = mountComponent()
        strictEqual(wrapper.find('.Grid__GradeCell').hasClass('passFail'), true)
      })
    })
  })

  QUnit.module('#handleKeyDown()', () => {
    QUnit.module('with a AssignmentGradeInput', hooks => {
      hooks.beforeEach(() => {
        props.assignment.gradingType = 'points'
      })

      test('skips SlickGrid default behavior when tabbing from grade input', () => {
        wrapper = mountComponent()
        wrapper.instance().gradeInput.focus()
        const continueHandling = simulateKeyDown(9, false) // tab to tray button trigger
        strictEqual(continueHandling, false)
      })

      test('skips SlickGrid default behavior when shift-tabbing from tray button', () => {
        wrapper = mountComponent()
        wrapper.instance().trayButton.focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to grade input
        strictEqual(continueHandling, false)
      })

      test('skips SlickGrid default behavior when the input handles the event', () => {
        wrapper = mountComponent()
        wrapper.instance().gradeInput.focus()
        sinon.stub(wrapper.find('AssignmentGradeInput').instance(), 'handleKeyDown').returns(false)
        const continueHandling = simulateKeyDown(9) // tab within the grade input
        strictEqual(continueHandling, false)
      })

      test('does not skip SlickGrid default behavior when tabbing from tray button', () => {
        wrapper = mountComponent()
        wrapper.instance().trayButton.focus()
        const continueHandling = simulateKeyDown(9, false) // tab out of grid
        equal(typeof continueHandling, 'undefined')
      })

      test('does not skip SlickGrid default behavior when shift-tabbing from grade input', () => {
        wrapper = mountComponent()
        wrapper.instance().gradeInput.focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab out of grid
        equal(typeof continueHandling, 'undefined')
      })

      test('skips SlickGrid default behavior when pressing enter on tray button', () => {
        wrapper = mountComponent()
        wrapper.instance().trayButton.focus()
        const continueHandling = simulateKeyDown(13) // enter on tray button (open tray)
        strictEqual(continueHandling, false)
      })

      test('does not skip SlickGrid default behavior when pressing enter on grade input', () => {
        wrapper = mountComponent()
        wrapper.instance().gradeInput.focus()
        const continueHandling = simulateKeyDown(13) // enter on grade input (commit editor)
        equal(typeof continueHandling, 'undefined')
      })

      QUnit.module('when the grade is invalid', contextHooks => {
        contextHooks.beforeEach(() => {
          props.pendingGradeInfo = {excused: false, grade: null, valid: false}
        })

        test('Tab on the invalid grade indicator skips SlickGrid default behavior', () => {
          wrapper = mountComponent()
          wrapper.instance().invalidGradeIndicator.focus()
          const continueHandling = simulateKeyDown(9, false) // tab to tray button trigger
          strictEqual(continueHandling, false)
        })

        test('Shift+Tab on the grade input skips SlickGrid default behavior', () => {
          wrapper = mountComponent()
          wrapper.instance().gradeInput.focus()
          const continueHandling = simulateKeyDown(9, true) // shift+tab back to indicator
          strictEqual(continueHandling, false)
        })

        test('Shift+Tab on the invalid grade indicator does not skip SlickGrid default behavior', () => {
          wrapper = mountComponent()
          wrapper.instance().invalidGradeIndicator.focus()
          const continueHandling = simulateKeyDown(9, true) // shift+tab out of grid
          equal(typeof continueHandling, 'undefined')
        })
      })
    })
  })

  QUnit.module('#focus()', () => {
    test('sets focus on the text input, if one exists, for a AssignmentGradeInput', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      wrapper.instance().focus()
      const input = wrapper.find('AssignmentGradeInput input')
      strictEqual(input.at(0).getDOMNode(), document.activeElement)
    })

    test('sets focus on the button for a AssignmentGradeInput if no text input exists', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      wrapper.instance().focus()
      const button = wrapper.find('AssignmentGradeInput button')
      strictEqual(button.at(0).getDOMNode(), document.activeElement)
    })
  })

  QUnit.module('#isValueChanged()', () => {
    test('delegates to the "hasGradeChanged" method for a AssignmentGradeInput', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      sinon.stub(wrapper.find('AssignmentGradeInput').instance(), 'hasGradeChanged').returns(true)
      strictEqual(wrapper.instance().isValueChanged(), true)
    })
  })

  QUnit.module('#componentDidUpdate()', () => {
    test('sets focus on the grade input when the submission finishes updating', () => {
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      wrapper.setProps({submissionIsUpdating: false})
      strictEqual(
        document.activeElement,
        wrapper
          .find('input')
          .at(0)
          .getDOMNode()
      )
    })

    test('does not set focus on the grade input when the submission has not finished updating', () => {
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      wrapper.setProps({submissionIsUpdating: true})
      notStrictEqual(
        document.activeElement,
        wrapper
          .find('input')
          .at(0)
          .getDOMNode()
      )
    })

    test('does not set focus on the grade input when the tray button has focus', () => {
      props.submissionIsUpdating = true
      wrapper = mountComponent()
      const button = wrapper
        .find('button')
        .at(0)
        .getDOMNode()
      button.focus()
      wrapper.setProps({submissionIsUpdating: false})
      strictEqual(document.activeElement, button)
    })
  })

  QUnit.module('"Toggle Tray" Button', () => {
    const buttonSelector = '.Grid__GradeCell__Options button'

    test('is rendered when the assignment grading type is "points"', () => {
      props.assignment.gradingType = 'points'
      wrapper = mountComponent()
      strictEqual(wrapper.find(buttonSelector).length, 1)
    })

    test('is rendered when the "enter grades as" setting is "passFail"', () => {
      props.enterGradesAs = 'passFail'
      wrapper = mountComponent()
      strictEqual(wrapper.find(buttonSelector).length, 1)
    })

    test('calls onToggleSubmissionTrayOpen when clicked', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub()
      wrapper = mountComponent()
      wrapper.find(buttonSelector).simulate('click')
      strictEqual(props.onToggleSubmissionTrayOpen.callCount, 1)
    })

    test('calls onToggleSubmissionTrayOpen with the student id and assignment id', () => {
      props.onToggleSubmissionTrayOpen = sinon.stub()
      wrapper = mountComponent()
      wrapper.find(buttonSelector).simulate('click')
      deepEqual(props.onToggleSubmissionTrayOpen.getCall(0).args, ['1101', '2301'])
    })
  })
})
