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

/* eslint-disable qunit/no-identical-names */

import React from 'react'
import {mount, ReactWrapper} from 'old-enzyme-2.x-you-need-to-upgrade-this-spec-to-enzyme-3.x-by-importing-just-enzyme'
import GradeInput from 'jsx/gradezilla/default_gradebook/GradebookGrid/editors/AssignmentCellEditor/GradeInput'

QUnit.module('GradeInput using GradingSchemeGradeInput', suiteHooks => {
  let $container
  let props
  let $menuContent
  let resolveClose
  let resolveOpen
  let qunitTimeout
  let wrapper

  suiteHooks.beforeEach(() => {
    qunitTimeout = QUnit.config.testTimeout
    QUnit.config.testTimeout = 500 // protect against unresolved async mistakes

    const assignment = {
      pointsPossible: 10
    }
    const submission = {
      enteredGrade: null,
      enteredScore: null,
      excused: false,
      id: '2501'
    }
    const gradingScheme = [
      ['A+', 0.97],
      ['A', 0.93],
      ['A-', 0.9],
      ['B+', 0.87],
      ['B', 0.83],
      ['B-', 0.8],
      ['C+', 0.77],
      ['C', 0.73],
      ['C-', 0.7],
      ['D+', 0.67],
      ['D', 0.63],
      ['D-', 0.6],
      ['F', 0]
    ]

    props = {
      assignment,
      enterGradesAs: 'gradingScheme',
      disabled: false,
      gradingScheme,
      menuContentRef(ref) {
        $menuContent = ref
      },
      onMenuDismiss() {
        resolveClose()
      },
      onMenuShow() {
        resolveOpen()
      },
      submission
    }

    $menuContent = null

    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
    QUnit.config.testTimeout = qunitTimeout
  })

  function mountComponent() {
    wrapper = mount(<GradeInput {...props} />, {attachTo: $container})
  }

  function clickToOpen() {
    return new Promise(resolve => {
      resolveOpen = resolve
      wrapper.find('button').simulate('click')
    })
  }

  function getRenderedOptions() {
    return new ReactWrapper([...$menuContent.querySelectorAll('[role="menuitem"]')], $menuContent)
  }

  function clickMenuItem(optionText) {
    return new Promise(resolve => {
      resolveClose = resolve
      const matchingOptions = getRenderedOptions().filterWhere(
        option => option.text() === optionText
      )
      matchingOptions.first().simulate('click')
    })
  }

  function openAndClick(optionText) {
    return clickToOpen().then(() => clickMenuItem(optionText))
  }

  function getTextInputValue() {
    return wrapper.find('input').getDOMNode().value
  }

  test('adds the GradingSchemeInput-suffix class to the container', () => {
    mountComponent()
    strictEqual(wrapper.hasClass('Grid__AssignmentRowCell__GradingSchemeInput'), true)
  })

  test('renders a text input', () => {
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.length, 1)
  })

  test('optionally disables the input', () => {
    props.disabled = true
    mountComponent()
    const input = wrapper.find('input[type="text"]')
    strictEqual(input.prop('disabled'), true)
  })

  test('optionally disables the menu button', () => {
    props.disabled = true
    mountComponent()
    const button = wrapper.find('button').node
    strictEqual(button.disabled, true)
  })

  test('sets as the input value the grade corresponding to the entered score', () => {
    props.submission = {...props.submission, enteredScore: 7.8, enteredGrade: 'C+'}
    mountComponent()
    equal(getTextInputValue(), 'C+')
  })

  test('sets the input to the pending grade when present and valid', () => {
    props.pendingGradeInfo = {excused: false, grade: 'A+', valid: true}
    mountComponent()
    equal(getTextInputValue(), 'A+')
  })

  test('sets the input to the pending grade when present and invalid', () => {
    props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
    mountComponent()
    equal(getTextInputValue(), 'invalid')
  })

  QUnit.module('#componentWillReceiveProps()', () => {
    test('sets the input value to the entered score of the updated submission', () => {
      mountComponent()
      wrapper.setProps({submission: {...props.submission, enteredScore: 8.0, enteredGrade: 'B-'}})
      equal(getTextInputValue(), 'B-')
    })

    test('displays "Excused" as the input value when the updated submission is excused', () => {
      mountComponent()
      wrapper.setProps({
        submission: {...props.submission, excused: true, enteredScore: null, enteredGrade: null}
      })
      equal(getTextInputValue(), 'Excused')
    })

    test('does not update the input value when the input has focus', () => {
      mountComponent()
      wrapper
        .find('input')
        .get(0)
        .focus()
      wrapper.setProps({submission: {...props.submission, enteredScore: 8.0, enteredGrade: 'B-'}})
      strictEqual(getTextInputValue(), '')
    })
  })

  QUnit.module('#gradeInfo', () => {
    function getGradeInfo() {
      return wrapper.instance().gradeInfo
    }

    QUnit.module('when the submission is ungraded', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to null', () => {
        strictEqual(getGradeInfo().enteredAs, null)
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the submission becomes ungraded', hooks => {
      hooks.beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
        wrapper.setProps({
          submission: {...props.submission, enteredGrade: null, enteredScore: null}
        })
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to null', () => {
        strictEqual(getGradeInfo().enteredAs, null)
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the submission is graded', hooks => {
      hooks.beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
      })

      test('sets grade to the letter grade form of the entered grade', () => {
        equal(getGradeInfo().grade, 'C')
      })

      test('sets score to the score form of the entered grade', () => {
        strictEqual(getGradeInfo().score, 7.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        equal(getGradeInfo().enteredAs, 'gradingScheme')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the submission becomes graded', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.setProps({submission: {...props.submission, enteredGrade: 'C', enteredScore: 7.6}})
      })

      test('sets grade to the letter grade form of the entered grade', () => {
        equal(getGradeInfo().grade, 'C')
      })

      test('sets score to the score form of the entered grade', () => {
        strictEqual(getGradeInfo().score, 7.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        equal(getGradeInfo().enteredAs, 'gradingScheme')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the submission is excused', hooks => {
      hooks.beforeEach(() => {
        props.submission = {...props.submission, excused: true}
        mountComponent()
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to "excused"', () => {
        equal(getGradeInfo().enteredAs, 'excused')
      })

      test('sets excused to true', () => {
        strictEqual(getGradeInfo().excused, true)
      })
    })

    QUnit.module('when the submission becomes excused', hooks => {
      hooks.beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
        mountComponent()
        wrapper.setProps({
          submission: {...props.submission, enteredGrade: null, enteredScore: null, excused: true}
        })
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to "excused"', () => {
        equal(getGradeInfo().enteredAs, 'excused')
      })

      test('sets excused to true', () => {
        strictEqual(getGradeInfo().excused, true)
      })
    })

    QUnit.module('when the submission has a pending grade', hooks => {
      hooks.beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true
        }
        mountComponent()
      })

      test('sets grade to the grade of the pending grade', () => {
        equal(getGradeInfo().grade, 'B')
      })

      test('sets score to the score of the pending grade', () => {
        strictEqual(getGradeInfo().score, 8.6)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        equal(getGradeInfo().enteredAs, 'points')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the submission receives a pending grade', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.setProps({
          pendingGradeInfo: {
            enteredAs: 'points',
            excused: false,
            grade: 'B',
            score: 8.6,
            valid: true
          }
        })
      })

      test('sets grade to the grade of the pending grade', () => {
        equal(getGradeInfo().grade, 'B')
      })

      test('sets score to the score of the pending grade', () => {
        strictEqual(getGradeInfo().score, 8.6)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        equal(getGradeInfo().enteredAs, 'points')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the pending grade updates', hooks => {
      hooks.beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true
        }
        mountComponent()
        wrapper.setProps({
          pendingGradeInfo: {
            enteredAs: 'percent',
            excused: false,
            grade: 'A',
            score: 9.3,
            valid: true
          }
        })
      })

      test('sets grade to the grade of the pending grade', () => {
        equal(getGradeInfo().grade, 'A')
      })

      test('sets score to the score of the pending grade', () => {
        strictEqual(getGradeInfo().score, 9.3)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        equal(getGradeInfo().enteredAs, 'percent')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the pending grade resolves with a graded submission', hooks => {
      hooks.beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'points',
          excused: false,
          grade: 'B',
          score: 8.6,
          valid: true
        }
        mountComponent()
        wrapper.setProps({
          pendingGradeInfo: null,
          submission: {...props.submission, enteredGrade: 'B', enteredScore: 8.6}
        })
      })

      test('sets grade to the letter grade form of the entered grade on the submission', () => {
        equal(getGradeInfo().grade, 'B')
      })

      test('sets score to the score form of the entered grade on the submission', () => {
        strictEqual(getGradeInfo().score, 8.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        equal(getGradeInfo().enteredAs, 'gradingScheme')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    test('trims whitespace from changed input values', () => {
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: ' B '}})
      equal(getGradeInfo().grade, 'B')
    })

    QUnit.module('when a point value is entered', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.find('input').simulate('change', {target: {value: '8.9'}})
      })

      test('sets grade to the percent form of the entered grade', () => {
        equal(getGradeInfo().grade, 'B+')
      })

      test('sets score to the score form of the entered grade', () => {
        strictEqual(getGradeInfo().score, 8.9)
      })

      test('sets enteredAs to "points"', () => {
        equal(getGradeInfo().enteredAs, 'points')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when a percent value is entered', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.find('input').simulate('change', {target: {value: '89%'}})
      })

      test('sets grade to the entered grade', () => {
        equal(getGradeInfo().grade, 'B+')
      })

      test('sets score to the score form of the entered grade', () => {
        strictEqual(getGradeInfo().score, 8.9)
      })

      test('sets enteredAs to "percent"', () => {
        equal(getGradeInfo().enteredAs, 'percent')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when a grading scheme value is entered', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.find('input').simulate('change', {target: {value: 'B'}})
      })

      test('sets grade to the percent form of the entered grade', () => {
        equal(getGradeInfo().grade, 'B')
      })

      test('sets score to the score form of the entered grade', () => {
        strictEqual(getGradeInfo().score, 8.6)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        equal(getGradeInfo().enteredAs, 'gradingScheme')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when "EX" is entered', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.find('input').simulate('change', {target: {value: 'EX'}})
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to "excused"', () => {
        equal(getGradeInfo().enteredAs, 'excused')
      })

      test('sets excused to true', () => {
        strictEqual(getGradeInfo().excused, true)
      })
    })

    QUnit.module('when the input is cleared', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        wrapper.find('input').simulate('change', {target: {value: 'B'}})
        wrapper.find('input').simulate('change', {target: {value: ''}})
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to null', () => {
        strictEqual(getGradeInfo().enteredAs, null)
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    test('ignores case for "ex"', () => {
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'ex'}})
      strictEqual(getGradeInfo().excused, true)
    })

    QUnit.module('when a grading scheme option is clicked', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        return openAndClick('B+')
      })

      test('sets grade to the clicked scheme key', () => {
        equal(getGradeInfo().grade, 'B+')
      })

      test('sets score to the score form of the clicked scheme key', () => {
        strictEqual(getGradeInfo().score, 8.9)
      })

      test('sets enteredAs to "gradingScheme"', () => {
        equal(getGradeInfo().enteredAs, 'gradingScheme')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when the "Excused" option is clicked', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
        return openAndClick('Excused')
      })

      test('sets grade to null', () => {
        strictEqual(getGradeInfo().grade, null)
      })

      test('sets score to null', () => {
        strictEqual(getGradeInfo().score, null)
      })

      test('sets enteredAs to "excused"', () => {
        equal(getGradeInfo().enteredAs, 'excused')
      })

      test('sets excused to true', () => {
        strictEqual(getGradeInfo().excused, true)
      })
    })
  })

  QUnit.module('#focus()', () => {
    test('sets focus on the input', () => {
      mountComponent()
      wrapper.instance().focus()
      strictEqual(document.activeElement, wrapper.find('input').get(0))
    })

    test('selects the content of the input', () => {
      props.submission = {...props.submission, enteredScore: 8.13, enteredGrade: 'B-'}
      mountComponent()
      wrapper.instance().focus()
      equal(document.getSelection().toString(), 'B-')
    })

    test('does not take focus from the grading scheme menu button', () => {
      mountComponent()
      wrapper
        .find('button')
        .get(0)
        .focus()
      wrapper.instance().focus()
      strictEqual(document.activeElement, wrapper.find('button').get(0))
    })

    test('does not change focus when the grading scheme menu is open', () => {
      mountComponent()
      return clickToOpen().then(() => {
        const currentActiveElement = document.activeElement
        wrapper.instance().focus()
        strictEqual(document.activeElement, currentActiveElement)
      })
    })
  })

  QUnit.module('#handleKeyDown()', hooks => {
    const TAB = {shiftKey: false, which: 9}
    const SHIFT_TAB = {shiftKey: true, which: 9}
    const ENTER = {shiftKey: false, which: 13}

    hooks.beforeEach(() => {
      mountComponent()
    })

    function focusOn(element) {
      const node = wrapper.find(element).get(0)
      node.focus()
    }

    function handleKeyDown(action) {
      return wrapper.instance().handleKeyDown({...action})
    }

    test('returns false when tabbing from the input to the menu button', () => {
      // return false so that focus moves from the input to the menu button
      focusOn('input')
      strictEqual(handleKeyDown(TAB), false)
    })

    test('returns undefined when tabbing forward from the menu button', () => {
      // return undefined to delegate event handling to the parent
      focusOn('button')
      equal(typeof handleKeyDown(TAB), 'undefined')
    })

    test('returns false when shift+tabbing from the menu button to the input', () => {
      // return false so that focus moves from the menu button to the input
      focusOn('button')
      strictEqual(handleKeyDown(SHIFT_TAB), false)
    })

    test('returns undefined when shift+tabbing back from the input', () => {
      // return undefined to delegate event handling to the parent
      focusOn('input')
      equal(typeof handleKeyDown(SHIFT_TAB), 'undefined')
    })

    test('returns false when pressing enter on the menu button', () => {
      // return false to allow the popover menu to open
      focusOn('button')
      strictEqual(handleKeyDown(ENTER), false)
    })

    test('returns undefined when pressing enter on the input', () => {
      // return undefined to delegate event handling to the parent
      focusOn('input')
      equal(typeof handleKeyDown(ENTER), 'undefined')
    })
  })

  QUnit.module('#hasGradeChanged()', () => {
    function hasGradeChanged() {
      return wrapper.instance().hasGradeChanged()
    }

    test('returns true when an invalid grade is entered', () => {
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'invalid'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns false when an invalid grade is entered without change', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'invalid'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('ignores whitespace when comparing an invalid grade', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '  invalid  '}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns true when an invalid grade is changed to a different invalid grade', () => {
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'also invalid'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns true when an invalid grade is cleared', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: ''}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns false when a valid grade is pending', () => {
      props.pendingGradeInfo = {excused: false, grade: 'B', valid: true}
      mountComponent()
      // with valid pending grades, the input is disabled
      // changing grades is not allowed at this time
      wrapper.find('input').simulate('change', {target: {value: 'invalid'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns false when a null grade is unchanged', () => {
      mountComponent()
      strictEqual(hasGradeChanged(), false)
    })

    test('returns true when a different grade is entered', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'B'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns true when a different grade is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      return openAndClick('B').then(() => {
        strictEqual(hasGradeChanged(), true)
      })
    })

    test('returns true when the submission becomes excused', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'EX'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns true when "Excused" is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      return openAndClick('Excused').then(() => {
        strictEqual(hasGradeChanged(), true)
      })
    })

    test('returns false when the grade has not changed', () => {
      mountComponent()
      strictEqual(hasGradeChanged(), false)
    })

    test('returns false when the same grade is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      return openAndClick('C').then(() => {
        strictEqual(hasGradeChanged(), false)
      })
    })

    test('returns false when the grade has not changed to a different grading scheme key', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'C'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns false when the grade has changed to the same value in "points"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '7.6'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns false when the grade has changed to the same value in "percent"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '76%'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns true when the grade has changed to a different value in "points"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '7.8'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns true when the grade has changed to a different value in "percent"', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '78%'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns false when the grade is stored as the same value in "points"', () => {
      props.submission = {...props.submission, enteredGrade: '7.6', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'C'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns false when the grade is stored as the same value in "percent"', () => {
      props.submission = {...props.submission, enteredGrade: '76%', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'C'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('returns true when an invalid grade is corrected', () => {
      props.pendingGradeInfo = {excused: false, grade: 'invalid', valid: false}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'B'}})
      strictEqual(hasGradeChanged(), true)
    })

    test('returns false when the grade has changed back to the original value', () => {
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'B'}})
      wrapper.find('input').simulate('change', {target: {value: ''}})
      strictEqual(hasGradeChanged(), false)
    })

    test('ignores whitespace in the entered grade', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '  C  '}})
      strictEqual(hasGradeChanged(), false)
    })

    test('ignores case for "ex"', () => {
      props.submission = {...props.submission, excused: true}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: 'ex'}})
      strictEqual(hasGradeChanged(), false)
    })

    test('ignores unnecessary zeros in the entered grade', () => {
      props.submission = {...props.submission, enteredGrade: 'C', enteredScore: 7.6}
      mountComponent()
      wrapper.find('input').simulate('change', {target: {value: '7.600'}})
      strictEqual(hasGradeChanged(), false)
    })

    QUnit.module('when the submission is excused', contextHooks => {
      contextHooks.beforeEach(() => {
        props.submission = {...props.submission, excused: true}
        mountComponent()
      })

      test('returns false when the input is unchanged', () => {
        strictEqual(hasGradeChanged(), false)
      })

      test('returns false when "EX" is entered', () => {
        wrapper.find('input').simulate('change', {target: {value: 'EX'}})
        strictEqual(hasGradeChanged(), false)
      })

      test('returns false when the input adds only whitespace', () => {
        wrapper.find('input').simulate('change', {target: {value: '   Excused   '}})
        strictEqual(hasGradeChanged(), false)
      })
    })
  })

  QUnit.module('Grading Scheme Menu Items', () => {
    test('includes an option for each grading scheme key', () => {
      mountComponent()
      return clickToOpen().then(() => {
        equal(getRenderedOptions().length, 14) // includes "Excused"
      })
    })

    test('uses the grading scheme key for each grading scheme option', () => {
      const expectedLabels = props.gradingScheme.map(([key]) => key) // ['A+', 'A', …, 'F']
      mountComponent()
      return clickToOpen().then(() => {
        const optionsText = getRenderedOptions().map(option => option.text())
        deepEqual(optionsText.slice(0, 13), expectedLabels)
      })
    })

    test('includes "Excused" as the last option', () => {
      mountComponent()
      return clickToOpen().then(() => {
        equal(
          getRenderedOptions()
            .last()
            .text(),
          'Excused'
        )
      })
    })

    test('set the input to the selected scheme key when clicked', () => {
      mountComponent()
      return openAndClick('B').then(() => {
        equal(getTextInputValue(), 'B')
      })
    })

    test('set the input to "Excused" when clicked', () => {
      mountComponent()
      return openAndClick('Excused').then(() => {
        equal(getTextInputValue(), 'Excused')
      })
    })
  })
})
