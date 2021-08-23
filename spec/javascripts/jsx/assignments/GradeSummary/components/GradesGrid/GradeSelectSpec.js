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

import GradeSelect, { NO_SELECTION_LABEL } from 'ui/features/assignment_grade_summary/react/components/GradesGrid/GradeSelect.js'
import {FAILURE, STARTED, SUCCESS} from 'ui/features/assignment_grade_summary/react/grades/GradeActions.js'

import {waitFor} from '../../../../support/Waiters'

function Container(props) {
  /*
   * This class exists because Enzyme does not update props of children, which
   * is necessary to test the full behavior of this component.
   */

  return (
    <div>
      <GradeSelect {...props} />
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
  let selectedGrade
  let wrapper

  suiteHooks.beforeEach(() => {
    $container = document.createElement('div')
    document.body.appendChild($container)

    selectedGrade = null

    props = {
      disabledCustomGrade: false,
      finalGrader: {
        graderId: 'teach',
        id: '1105'
      },
      graders: [
        {graderId: 'frizz', graderName: 'Miss Frizzle', graderSelectable: true},
        {graderId: 'robin', graderName: 'Mr. Keating', graderSelectable: true},
        {graderId: 'ednak', graderName: 'Mrs. Krabappel', graderSelectable: true},
        {graderId: 'feeny', graderName: 'Mr. Feeny', graderSelectable: true}
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
      onSelect: sinon.stub().callsFake(gradeInfo => {
        selectedGrade = gradeInfo
      }),
      selectProvisionalGradeStatus: null,
      studentId: '1111',
      studentName: 'Adam Jones'
    }
  })

  suiteHooks.afterEach(async () => {
    if (getOptionList()) {
      await clickOff()
    }
    wrapper.unmount()
  })

  function mountComponent() {
    wrapper = mount(<Container {...props} />, {attachTo: $container})
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
    return wrapper
      .find('input')
      .at(0)
      .instance()
  }

  function clickInputToOpenMenu() {
    const $input = getTextInput()
    focusElement($input)
    $input.click()
    return waitFor(getOptionList)
  }

  function keyDownOnInput(keyCode) {
    wrapper.find('input').simulate('keyDown', {keyCode})
  }

  function keyUpOnInput(keyCode) {
    wrapper.find('input').simulate('keyUp', {keyCode})
  }

  function getOptionList() {
    const controlledContentId = getTextInput().getAttribute('aria-controls')
    return controlledContentId ? document.getElementById(controlledContentId) : null
  }

  function getOptions() {
    const $list = getOptionList()
    const $items = $list.querySelectorAll('span[role="option"]')
    return Array.from($items)
  }

  function getOptionLabels() {
    return getOptions().map($option => $option.textContent.trim())
  }

  function getOption(optionLabel) {
    return getOptions().find($el => $el.textContent.trim() === optionLabel)
  }

  function clickOption(optionLabel) {
    getOption(optionLabel).click()
    return menuClosed()
  }

  function arrowDownTo(optionLabel) {
    const options = getOptions()
    const indexOfHighlightedOption = options.findIndex(
      $option => $option.getAttribute('aria-selected') === 'true'
    )
    const indexOfTargetOption = getOptionLabels().indexOf(optionLabel)

    for (let i = indexOfHighlightedOption; i < indexOfTargetOption; i++) {
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

  function clickOff() {
    blurElement(getTextInput())
    return menuClosed()
  }

  function setInputText(value) {
    const input = wrapper.find('input[type="text"]')
    input.at(0).instance().value = value
    input.simulate('change', {target: {value}})
  }

  function labelForGrader(graderId) {
    const gradeInfo = props.grades[graderId]
    const grader = props.graders.find(g => g.graderId === graderId)
    return `${gradeInfo.score} (${grader.graderName})`
  }

  function customLabel(score) {
    return `${score} (Custom)`
  }

  function mountAndClick() {
    mountComponent()
    return clickInputToOpenMenu()
  }

  function menuClosed() {
    if (getOptionList()) {
      return waitFor(() => !getOptionList())
    }
    else {
      return Promise.resolve()
    }
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

  QUnit.module('when a grade has been selected', hooks => {
    hooks.beforeEach(() => {
      props.grades.robin.selected = true
    })

    test('excludes an option for "no selection"', async () => {
      await mountAndClick()
      notOk(getOptionLabels().includes('–'))
    })

    test('does not include an option for graders who did not grade', async () => {
      await mountAndClick()
      const labels = getOptionLabels().filter(label => label.match(/Krabappel/))
      strictEqual(labels.length, 0)
    })

    test('includes an option for each grader who graded', async () => {
      await mountAndClick()
      deepEqual(getOptionLabels(), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('sets as the input value the selected provisional grade', () => {
      mountComponent()
      equal(getTextInput().value, labelForGrader('robin'))
    })
  })

  QUnit.module('when the input is dismissed by clicking elsewhere', () => {
    function clickOffAndWaitForValue(value) {
      return clickOff().then(() => waitFor(() => getTextInput().value === value))
    }
    test('does not call the onSelect prop', async () => {
      await mountAndClick()
      await clickOff()
      strictEqual(props.onSelect.callCount, 0)
    })

    test('does not call the onSelect prop when input was changed', async () => {
      await mountAndClick()
      setInputText('7.9')
      await clickOff()
      strictEqual(props.onSelect.callCount, 0)
    })

    test('does not call the onSelect prop when input was cleared', async () => {
      await mountAndClick()
      setInputText('')
      await clickOff()
      strictEqual(props.onSelect.callCount, 0)
    })

    test('resets the input to the selected option', async () => {
      props.grades.robin.selected = true
      await mountAndClick()
      setInputText('')
      await clickOffAndWaitForValue(labelForGrader('robin'))
      equal(getTextInput().value, labelForGrader('robin'))
    })

    test('resets the input to the selected custom option', async () => {
      props.grades.teach = {
        grade: 'A++',
        graderId: 'teach',
        id: '4604',
        score: 11,
        selected: true,
        studentId: '1111'
      }
      await mountAndClick()
      setInputText('')
      await clickOffAndWaitForValue(customLabel('11'))
      equal(getTextInput().value, customLabel('11'))
    })

    test('resets the input to the "no selection" option when no grade is selected', async () => {
      await mountAndClick()
      setInputText('')
      await clickOffAndWaitForValue('–')
      equal(getTextInput().value, '–')
    })

    test('resets the input to the "no selection" option when some text has been entered', async () => {
      await mountAndClick()
      setInputText('5')
      await clickOff()
      equal(getTextInput().value, NO_SELECTION_LABEL)
    })

    QUnit.skip('restores the full list of options for subsequent selection', async () => {
      await mountAndClick()
      setInputText('7.9')
      await clickOffAndWaitForValue('')
      await clickInputToOpenMenu()
      deepEqual(getOptionLabels(), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })
  })

  QUnit.module('when no grade has been selected', () => {
    test('includes an option for "no selection"', async () => {
      await mountAndClick()
      strictEqual(getOptionLabels()[0], '–')
    })

    test('displays the grade and grader name as option labels', async () => {
      await mountAndClick()
      deepEqual(getOptionLabels().slice(1), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('set the input value to "–" (en dash)', () => {
      mountComponent()
      strictEqual(getTextInput().value, '–')
    })
  })

  QUnit.module('when selecting an existing grade', () => {
    function openAndSelect(optionLabel) {
      return mountAndClick().then(() => clickOption(optionLabel))
    }

    test('calls the onSelect prop', async () => {
      await openAndSelect(labelForGrader('frizz'))
      strictEqual(props.onSelect.callCount, 1)
    })

    test('includes the related grade info when calling onSelect', async () => {
      await openAndSelect(labelForGrader('frizz'))
      deepEqual(selectedGrade, props.grades.frizz)
    })

    test('does not call the onSelect prop when the option for the selected grade is clicked', async () => {
      props.grades.robin.selected = true
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

    test('updates the custom grade option when a custom grade is entered', async () => {
      await mountAndClick()
      setInputText('5')
      ok(getOptionLabels().includes(customLabel('5')))
    })

    test('does not include multiple custom grades', async () => {
      await mountAndClick()
      setInputText('5')
      notOk(getOptionLabels().includes(customLabel('11')))
    })

    QUnit.module('when clicking the custom grade option', () => {
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

      test('calls the onSelect prop when entered text has changed the selected custom grade', async () => {
        props.grades.teach.selected = true
        await mountAndClick()
        setInputText('5')
        await clickOption(customLabel('5'))
        strictEqual(props.onSelect.callCount, 1)
      })

      test('updates the custom grade info with the changed score when calling the onSelect prop', async () => {
        props.grades.teach.selected = true
        await mountAndClick()
        setInputText('5')
        await clickOption(customLabel('5'))
        const [gradeInfo] = props.onSelect.lastCall.args
        deepEqual(gradeInfo, {...props.grades.teach, score: 5})
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

    test('allows selecting other grades', async () => {
      await mountAndClick()
      await clickOption(labelForGrader('robin'))
      deepEqual(selectedGrade, props.grades.robin)
    })
  })

  QUnit.module('when a grade selection is pending', hooks => {
    hooks.beforeEach(() => {
      props.selectProvisionalGradeStatus = STARTED
      mountComponent()
    })

    test('sets the input to read-only while grade selection is pending', () => {
      const input = wrapper.find('input[type="text"]')
      strictEqual(input.prop('aria-readonly'), true)
    })

    test('enables the input when grade selection was successful', () => {
      wrapper.setProps({selectProvisionalGradeStatus: SUCCESS})
      strictEqual(wrapper.find('SimpleSelect').prop('editable'), true)
    })

    test('enables the input when grade selection has failed', () => {
      wrapper.setProps({selectProvisionalGradeStatus: FAILURE})
      strictEqual(wrapper.find('SimpleSelect').prop('editable'), true)
    })
  })

  QUnit.module('when not given an onSelect prop (grades have been published)', hooks => {
    hooks.beforeEach(() => {
      props.grades.frizz.selected = true
      props.onSelect = null
      mountComponent()
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

  QUnit.module('when custom grades cannot be edited', hooks => {
    /*
     * This is temporary until users beyond provisional graders and the final
     * grader are allowed to grade. Doing this will prevent as-yet-unexplored
     * scenarios from causing as-yet-unconsidered problems.
     */
    hooks.beforeEach(() => {
      props.disabledCustomGrade = true
      return mountAndClick()
    })

    test('prevents adding custom options to the options list', () => {
      setInputText('5')
      notOk(getOptionLabels().includes(customLabel('5')))
    })

    test('prevents entering text for custom options', async () => {
      setInputText('5')
      await keyDownOnInput(keyCodes.ENTER)
      strictEqual(props.onSelect.callCount, 0)
    })

    test('does not prevent selecting existing grades', async () => {
      await clickOption(labelForGrader('robin'))
      strictEqual(props.onSelect.callCount, 1)
    })
  })

  QUnit.module('when entered text partially matches other grades', hooks => {
    hooks.beforeEach(() => {
      return mountAndClick().then(() => {
        setInputText('8')
      })
    })

    test('excludes the "no selection" option', () => {
      notOk(getOptionLabels().includes('–'))
    })

    test('excludes options not matching the entered text', () => {
      notOk(getOptionLabels().includes(labelForGrader('frizz')))
    })

    test('includes options partially matching the entered text', () => {
      ok(getOptionLabels().includes(labelForGrader('robin')))
    })

    test('adds a custom grade option', () => {
      ok(getOptionLabels().includes(customLabel('8')))
    })

    test('places the custom grade last in the options list', () => {
      deepEqual(getOptionLabels(), [labelForGrader('robin'), '8 (Custom)'])
    })

    test('ignores surrounding whitespace when exactly matching grades', () => {
      setInputText('  8  ')
      deepEqual(getOptionLabels(), [labelForGrader('robin'), '8 (Custom)'])
    })
  })

  QUnit.module('when entered text exactly matches other grades', hooks => {
    hooks.beforeEach(() => {
      props.grades.frizz.score = 7.9
      props.grades.feeny.score = 7
      return mountAndClick().then(() => {
        setInputText('7')
      })
    })

    test('excludes the "no selection" option', () => {
      notOk(getOptionLabels().includes('–'))
    })

    test('excludes options not matching the entered text', () => {
      notOk(getOptionLabels().includes(labelForGrader('robin')))
    })

    test('includes options exactly matching the entered text', () => {
      ok(getOptionLabels().includes(labelForGrader('feeny')))
    })

    test('includes options partially matching the entered text', () => {
      ok(getOptionLabels().includes(labelForGrader('frizz')))
    })

    test('orders exact matches before partial matches', () => {
      deepEqual(getOptionLabels().slice(0, 2), [labelForGrader('feeny'), labelForGrader('frizz')])
    })

    test('adds a custom grade option', () => {
      ok(getOptionLabels().includes(customLabel('7')))
    })

    test('places the custom grade last in the options list', () => {
      const labels = getOptionLabels()
      equal(labels[labels.length - 1], customLabel('7'))
    })

    test('ignores surrounding whitespace when partially matching grades', () => {
      setInputText('  7  ')
      deepEqual(getOptionLabels(), [
        labelForGrader('feeny'),
        labelForGrader('frizz'),
        customLabel('7')
      ])
    })
  })

  QUnit.module('when entered text partially matches grader names', hooks => {
    hooks.beforeEach(mountAndClick)

    test('includes grades from graders whose names partially match the entered text', () => {
      setInputText('z')
      ok(getOptionLabels().includes(labelForGrader('frizz')))
    })

    test('excludes grades from graders whose names do not match the entered text', () => {
      setInputText('mr')
      notOk(getOptionLabels().includes(labelForGrader('frizz')))
    })

    test('includes only options for the matching grader names', () => {
      // Non-numerical values are not valid scores.
      setInputText('f')
      deepEqual(getOptionLabels(), [labelForGrader('frizz'), labelForGrader('feeny')])
    })

    test('ignores surrounding whitespace when partially matching grader names', () => {
      setInputText('   f   ')
      deepEqual(getOptionLabels(), [labelForGrader('frizz'), labelForGrader('feeny')])
    })
  })

  QUnit.module('when entered text does not match grades or grader names', () => {
    test('includes only the custom grade when the text is a valid score', async () => {
      await mountAndClick()
      setInputText('3')
      deepEqual(getOptionLabels(), [customLabel('3')])
    })

    test('filters out all options when the text is not a valid score', async () => {
      await mountAndClick()
      setInputText('oops')
      deepEqual(getOptionLabels(), ['---'])
    })

    test('includes the custom grade when the entered text matches the custom grade label', async () => {
      props.grades.teach = {
        grade: 'A++',
        graderId: 'teach',
        id: '4604',
        score: 11,
        selected: true,
        studentId: '1111'
      }
      await mountAndClick()
      setInputText('custom')
      deepEqual(getOptionLabels(), [customLabel('11')])
    })
  })

  QUnit.module('when entered text is updated', hooks => {
    hooks.beforeEach(() => {
      return mountAndClick().then(() => {
        setInputText('8')
      })
    })

    test('adds options matching the updated text', () => {
      setInputText('7')
      ok(getOptionLabels().includes(labelForGrader('feeny')))
    })

    test('removes options not matching the updated text', () => {
      setInputText('7')
      notOk(getOptionLabels().includes(labelForGrader('robin')))
    })

    test('continues filtering as text is changed', () => {
      setInputText('8.6 (Mr. Keating)')
      setInputText('8.6 (Mr. Keating')
      setInputText('8.6 (Mr. Keatin')
      ok(getOptionLabels().includes(labelForGrader('robin')))
    })
  })

  QUnit.module('when the input has focus and Escape is pressed', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
      return clickInputToOpenMenu()
    })

    test('dismisses the options list', () => {
      keyUpOnInput(keyCodes.ESCAPE)
      strictEqual(getOptionList(), null)
    })

    test('does not call the onSelect prop', () => {
      keyUpOnInput(keyCodes.ESCAPE)
      strictEqual(props.onSelect.callCount, 0)
    })

    test('sets focus on the input', () => {
      keyUpOnInput(keyCodes.ESCAPE)
      strictEqual(document.activeElement, getTextInput())
    })

    test('resets the input value when text was entered', () => {
      setInputText('7.9')
      keyUpOnInput(keyCodes.ESCAPE)
      equal(getTextInput().value, '')
    })
  })

  QUnit.skip('FOO-620: this works in the browser but no longer in test once we started using SimpleSelect', () => {
    QUnit.module('when an option has focus and Escape is pressed', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        return clickInputToOpenMenu()
      })

      test('dismisses the options list', () => {
        focusOption(labelForGrader('robin'))
        keyUpOnOption(labelForGrader('robin'), keyCodes.ESCAPE)
        strictEqual(getOptionList(), null)
      })

      test('does not call the onSelect prop', () => {
        focusOption(labelForGrader('robin'))
        keyUpOnOption(labelForGrader('robin'), keyCodes.ESCAPE)
        strictEqual(props.onSelect.callCount, 0)
      })

      test('sets focus on the input', () => {
        focusOption(labelForGrader('robin'))
        keyUpOnOption(labelForGrader('robin'), keyCodes.ESCAPE)
        strictEqual(document.activeElement, getTextInput())
      })
    })
  })

  QUnit.module('when the input has focus and Enter is pressed', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
      return clickInputToOpenMenu()
    })

    test('dismisses the options list', async () => {
      await keyDownOnInput(keyCodes.ENTER)
      strictEqual(getOptionList(), null)
    })

    test('calls the onSelect prop when the input has changed', async () => {
      setInputText('8')
      await keyDownOnInput(40) // arrow down
      await keyDownOnInput(keyCodes.ENTER)
      strictEqual(props.onSelect.callCount, 1)
    })

    test('includes the entered grade info when calling onSelect', async () => {
      setInputText('8')
      await keyDownOnInput(40) // arrow down
      await keyDownOnInput(keyCodes.ENTER)
      const [gradeInfo] = props.onSelect.lastCall.args
      strictEqual(gradeInfo, props.grades.robin)
    })

    test('trims surrounding whitespace from the entered grade', async () => {
      setInputText('  8  ')
      await keyDownOnInput(40) // arrow down
      await keyDownOnInput(keyCodes.ENTER)
      const [gradeInfo] = props.onSelect.lastCall.args
      strictEqual(gradeInfo, props.grades.robin)
    })

    test('trims surrounding whitespace from a custom grade', async () => {
      setInputText('  5  ')
      await keyDownOnInput(40) // arrow down
      await keyDownOnInput(keyCodes.ENTER)
      const [gradeInfo] = props.onSelect.lastCall.args
      strictEqual(gradeInfo.score, 5)
    })

    test('does not call the onSelect prop when the input has not changed', async () => {
      await keyDownOnInput(keyCodes.ENTER)
      strictEqual(props.onSelect.callCount, 0)
    })
  })

  QUnit.skip('FOO-620: choosing a custom option with RETURN works with SimpleSelect in the browser but tests need to be modified', () => {
    QUnit.module('when an option has focus and Enter is pressed', () => {
      function openAndSelect(optionLabel) {
        mountComponent()
        return clickInputToOpenMenu().then(() => {
          arrowDownTo(optionLabel)
          return keyDownOnOption(optionLabel, keyCodes.ENTER)
        })
      }

      test('dismisses the options list', async () => {
        await openAndSelect(labelForGrader('robin'))
        strictEqual(getOptionList(), null)
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
  })

  QUnit.module('when a grader is not selectable', () => {
    function openAndGetOption(optionLabel) {
      mountComponent()
      return clickInputToOpenMenu().then(() => {
        return getOption(optionLabel)
      })
    }

    test('does disable the option', async () => {
      props.graders[3].graderSelectable = false
      const option = await openAndGetOption(labelForGrader('feeny'))
      strictEqual(option.getAttribute('aria-disabled'), 'true')
    })
  })

  QUnit.module('when selecting a new custom grade', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
      return clickInputToOpenMenu().then(() => {
        setInputText('5')
        return clickOption(customLabel('5'))
      })
    })

    test('calls the onSelect prop', () => {
      strictEqual(props.onSelect.callCount, 1)
    })

    test('includes the entered score when calling onSelect', () => {
      const [gradeInfo] = props.onSelect.lastCall.args
      strictEqual(gradeInfo.score, 5)
    })

    test('includes the student id when calling onSelect', () => {
      const [gradeInfo] = props.onSelect.lastCall.args
      strictEqual(gradeInfo.studentId, '1111')
    })

    test('restores the full list of options for subsequent selection', async () => {
      await clickInputToOpenMenu()
      const graderOptionLabels = ['frizz', 'robin', 'feeny'].map(labelForGrader)
      deepEqual(getOptionLabels(), [...graderOptionLabels, customLabel('5')])
      await clickOff()
    })
  })

  QUnit.module('when updating from having no grades to having grades', hooks => {
    hooks.beforeEach(() => {
      const {grades} = props
      props.grades = {}
      return mountAndClick().then(() => {
        props.grades = grades
      })
    })

    test('includes only grader options when one of the grades is selected', () => {
      props.grades.frizz.selected = true
      wrapper.setProps({grades: props.grades})
      deepEqual(getOptionLabels(), ['frizz', 'robin', 'feeny'].map(labelForGrader))
    })

    test('includes an option for "no selection" when no grade is selected', () => {
      wrapper.setProps({grades: props.grades})
      strictEqual(getOptionLabels()[0], '–')
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
      return mountAndClick().then(() => {
        props = JSON.parse(JSON.stringify(props))
        props.studentName = 'Betty Ford'
        props.grades.frizz.studentId = '1112'
        props.grades.robin.studentId = '1112'
      })
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
