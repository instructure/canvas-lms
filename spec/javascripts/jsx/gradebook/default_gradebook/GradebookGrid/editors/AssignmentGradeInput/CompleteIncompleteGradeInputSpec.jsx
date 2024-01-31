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
import AssignmentGradeInput from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/editors/AssignmentGradeInput/index'
import fakeENV from 'helpers/fakeENV'

QUnit.module('GradebookGrid CompleteIncompleteGradeInput', suiteHooks => {
  let $container
  let props
  let $menuContent
  let resolveClose
  let wrapper

  suiteHooks.beforeEach(() => {
    fakeENV.setup({
      GRADEBOOK_OPTIONS: {assignment_missing_shortcut: true},
    })
    const assignment = {
      pointsPossible: 10,
    }
    const submission = {
      enteredGrade: null,
      enteredScore: null,
      excused: false,
      id: '2501',
    }

    props = {
      assignment,
      enterGradesAs: 'passFail',
      menuContentRef(ref) {
        $menuContent = ref
      },
      onMenuDismiss() {
        resolveClose()
      },
      submission,
    }

    $menuContent = null

    $container = document.createElement('div')
    document.body.appendChild($container)
  })

  suiteHooks.afterEach(() => {
    wrapper.unmount()
    $container.remove()
    fakeENV.teardown()
  })

  function mountComponent() {
    wrapper = mount(<AssignmentGradeInput {...props} />, {attachTo: $container})
  }

  function clickToOpen() {
    return new Promise(resolve => {
      const waitForMenuReady = () => {
        setTimeout(() => {
          if ($menuContent) {
            resolve()
          } else {
            waitForMenuReady()
          }
        })
      }
      wrapper.find('button').simulate('click')
      waitForMenuReady()
    })
  }

  function getRenderedOptions() {
    return [...$menuContent.querySelectorAll('[role="menuitem"]')]
  }

  function clickMenuItem(optionText) {
    return new Promise(resolve => {
      resolveClose = resolve
      getRenderedOptions()
        .find($option => $option.textContent === optionText)
        .click()
    })
  }

  function openAndClick(optionText) {
    return clickToOpen().then(() => clickMenuItem(optionText))
  }

  function getTextValue() {
    const text = wrapper.find('.Grid__GradeCell__CompleteIncompleteValue').at(0)
    return text.getDOMNode().textContent
  }

  test('adds the CompleteIncompleteInput-suffix class to the container', () => {
    mountComponent()
    const classList = wrapper.getDOMNode().classList
    strictEqual(classList.contains('Grid__GradeCell__CompleteIncompleteInput'), true)
  })

  test('renders a text container', () => {
    mountComponent()
    const container = wrapper.find('.Grid__GradeCell__CompleteIncompleteValue')
    strictEqual(container.length, 1)
  })

  test('optionally disables the menu button', () => {
    props.disabled = true
    mountComponent()
    const button = wrapper.find('button').at(0).getDOMNode()
    strictEqual(button.disabled, true)
  })

  test('sets the value to "Complete" when the grade is "complete"', () => {
    props.submission = {...props.submission, enteredScore: 10, enteredGrade: 'complete'}
    mountComponent()
    equal(getTextValue(), 'Complete')
  })

  test('sets the value to "Incomplete" when the grade is "incomplete"', () => {
    props.submission = {...props.submission, enteredScore: 0, enteredGrade: 'incomplete'}
    mountComponent()
    equal(getTextValue(), 'Incomplete')
  })

  test('sets the value to "–" when the grade is null', () => {
    props.submission = {...props.submission, enteredScore: null, enteredGrade: null}
    mountComponent()
    equal(getTextValue(), '–')
  })

  test('sets the value to "Excused" when the submission is excused', () => {
    props.submission = {
      ...props.submission,
      enteredScore: null,
      enteredGrade: null,
      excused: true,
    }
    mountComponent()
    equal(getTextValue(), 'Excused')
  })

  test('sets the value to the pending grade when present', () => {
    props.pendingGradeInfo = {excused: false, grade: 'complete', valid: true}
    mountComponent()
    equal(getTextValue(), 'Complete')
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

    QUnit.module('when the submission is graded', hooks => {
      hooks.beforeEach(() => {
        props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
        mountComponent()
      })

      test('sets grade to the letter grade form of the entered grade', () => {
        equal(getGradeInfo().grade, 'complete')
      })

      test('sets score to the score form of the entered grade', () => {
        strictEqual(getGradeInfo().score, 10)
      })

      test('sets enteredAs to "passFail"', () => {
        equal(getGradeInfo().enteredAs, 'passFail')
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

    QUnit.module('when the submission has a pending grade', hooks => {
      hooks.beforeEach(() => {
        props.pendingGradeInfo = {
          enteredAs: 'passFail',
          excused: false,
          grade: 'incomplete',
          score: 0,
          valid: true,
        }
        mountComponent()
      })

      test('sets grade to the grade of the pending grade', () => {
        equal(getGradeInfo().grade, 'incomplete')
      })

      test('sets score to the score of the pending grade', () => {
        strictEqual(getGradeInfo().score, 0)
      })

      test('sets enteredAs to the value of the pending grade', () => {
        equal(getGradeInfo().enteredAs, 'passFail')
      })

      test('sets excused to false', () => {
        strictEqual(getGradeInfo().excused, false)
      })
    })

    QUnit.module('when an option in the menu is clicked', hooks => {
      hooks.beforeEach(() => {
        mountComponent()
      })

      test('sets enteredAs to "passFail"', () =>
        openAndClick('Complete').then(() => {
          equal(getGradeInfo().enteredAs, 'passFail')
        }))

      test('sets grade to "complete" when "Complete" is clicked', () =>
        openAndClick('Complete').then(() => {
          equal(getGradeInfo().grade, 'complete')
        }))

      test('sets score to points possible when "Complete" is clicked', () =>
        openAndClick('Complete').then(() => {
          equal(getGradeInfo().score, 10)
        }))

      test('sets excused to false when "Complete" is clicked', () =>
        openAndClick('Complete').then(() => {
          equal(getGradeInfo().excused, false)
        }))

      test('sets grade to "incomplete" when "Incomplete" is clicked', () =>
        openAndClick('Incomplete').then(() => {
          equal(getGradeInfo().grade, 'incomplete')
        }))

      test('sets score to 0 when "Incomplete" is clicked', () =>
        openAndClick('Incomplete').then(() => {
          equal(getGradeInfo().score, 0)
        }))

      test('sets excused to false when "Incomplete" is clicked', () =>
        openAndClick('Incomplete').then(() => {
          equal(getGradeInfo().excused, false)
        }))

      test('sets grade to null when "Ungraded" is clicked', () =>
        openAndClick('Ungraded').then(() => {
          equal(getGradeInfo().grade, null)
        }))

      test('sets score to null when "Ungraded" is clicked', () =>
        openAndClick('Ungraded').then(() => {
          equal(getGradeInfo().score, null)
        }))

      test('sets excused to false when "Ungraded" is clicked', () =>
        openAndClick('Ungraded').then(() => {
          equal(getGradeInfo().excused, false)
        }))

      test('sets grade to null when "Excused" is clicked', () =>
        openAndClick('Excused').then(() => {
          equal(getGradeInfo().grade, null)
        }))

      test('sets score to null when "Excused" is clicked', () =>
        openAndClick('Excused').then(() => {
          equal(getGradeInfo().score, null)
        }))

      test('sets excused to true when "Excused" is clicked', () =>
        openAndClick('Excused').then(() => {
          equal(getGradeInfo().excused, true)
        }))
    })
  })

  QUnit.module('#focus()', () => {
    test('sets focus on the button', () => {
      mountComponent()
      wrapper.instance().focus()
      strictEqual(document.activeElement, wrapper.find('button').at(0).getDOMNode())
    })
  })

  QUnit.module('#handleKeyDown()', () => {
    const ENTER = {shiftKey: false, which: 13}

    test('returns false when pressing enter on the menu button', () => {
      mountComponent()
      const handleKeyDown = action => wrapper.instance().handleKeyDown({...action})
      // return false to allow the popover menu to open
      wrapper.find('button').at(0).getDOMNode().focus()
      strictEqual(handleKeyDown(ENTER), false)
    })
  })

  QUnit.module('#hasGradeChanged()', () => {
    function hasGradeChanged() {
      return wrapper.instance().hasGradeChanged()
    }

    test('returns false when a null grade is unchanged', () => {
      mountComponent()
      strictEqual(hasGradeChanged(), false)
    })

    test('returns true when a different grade is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
      mountComponent()
      return openAndClick('Incomplete').then(() => {
        strictEqual(hasGradeChanged(), true)
      })
    })

    test('returns true when the submission becomes excused', () => {
      props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
      mountComponent()
      return openAndClick('Excused').then(() => {
        strictEqual(hasGradeChanged(), true)
      })
    })

    test('returns false when the same grade is clicked', () => {
      props.submission = {...props.submission, enteredGrade: 'complete', enteredScore: 10}
      mountComponent()
      return openAndClick('Complete').then(() => {
        strictEqual(hasGradeChanged(), false)
      })
    })
  })

  QUnit.module('Complete/Incomplete Menu Items', () => {
    test('includes "Complete", "Incomplete", "Ungraded", and "Excused"', () => {
      const expectedLabels = ['Complete', 'Incomplete', 'Ungraded', 'Excused']
      mountComponent()
      return clickToOpen().then(() => {
        const optionsText = getRenderedOptions().map($option => $option.textContent)
        deepEqual(optionsText, expectedLabels)
      })
    })

    test('sets the value to the selected option when clicked', () => {
      mountComponent()
      return openAndClick('Incomplete').then(() => {
        equal(getTextValue(), 'Incomplete')
      })
    })

    test('set the value to "Excused" when clicked', () => {
      mountComponent()
      return openAndClick('Excused').then(() => {
        equal(getTextValue(), 'Excused')
      })
    })
  })
})
