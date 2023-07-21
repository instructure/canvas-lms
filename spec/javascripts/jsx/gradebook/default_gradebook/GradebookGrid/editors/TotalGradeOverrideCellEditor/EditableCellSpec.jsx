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

import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import EditableCell from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/TotalGradeOverrideCellEditor/EditableCell'

QUnit.module('GradebookGrid TotalGradeOverrideCellEditor EditableCell', suiteHooks => {
  let $container
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    const gradeEntry = new GradeOverrideEntry()

    props = {
      gradeEntry,
      gradeInfo: gradeEntry.parseValue('91%'),
      gradeIsUpdating: false,
      onGradeUpdate: sinon.stub(),
      pendingGradeInfo: null,
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  function mountComponent() {
    wrapper = mount(<EditableCell {...props} />, {attachTo: $container})
  }

  function getInstance() {
    return wrapper.instance()
  }

  function getTextInput() {
    return $container.querySelector('input[type="text"]')
  }

  function getInvalidGradeIndicator() {
    return $container.querySelector('.Grid__GradeCell__InvalidGrade button')
  }

  function setTextInputValue(value) {
    wrapper.find('input[type="text"]').simulate('change', {target: {value}})
  }

  function simulateKeyDown(keyCode, shiftKey = false) {
    const event = new Event('keydown')
    event.which = keyCode
    event.shiftKey = shiftKey
    return getInstance().handleKeyDown(event)
  }

  function updateProps(nextProps) {
    wrapper.setProps(nextProps)
  }

  QUnit.module('#render()', () => {
    test('renders a text input', () => {
      mountComponent()
      ok(getTextInput())
    })

    test('sets focus on the grade input', () => {
      mountComponent()
      strictEqual(document.activeElement, getTextInput())
    })

    test('disables the input when the grade is updating', () => {
      props.gradeIsUpdating = true
      mountComponent()
      strictEqual(getTextInput().disabled, true)
    })

    test('does not disable the input when the grade is not updating', () => {
      mountComponent()
      strictEqual(getTextInput().disabled, false)
    })

    test('displays the given grade info in the input', () => {
      mountComponent()
      equal(getTextInput().value, '91%')
    })

    test('displays the given pending grade info in the input', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
      mountComponent()
      equal(getTextInput().value, '92%')
    })

    test('displays the invalid grade indicator when the pending grade info is invalid', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('invalid')
      mountComponent()
      ok(getInvalidGradeIndicator())
    })

    test('does not display the invalid grade indicator when the pending grade info is valid', () => {
      props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
      mountComponent()
      notOk(getInvalidGradeIndicator())
    })
  })

  QUnit.module('#applyValue()', () => {
    test('calls the .onGradeUpdate prop', () => {
      mountComponent()
      getInstance().applyValue()
      strictEqual(props.onGradeUpdate.callCount, 1)
    })

    test('includes the current grade info when calling the .onGradeUpdate prop', () => {
      mountComponent()
      setTextInputValue('93%')
      getInstance().applyValue()
      const [gradeInfo] = props.onGradeUpdate.lastCall.args
      const expected = props.gradeEntry.parseValue('93%')
      deepEqual(gradeInfo, expected)
    })
  })

  QUnit.module('#focus()', () => {
    test('sets focus on the grade input', () => {
      mountComponent()
      document.body.focus()
      getInstance().focus()
      strictEqual(document.activeElement, getTextInput())
    })
  })

  QUnit.module('#handleKeyDown()', () => {
    QUnit.module('when the grade is valid', contextHooks => {
      contextHooks.beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('92%')
        mountComponent()
      })

      test('does not skip SlickGrid default behavior when tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, false) // tab to next cell
        equal(typeof continueHandling, 'undefined')
      })

      test('does not skip SlickGrid default behavior when shift-tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to previous cell
        equal(typeof continueHandling, 'undefined')
      })

      // TODO: GRADE-1926 Ensure SlickGrid behavior is skipped when using the
      // Grading Scheme Input
      QUnit.skip('skips SlickGrid default behavior when the grade input handles the event')
    })

    QUnit.module('when the grade is invalid', contextHooks => {
      contextHooks.beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('invalid')
        mountComponent()
      })

      test('skips SlickGrid default behavior when tabbing from the invalid grade indicator', () => {
        getInvalidGradeIndicator().focus()
        const continueHandling = simulateKeyDown(9, false) // tab to grade input
        strictEqual(continueHandling, false)
      })

      test('does not skip SlickGrid default behavior when tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, false) // tab to next cell
        equal(typeof continueHandling, 'undefined')
      })

      test('does not skip SlickGrid default behavior when shift-tabbing from the invalid grade indicator', () => {
        getInvalidGradeIndicator().focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to previous cell
        equal(typeof continueHandling, 'undefined')
      })

      test('skips SlickGrid default behavior when shift-tabbing from the grade input', () => {
        getTextInput().focus()
        const continueHandling = simulateKeyDown(9, true) // shift+tab back to invalid grade indicator
        strictEqual(continueHandling, false)
      })
    })
  })

  QUnit.module('#isValueChanged()', () => {
    test('returns false when the grade input value has not changed', () => {
      mountComponent()
      strictEqual(getInstance().isValueChanged(), false)
    })

    test('returns true when the grade input value has changed', () => {
      mountComponent()
      setTextInputValue('93%')
      strictEqual(getInstance().isValueChanged(), true)
    })
  })

  QUnit.module('when re-rendering', () => {
    test('sets focus on the grade input when the grade finishes updating', () => {
      props.gradeIsUpdating = true
      mountComponent()
      updateProps({gradeIsUpdating: false})
      strictEqual(document.activeElement, getTextInput())
    })

    test('does not set focus on the grade input when the grade has not finished updating', () => {
      props.gradeIsUpdating = true
      mountComponent()
      updateProps({gradeIsUpdating: true})
      notEqual(document.activeElement, getTextInput())
    })
  })
})
