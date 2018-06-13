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

function Container(props) {
  /*
   * This class exists because Enzyme does not update props of children, which
   * is necessary to test the full behavior of this component.
   */

  return (
    <div>
      <GradeSelect {...props} />
      <button id="next-element">Next Element</button>
    </div>
  )
}

QUnit.module('GradeSummary GradeSelect', suiteHooks => {
  const keyCodes = {
    ENTER: 13,
    ESCAPE: 27
  }

  let $container
  let props
  let qunitTimeout
  let resolveOpenCloseState
  let resolvePositioned
  let selectedGrade
  let wrapper

  suiteHooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // prevent accidental unresolved async

    $container = document.createElement('div')
    document.body.appendChild($container)

    selectedGrade = null

    props = {
      finalGrader: {
        graderId: 'teach',
        id: '1105'
      },
      graders: [
        {graderId: 'frizz', graderName: 'Miss Frizzle'},
        {graderId: 'robin', graderName: 'Mr. Keating'},
        {graderId: 'ednak', graderName: 'Mrs. Krabappel'},
        {graderId: 'feeny', graderName: 'Mr. Feeny'}
      ],
      grades: {
        frizz: {
          grade: 'A',
          graderId: 'frizz',
          id: '4601',
          score: 10,
          selected: false,
          studentId: '1111'
        },
        robin: {
          grade: 'B',
          graderId: 'robin',
          id: '4602',
          score: 8.6,
          selected: false,
          studentId: '1111'
        },
        feeny: {
          grade: 'C+',
          graderId: 'feeny',
          id: '4603',
          score: 7.9,
          selected: false,
          studentId: '1111'
        }
      },
      onClose() {
        resolveOpenCloseState()
      },
      onOpen() {
        resolveOpenCloseState()
      },
      onPositioned() {
        resolvePositioned()
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
    return new Promise(resolve => {
      resolvePositioned = resolve
      wrapper = mount(<Container {...props} />, {attachTo: $container})
    })
  }

  function blurElement($el) {
    $el.blur()
    const event = new Event('blur', {bubbles: true, cancelable: true})
    $el.dispatchEvent(event)
  }

  function focusElement($el) {
    $el.focus()
    const event = new Event('focus', {bubbles: true, cancelable: true})
    $el.dispatchEvent(event)
  }

  function getTextInput() {
    return wrapper.find('input').get(0)
  }

  function clickInputToOpenMenu() {
    return new Promise(resolve => {
      resolveOpenCloseState = resolve
      const $input = getTextInput()
      focusElement($input)
      $input.click()
    })
  }

  function keyDownOnInput(keyCode) {
    wrapper.find('input').simulate('keyDown', {keyCode})
  }

  function keyUpOnInput(keyCode) {
    wrapper.find('input').simulate('keyUp', {keyCode})
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

  function getOption(optionLabel) {
    return getOptions().find($el => $el.textContent.trim() === optionLabel)
  }

  function clickOption(optionLabel) {
    return new Promise(resolve => {
      resolveOpenCloseState = resolve
      getOption(optionLabel).click()
    })
  }

  function arrowDownTo(optionLabel) {
    const options = getOptions()
    const steps = getOptionLabels().indexOf(optionLabel)

    for (let i = 0; i < steps; i++) {
      const event = new Event('keydown', {bubbles: true, cancelable: true})
      event.keyCode = 40 // down arrow
      options[i].dispatchEvent(event)
    }
  }

  function focusOption(optionLabel) {
    blurElement(document.activeElement)
    focusElement(getOption(optionLabel))
  }

  function keyUpOnOption(optionLabel, keyCode) {
    const event = new Event('keyup', {bubbles: true, cancelable: true})
    event.keyCode = keyCode
    getOption(optionLabel).dispatchEvent(event)
  }

  function keyDownOnOption(optionLabel, keyCode) {
    const event = new Event('keydown', {bubbles: true, cancelable: true})
    event.keyCode = keyCode
    getOption(optionLabel).dispatchEvent(event)
  }

  function labelForGrader(graderId) {
    const gradeInfo = props.grades[graderId]
    const grader = props.graders.find(g => g.graderId === graderId)
    return `${gradeInfo.score} (${grader.graderName})`
  }

  function customLabel(score) {
    return `${score} (Custom)`
  }

  async function mountAndClick() {
    await mountComponent()
    await clickInputToOpenMenu()
  }

  test('renders a text input', async () => {
    await mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.length, 1)
  })

  test('uses the student name for a label', async () => {
    await mountComponent()
    const label = wrapper.find('label')
    strictEqual(label.text(), 'Grade for Adam Jones')
  })

  QUnit.module('when a grade has been selected', hooks => {
    hooks.beforeEach(() => {
      props.grades.robin.selected = true
    })

    test('excludes an option for "no selection"', async () => {
      await mountComponent()
      notOk(getOptionLabels().includes('–'))
    })

    test('does not include an option for graders who did not grade', async () => {
      await mountComponent()
      const labels = getOptionLabels().filter(label => label.match(/Krabappel/))
      strictEqual(labels.length, 0)
    })

    test('includes an option for each grader who graded', async () => {
      await mountComponent()
      deepEqual(getOptionLabels(), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('sets as the input value the selected provisional grade', async () => {
      await mountComponent()
      equal(getTextInput().value, labelForGrader('robin'))
    })
  })

  QUnit.module('when no grade has been selected', () => {
    test('includes an option for "no selection"', async () => {
      await mountComponent()
      strictEqual(getOptionLabels()[0], '–')
    })

    test('displays the grade and grader name as option labels', async () => {
      await mountComponent()
      deepEqual(getOptionLabels().slice(1), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('set the input value to "–" (en dash)', async () => {
      await mountComponent()
      strictEqual(getTextInput().value, '–')
    })
  })

  QUnit.module('when selecting an existing grade', () => {
    async function openAndSelect(optionLabel) {
      await mountComponent()
      await clickInputToOpenMenu()
      await clickOption(optionLabel)
    }

    test('calls the onSelect prop', async () => {
      props.onSelect = sinon.spy()
      await openAndSelect(labelForGrader('frizz'))
      strictEqual(props.onSelect.callCount, 1)
    })

    test('includes the related grade info when calling onSelect', async () => {
      await openAndSelect(labelForGrader('frizz'))
      deepEqual(selectedGrade, props.grades.frizz)
    })

    test('does not call the onSelect prop when the option for the selected grade is clicked', async () => {
      props.grades.robin.selected = true
      props.onSelect = sinon.spy()
      await openAndSelect(labelForGrader('robin'))
      strictEqual(props.onSelect.callCount, 0)
    })
  })

  QUnit.module('when a custom grade exists for the final grader', contextHooks => {
    contextHooks.beforeEach(() => {
      props.grades.teach = {
        grade: 'A++',
        graderId: 'teach',
        id: '4604',
        score: 11,
        selected: false,
        studentId: '1111'
      }
    })

    test('includes a custom grade option', async () => {
      await mountAndClick()
      ok(getOptionLabels().includes(customLabel('11')))
    })

    test('includes the "no selection" option when no grade is selected', async () => {
      await mountAndClick()
      ok(getOptionLabels().includes('–'))
    })

    test('excludes the "no selection" option when the custom grade is selected', async () => {
      props.grades.teach.selected = true
      await mountAndClick()
      notOk(getOptionLabels().includes('–'))
    })

    QUnit.module('when clicking the custom grade option', hooks => {
      hooks.beforeEach(() => {
        props.onSelect = sinon.spy()
      })

      test('does not call the onSelect prop when the custom grade is selected', async () => {
        props.grades.teach.selected = true
        await mountAndClick()
        await clickOption(customLabel('11'))
        strictEqual(props.onSelect.callCount, 0)
      })

      test('calls the onSelect prop when the custom grade is not selected', async () => {
        await mountAndClick()
        await clickOption(customLabel('11'))
        strictEqual(props.onSelect.callCount, 1)
      })

      test('includes the custom grade info when calling the onSelect prop', async () => {
        await mountAndClick()
        await clickOption(customLabel('11'))
        const [gradeInfo] = props.onSelect.lastCall.args
        deepEqual(gradeInfo, props.grades.teach)
      })
    })
  })

  QUnit.module('when no custom grade exists for the final grader', () => {
    test('does not include a custom grade option', async () => {
      await mountAndClick()
      deepEqual(getOptionLabels().slice(1), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('includes the "no selection" option', async () => {
      await mountAndClick()
      ok(getOptionLabels().includes('–'))
    })
  })

  QUnit.module('when the assignment does not have a final grader', contextHooks => {
    contextHooks.beforeEach(() => {
      props.finalGrader = null
    })

    test('does not include a custom grade option', async () => {
      await mountAndClick()
      deepEqual(getOptionLabels().slice(1), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('includes the "no selection" option', async () => {
      await mountAndClick()
      ok(getOptionLabels().includes('–'))
    })
  })

  QUnit.module('when a grade selection is pending', hooks => {
    hooks.beforeEach(async () => {
      props.selectProvisionalGradeStatus = STARTED
      await mountComponent()
    })

    test('sets the input to read-only while grade selection is pending', () => {
      const input = wrapper.find('input[type="text"]')
      strictEqual(input.prop('aria-readonly'), true)
    })

    test('enables the input when grade selection was successful', () => {
      wrapper.setProps({selectProvisionalGradeStatus: SUCCESS})
      const input = wrapper.find('input[type="text"]')
      strictEqual(input.prop('aria-disabled'), null)
    })

    test('enables the input when grade selection has failed', () => {
      wrapper.setProps({selectProvisionalGradeStatus: FAILURE})
      const input = wrapper.find('input[type="text"]')
      strictEqual(input.prop('aria-disabled'), null)
    })
  })

  QUnit.module('when not given an onSelect prop (grades have been published)', hooks => {
    hooks.beforeEach(async () => {
      props.onSelect = null
      await mountComponent()
    })

    test('sets the input to read-only', () => {
      const input = wrapper.find('input[type="text"]')
      strictEqual(input.prop('aria-readonly'), true)
    })

    test('has no effect when an option is clicked', async () => {
      await clickInputToOpenMenu()
      await clickOption(labelForGrader('robin'))
      ok('component gracefully ignores the event')
    })
  })

  QUnit.module('when the input has focus and Escape is pressed', hooks => {
    hooks.beforeEach(async () => {
      props.onSelect = sinon.spy()
      await mountComponent()
      await clickInputToOpenMenu()
    })

    test('dismisses the options list', () => {
      keyUpOnInput(keyCodes.ESCAPE)
      const style = window.getComputedStyle(getOptionList())
      equal(style.display, 'none')
    })

    test('does not call the onSelect prop', () => {
      keyUpOnInput(keyCodes.ESCAPE)
      strictEqual(props.onSelect.callCount, 0)
    })

    test('sets focus on the input', () => {
      keyUpOnInput(keyCodes.ESCAPE)
      strictEqual(document.activeElement, wrapper.find('input').get(0))
    })
  })

  QUnit.module('when an option has focus and Escape is pressed', hooks => {
    hooks.beforeEach(async () => {
      props.onSelect = sinon.spy()
      await mountComponent()
      await clickInputToOpenMenu()
    })

    test('dismisses the options list', () => {
      focusOption(labelForGrader('robin'))
      keyUpOnOption(labelForGrader('robin'), keyCodes.ESCAPE)
      const style = window.getComputedStyle(getOptionList())
      equal(style.display, 'none')
    })

    test('does not call the onSelect prop', () => {
      focusOption(labelForGrader('robin'))
      keyUpOnOption(labelForGrader('robin'), keyCodes.ESCAPE)
      strictEqual(props.onSelect.callCount, 0)
    })

    test('sets focus on the input', () => {
      focusOption(labelForGrader('robin'))
      keyUpOnOption(labelForGrader('robin'), keyCodes.ESCAPE)
      strictEqual(document.activeElement, wrapper.find('input').get(0))
    })
  })

  QUnit.module('when the input has focus and Enter is pressed', hooks => {
    hooks.beforeEach(async () => {
      props.onSelect = sinon.spy()
      await mountComponent()
      await clickInputToOpenMenu()
    })

    test('dismisses the options list', async () => {
      await keyDownOnInput(keyCodes.ENTER)
      const style = window.getComputedStyle(getOptionList())
      equal(style.display, 'none')
    })
  })

  QUnit.module('when an option has focus and Enter is pressed', hooks => {
    hooks.beforeEach(() => {
      props.onSelect = sinon.spy()
    })

    async function openAndSelect(optionLabel) {
      await mountComponent()
      await clickInputToOpenMenu()
      arrowDownTo(optionLabel)
      await keyDownOnOption(optionLabel, keyCodes.ENTER)
    }

    test('dismisses the options list', async () => {
      await openAndSelect(labelForGrader('robin'))
      const style = window.getComputedStyle(getOptionList())
      equal(style.display, 'none')
    })

    test('calls the onSelect prop when the input has changed', async () => {
      await openAndSelect(labelForGrader('robin'))
      strictEqual(props.onSelect.callCount, 1)
    })

    test('includes the focused grade info when calling onSelect', async () => {
      await openAndSelect(labelForGrader('robin'))
      const [gradeInfo] = props.onSelect.lastCall.args
      strictEqual(gradeInfo, props.grades.robin)
    })

    test('does not call the onSelect prop when the input has not changed', async () => {
      props.grades.robin.selected = true
      await openAndSelect(labelForGrader('robin'))
      strictEqual(props.onSelect.callCount, 0)
    })

    test('does not call the onSelect prop when the "no selection" option is selected', async () => {
      await openAndSelect('–')
      strictEqual(props.onSelect.callCount, 0)
    })
  })

  QUnit.module('when the component instance is reused for another student', hooks => {
    /*
     * The purpose of this context is to help ensure that component instance
     * reuse does not result in state-based bugs. When updating input components
     * like Select, updating internal state can easily lead to mismatches
     * between old state and new props.
     */

    hooks.beforeEach(async () => {
      await mountComponent()
      props = JSON.parse(JSON.stringify(props))
      props.studentName = 'Betty Ford'
      props.grades.frizz.studentId = '1112'
      props.grades.robin.studentId = '1112'
    })

    test('includes an option for "no selection" when the student has no selected grade', () => {
      wrapper.setProps(props)
      ok(getOptionLabels().includes('–'))
    })

    test('excludes the option for "no selection" when the student has a selected grade', () => {
      props.grades.robin.selected = true
      wrapper.setProps(props)
      notOk(getOptionLabels().includes('–'))
    })
  })
})
