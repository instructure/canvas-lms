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

import GradeInput from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/GradeInput/GradeInput'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid GradeInput', suiteHooks => {
  let $container
  let instance
  let props
  let wrapper

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    const gradeEntry = new GradeOverrideEntry({
      gradingScheme: {
        data: [
          ['A', 0.9],
          ['B', 0.8],
          ['C', 0.7],
          ['D', 0.6],
          ['F', 0],
        ],
      },
    })

    props = {
      disabled: false,
      gradeEntry,
      gradeInfo: gradeEntry.gradeInfoFromGrade(null),
      pendingGradeInfo: null,
    }
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
  })

  function mountComponent() {
    wrapper = mount(<GradeInput {...props} />, {attachTo: $container})
    instance = wrapper.instance()
  }

  function updateProps(nextProps) {
    wrapper.setProps(nextProps)
  }

  function getTextInput() {
    return $container.querySelector('input[type="text"]')
  }

  function getTextInputValue() {
    return getTextInput().value
  }

  function setTextInputValue(value) {
    wrapper.find('input[type="text"]').simulate('change', {target: {value}})
  }

  QUnit.module('when using a grading scheme', () => {
    test('adds the PercentInput suffix class to the container', () => {
      // TODO: GRADE-1926, Use GradingSchemeInput suffix instead
      mountComponent()
      const {classList} = $container.firstChild
      strictEqual(classList.contains('Grid__GradeCell__PercentInput'), true)
    })

    test('renders a text input', () => {
      mountComponent()
      ok(getTextInput())
    })

    test('optionally disables the input', () => {
      props.disabled = true
      mountComponent()
      strictEqual(getTextInput().disabled, true)
    })
  })

  QUnit.module('when not using a grading scheme', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
    })

    test('adds the PercentInput suffix class to the container', () => {
      mountComponent()
      const {classList} = $container.firstChild
      strictEqual(classList.contains('Grid__GradeCell__PercentInput'), true)
    })

    test('renders a text input', () => {
      mountComponent()
      ok(getTextInput())
    })

    test('optionally disables the input', () => {
      props.disabled = true
      mountComponent()
      strictEqual(getTextInput().disabled, true)
    })
  })

  QUnit.module('when no grade is assigned', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradeInfo = props.gradeEntry.gradeInfoFromGrade(null)
      mountComponent()
    })

    test('keeps the input blank', () => {
      strictEqual(getTextInputValue(), '')
    })

    test('#gradeInfo is set to a null grade', () => {
      const grade = props.gradeEntry.parseValue('')
      deepEqual(instance.gradeInfo, grade)
    })

    test('#hasGradeChanged() returns false when the input value has not changed', () => {
      strictEqual(instance.hasGradeChanged(), false)
    })

    test('#hasGradeChanged() returns true when the input value has changed', () => {
      setTextInputValue('A')
      strictEqual(instance.hasGradeChanged(), true)
    })
  })

  QUnit.module('when a grade is assigned', () => {
    QUnit.module('when using a grading scheme', contextHooks => {
      contextHooks.beforeEach(() => {
        props.gradeInfo = props.gradeEntry.parseValue('91.1%')
        mountComponent()
      })

      test('sets the input value with the scheme grade', () => {
        strictEqual(getTextInputValue(), 'A')
      })

      test('#gradeInfo is set to equivalent grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1%')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the assigned scheme grade', () => {
        setTextInputValue(' A ')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns false when the input value matches as a percentage', () => {
        setTextInputValue('91.1')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input value differs from the assigned grade', () => {
        setTextInputValue('B')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })

    QUnit.module('when not using a grading scheme', contextHooks => {
      contextHooks.beforeEach(() => {
        props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
        props.gradeInfo = props.gradeEntry.parseValue('91.1%')
      })

      test('sets the input value with the percentage grade', () => {
        mountComponent()
        strictEqual(getTextInputValue(), '91.1%')
      })

      test('rounds the input value to two decimal places', () => {
        props.gradeInfo = props.gradeEntry.parseValue('91.1234%')
        mountComponent()
        strictEqual(getTextInputValue(), '91.12%')
      })

      test('strips insignificant zeros', () => {
        props.gradeInfo = props.gradeEntry.parseValue('91.0000%')
        mountComponent()
        strictEqual(getTextInputValue(), '91%')
      })

      test('#gradeInfo is set to equivalent grade info', () => {
        mountComponent()
        const gradeInfo = props.gradeEntry.parseValue('91.1%')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the assigned grade', () => {
        mountComponent()
        setTextInputValue(' 91.1 ')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input value differs from the assigned grade', () => {
        mountComponent()
        setTextInputValue('91.2')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })
  })

  QUnit.module('when no grade is assigned and a valid grade is pending', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradeInfo = props.gradeEntry.gradeInfoFromGrade(null)
    })

    QUnit.module('when using a grading scheme', hooks => {
      hooks.beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
        mountComponent()
      })

      test('sets the input value with the scheme grade', () => {
        strictEqual(getTextInputValue(), 'A')
      })

      test('#gradeInfo is set to the pending grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending scheme grade', () => {
        setTextInputValue(' A ')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns false when the input value matches as a percentage', () => {
        setTextInputValue('91.1')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        setTextInputValue('B')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })

    QUnit.module('when not using a grading scheme', hooks => {
      hooks.beforeEach(() => {
        props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
      })

      test('sets the input value with the percentage grade', () => {
        mountComponent()
        strictEqual(getTextInputValue(), '91.1%')
      })

      test('#gradeInfo is set to the pending grade info', () => {
        mountComponent()
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending grade', () => {
        mountComponent()
        setTextInputValue(' 91.1 ')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        mountComponent()
        setTextInputValue('91.2')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })
  })

  QUnit.module('when a grade is assigned and an updated, valid grade is pending', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradeInfo = props.gradeEntry.parseValue('89.9')
    })

    QUnit.module('when using a grading scheme', hooks => {
      hooks.beforeEach(() => {
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
        mountComponent()
      })

      test('sets the input value with the scheme grade of the pending grade', () => {
        strictEqual(getTextInputValue(), 'A')
      })

      test('#gradeInfo is set to pending grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending scheme grade', () => {
        setTextInputValue(' A ')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns false when the input value matches as a percentage', () => {
        setTextInputValue('91.1')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        setTextInputValue('C')
        strictEqual(instance.hasGradeChanged(), true)
      })

      test('#hasGradeChanged() returns true when the input value matches the assigned grade', () => {
        setTextInputValue('B')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })

    QUnit.module('when not using a grading scheme', hooks => {
      hooks.beforeEach(() => {
        props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
        props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
        mountComponent()
      })

      test('sets the input value with the percentage grade', () => {
        strictEqual(getTextInputValue(), '91.1%')
      })

      test('#gradeInfo is set to the pending grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('91.1')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false when the input value matches the pending grade', () => {
        setTextInputValue(' 91.1 ')
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input value differs from the pending grade', () => {
        setTextInputValue('91.2')
        strictEqual(instance.hasGradeChanged(), true)
      })

      test('#hasGradeChanged() returns true when the input value matches the assigned grade', () => {
        setTextInputValue('89.9')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })

    QUnit.module('when the pending grade cleared the assigned grade', hooks => {
      hooks.beforeEach(() => {
        props.gradeInfo = props.gradeEntry.parseValue('A')
        props.pendingGradeInfo = props.gradeEntry.parseValue('')
        mountComponent()
      })

      test('keeps the input blank', () => {
        strictEqual(getTextInputValue(), '')
      })

      test('#gradeInfo is set to the pending blank grade info', () => {
        const gradeInfo = props.gradeEntry.parseValue('')
        deepEqual(instance.gradeInfo, gradeInfo)
      })

      test('#hasGradeChanged() returns false while the input remains blank', () => {
        strictEqual(instance.hasGradeChanged(), false)
      })

      test('#hasGradeChanged() returns true when the input is not blank', () => {
        setTextInputValue('A')
        strictEqual(instance.hasGradeChanged(), true)
      })
    })
  })

  QUnit.module('when a new grade changes from pending to applied', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradeInfo = props.gradeEntry.gradeInfoFromGrade(null)
      props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
      mountComponent()
    })

    function updateGrade() {
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      updateProps({gradeInfo, pendingGradeInfo: null})
    }

    test('sets the input value with the updated grade', () => {
      updateGrade()
      strictEqual(getTextInputValue(), 'A')
    })

    test('#gradeInfo is set to the updated grade info', () => {
      updateGrade()
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      deepEqual(instance.gradeInfo, gradeInfo)
    })

    test('does not update the input value when the input has focus', () => {
      getTextInput().focus()
      setTextInputValue('91.2%')
      updateGrade()
      strictEqual(getTextInputValue(), '91.2%')
    })
  })

  QUnit.module('when an updated grade changes from pending to applied', contextHooks => {
    contextHooks.beforeEach(() => {
      props.gradeInfo = props.gradeEntry.parseValue('89.9')
      props.pendingGradeInfo = props.gradeEntry.parseValue('91.1')
      mountComponent()
    })

    function updateGrade() {
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      updateProps({gradeInfo, pendingGradeInfo: null})
    }

    test('sets the input value with the updated grade', () => {
      updateGrade()
      strictEqual(getTextInputValue(), 'A')
    })

    test('#gradeInfo is set to the updated grade info', () => {
      updateGrade()
      const gradeInfo = props.gradeEntry.parseValue('91.1')
      deepEqual(instance.gradeInfo, gradeInfo)
    })

    test('does not update the input value when the input has focus', () => {
      getTextInput().focus()
      setTextInputValue('91.2%')
      updateGrade()
      strictEqual(getTextInputValue(), '91.2%')
    })
  })

  QUnit.module('#gradeInfo', () => {
    test('is set to the parsed grade from the given GradeEntry', () => {
      mountComponent()
      setTextInputValue('91.1')
      deepEqual(instance.gradeInfo, props.gradeEntry.parseValue('91.1'))
    })

    test('trims whitespace from the input value', () => {
      mountComponent()
      setTextInputValue('  90.0  ')
      deepEqual(instance.gradeInfo, props.gradeEntry.parseValue('90.0'))
    })

    test('sets .grade to null when the input was cleared', () => {
      mountComponent()
      setTextInputValue('90.0')
      setTextInputValue('')
      strictEqual(instance.gradeInfo.grade, null)
    })
  })

  QUnit.module('#focus()', () => {
    test('sets focus on the input', () => {
      mountComponent()
      wrapper.instance().focus()
      strictEqual(document.activeElement, getTextInput())
    })

    test('selects the content of the input', () => {
      props.gradeEntry = new GradeOverrideEntry({gradingScheme: null})
      props.gradeInfo = props.gradeEntry.parseValue('78.9')
      mountComponent()
      wrapper.instance().focus()
      strictEqual(document.getSelection().toString(), '78.9%')
    })
  })

  QUnit.module('#handleKeyDown()', () => {
    test('always returns undefined', () => {
      mountComponent()
      const result = wrapper.instance().handleKeyDown({shiftKey: false, which: 9})
      equal(typeof result, 'undefined')
    })
  })
})
/* eslint-enable qunit/no-identical-names */
