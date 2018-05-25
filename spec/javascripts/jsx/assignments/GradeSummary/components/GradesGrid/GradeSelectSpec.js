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

import GradeSelect from 'jsx/assignments/GradeSummary/components/GradesGrid/GradeSelect'
import {FAILURE, STARTED, SUCCESS} from 'jsx/assignments/GradeSummary/grades/GradeActions'

QUnit.module('GradeSummary GradeSelect', suiteHooks => {
  let props
  let qunitTimeout
  let resolveOpenCloseState
  let selectedGrade
  let wrapper

  suiteHooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // prevent accidental unresolved async

    selectedGrade = null

    props = {
      graders: [
        {graderId: '1101', graderName: 'Miss Frizzle'},
        {graderId: '1102', graderName: 'Mr. Keating'}
      ],
      grades: {
        1101: {
          grade: 'A',
          graderId: '1101',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111'
        },
        1102: {
          grade: 'B',
          graderId: '1102',
          id: '4602',
          score: 8.9,
          selected: true,
          studentId: '1111'
        }
      },
      onClose() {
        resolveOpenCloseState()
      },
      onOpen() {
        resolveOpenCloseState()
      },
      onSelect(gradeInfo) {
        selectedGrade = gradeInfo
      },
      selectProvisionalGradeStatus: null,
      studentName: 'Adam Jones'
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    QUnit.config.testTimeout = qunitTimeout
  })

  function mountComponent() {
    wrapper = mount(<GradeSelect {...props} />)
  }

  function getOptionList() {
    const controlledContentId = wrapper.find('input').prop('aria-controls')
    return document.getElementById(controlledContentId)
  }

  function getOptions() {
    const $list = getOptionList()
    const $items = $list.querySelectorAll('li[role="option"]')
    return Array.from($items)
  }

  function getOptionLabels() {
    return getOptions().map($option => $option.textContent.trim())
  }

  function openSelect() {
    return new Promise(resolve => {
      resolveOpenCloseState = resolve
      wrapper.find('input').simulate('click')
    })
  }

  function selectOption(optionLabel) {
    return openSelect().then(
      () =>
        new Promise(resolve => {
          resolveOpenCloseState = resolve
          const $option = getOptions().find($el => $el.textContent.trim() === optionLabel)
          $option.click()
        })
    )
  }

  function getTextInputValue() {
    return wrapper.find('input').getDOMNode().value
  }

  function labelForGrader(graderId) {
    const gradeInfo = props.grades[graderId]
    const grader = props.graders.find(g => g.graderId === graderId)
    return `${gradeInfo.score} (${grader.graderName})`
  }

  test('renders a text input', () => {
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.length, 1)
  })

  test('uses the student name for a label', () => {
    mountComponent()
    const label = wrapper.find('label')
    strictEqual(label.text(), 'Grade for Adam Jones')
  })

  test('includes an option for each grader who graded', () => {
    mountComponent()
    strictEqual(getOptions().length, 2)
  })

  test('displays the grade and grader name as option labels', () => {
    mountComponent()
    deepEqual(getOptionLabels(), [labelForGrader('1101'), labelForGrader('1102')])
  })

  test('sets as the input value the selected provisional grade', () => {
    mountComponent()
    equal(getTextInputValue(), labelForGrader('1102'))
  })

  test('calls the onSelect prop when an option is clicked', async () => {
    props.onSelect = sinon.spy()
    mountComponent()
    await selectOption(labelForGrader('1101'))
    strictEqual(props.onSelect.callCount, 1)
  })

  test('includes the related grade info when calling onSelect', async () => {
    mountComponent()
    await selectOption(labelForGrader('1101'))
    deepEqual(selectedGrade, props.grades[1101])
  })

  test('does not call the onSelect prop when the option for the selected grade is clicked', async () => {
    props.onSelect = sinon.spy()
    mountComponent()
    await selectOption(labelForGrader('1102'))
    strictEqual(props.onSelect.callCount, 0)
  })

  test('sets the input to read-only when not given an onSelect prop', () => {
    props.onSelect = null
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.prop('aria-readonly'), true)
  })

  test('has no effect when an option is clicked and not given an onSelect prop', async () => {
    props.onSelect = null
    mountComponent()
    await selectOption(labelForGrader('1102'))
    ok('component gracefully ignores the event')
  })

  test('sets the input to read-only when grade selection is pending', () => {
    props.selectProvisionalGradeStatus = STARTED
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.prop('aria-readonly'), true)
  })

  test('enables the input when grade selection was successful', () => {
    props.selectProvisionalGradeStatus = SUCCESS
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.prop('aria-disabled'), null)
  })

  test('enables the input when grade selection has failed', () => {
    props.selectProvisionalGradeStatus = FAILURE
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.prop('aria-disabled'), null)
  })

  QUnit.module('when no grade has been selected', hooks => {
    hooks.beforeEach(() => {
      props.grades[1102].selected = false
    })

    test('includes an option for "no selection"', () => {
      mountComponent()
      strictEqual(getOptionLabels()[0], '–')
    })

    test('includes an option for each grader who graded', () => {
      mountComponent()
      strictEqual(getOptions().length, 3) // two graders plus "no selection" option
    })

    test('set the input value to "–" (en dash)', () => {
      mountComponent()
      strictEqual(getTextInputValue(), '–')
    })
  })

  QUnit.module('when the component instance is reused for another student', hooks => {
    /*
     * The purpose of this context is to help ensure that component instance
     * reuse does not result in state-based bugs. When updating input components
     * like Select, updating internal state can easily lead to mismatches
     * between old state and new props.
     */

    hooks.beforeEach(() => {
      mountComponent()
      props = JSON.parse(JSON.stringify(props))
      props.studentName = 'Betty Ford'
      props.grades[1101].studentId = '1112'
      props.grades[1102].studentId = '1112'
    })

    test('includes an option for "no selection" when the student has no selected grade', () => {
      props.grades[1102].selected = false
      wrapper.setProps(props)
      strictEqual(getOptions().length, 3) // two graders plus "no selection" option
    })

    test('excludes the option for "no selection" when the student has a selected grade', () => {
      wrapper.setProps(props)
      strictEqual(getOptions().length, 2) // only the two graders
    })
  })
})
