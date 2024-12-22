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
import ReactDOM from 'react-dom'

import StudentColumnHeader from '../StudentColumnHeader'
import studentRowHeaderConstants from '../../../constants/studentRowHeaderConstants'
import {blurElement, getMenuItem} from './ColumnHeaderSpecHelpers'

QUnit.module('GradebookGrid StudentColumnHeader', suiteHooks => {
  let $container
  let $menuContent
  let component
  let gradebookElements
  let props

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

    gradebookElements = []
    props = {
      addGradebookElement($el) {
        gradebookElements.push($el)
      },

      disabled: false,

      onMenuDismiss() {},
      onSelectPrimaryInfo() {},
      onSelectSecondaryInfo() {},
      onToggleEnrollmentFilter() {},

      removeGradebookElement($el) {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
      },

      sectionsEnabled: true,
      selectedEnrollmentFilters: [],
      selectedPrimaryInfo: studentRowHeaderConstants.defaultPrimaryInfo,
      selectedSecondaryInfo: studentRowHeaderConstants.defaultSecondaryInfo,

      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        // sort callbacks with additional sort options enabled
        onSortByIntegrationId() {},
        onSortByLoginId() {},
        onSortBySisId() {},
        onSortBySortableName() {},
        onSortInAscendingOrder() {},
        onSortInDescendingOrder() {},
        // sort callbacks with additional sort options disabled
        onSortBySortableNameAscending() {},
        onSortBySortableNameDescending() {},
        settingKey: 'sortable_name',
      },
      studentGroupsEnabled: true,
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    // eslint-disable-next-line react/no-render-return-value
    component = ReactDOM.render(<StudentColumnHeader {...props} />, $container)
  }

  function getOptionsMenuTrigger() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Student Name Options'
    )
  }

  function getOptionsMenuContent() {
    const $button = getOptionsMenuTrigger()
    return document.querySelector(`[aria-labelledby="${$button.id}"]`)
  }

  function openOptionsMenu() {
    getOptionsMenuTrigger().click()
    $menuContent = getOptionsMenuContent()
  }

  function mountAndOpenOptionsMenu() {
    mountComponent()
    openOptionsMenu()
  }

  QUnit.module('"Options" > "Show" setting', () => {
    function getShowOption(label) {
      return getMenuItem($menuContent, label)
    }

    QUnit.module('"Inactive enrollments" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        ok(getShowOption('Inactive enrollments'))
      })

      test('is selected when showing inactive enrollments', () => {
        props.selectedEnrollmentFilters = ['concluded', 'inactive']
        mountAndOpenOptionsMenu()
        strictEqual(getShowOption('Inactive enrollments').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when not showing inactive enrollments', () => {
        props.selectedEnrollmentFilters = ['concluded']
        mountAndOpenOptionsMenu()
        strictEqual(getShowOption('Inactive enrollments').getAttribute('aria-checked'), 'false')
      })

      test('is disabled when all options are disabled', () => {
        props.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getShowOption('Inactive enrollments').getAttribute('aria-disabled'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onToggleEnrollmentFilter = sinon.stub()
        })

        test('calls the .onToggleEnrollmentFilter callback', () => {
          mountAndOpenOptionsMenu()
          getShowOption('Inactive enrollments').click()
          strictEqual(props.onToggleEnrollmentFilter.callCount, 1)
        })

        test('includes "inactive" when calling the .onToggleEnrollmentFilter callback', () => {
          mountAndOpenOptionsMenu()
          getShowOption('Inactive enrollments').click()
          const [secondaryInfoType] = props.onToggleEnrollmentFilter.lastCall.args
          equal(secondaryInfoType, 'inactive')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getShowOption('Inactive enrollments').focus()
          getShowOption('Inactive enrollments').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })
      })
    })

    QUnit.module('"Concluded enrollments" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        ok(getShowOption('Concluded enrollments'))
      })

      test('is selected when showing concluded enrollments', () => {
        props.selectedEnrollmentFilters = ['concluded', 'inactive']
        mountAndOpenOptionsMenu()
        strictEqual(getShowOption('Concluded enrollments').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when not showing concluded enrollments', () => {
        props.selectedEnrollmentFilters = ['inactive']
        mountAndOpenOptionsMenu()
        strictEqual(getShowOption('Concluded enrollments').getAttribute('aria-checked'), 'false')
      })

      test('is disabled when all options are disabled', () => {
        props.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getShowOption('Concluded enrollments').getAttribute('aria-disabled'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onToggleEnrollmentFilter = sinon.stub()
        })

        test('calls the .onToggleEnrollmentFilter callback', () => {
          mountAndOpenOptionsMenu()
          getShowOption('Concluded enrollments').click()
          strictEqual(props.onToggleEnrollmentFilter.callCount, 1)
        })

        test('includes "concluded" when calling the .onToggleEnrollmentFilter callback', () => {
          mountAndOpenOptionsMenu()
          getShowOption('Concluded enrollments').click()
          const [secondaryInfoType] = props.onToggleEnrollmentFilter.lastCall.args
          equal(secondaryInfoType, 'concluded')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getShowOption('Concluded enrollments').focus()
          getShowOption('Concluded enrollments').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })
      })
    })
  })

  QUnit.module('#handleKeyDown()', hooks => {
    let preventDefault

    hooks.beforeEach(() => {
      preventDefault = sinon.spy()
      mountComponent()
    })

    function handleKeyDown(which, shiftKey = false) {
      return component.handleKeyDown({which, shiftKey, preventDefault})
    }

    QUnit.module('when the "Options" menu trigger has focus', contextHooks => {
      contextHooks.beforeEach(() => {
        getOptionsMenuTrigger().focus()
      })

      test('does not handle Tab', () => {
        // This allows Grid Support Navigation to handle navigation.
        const returnValue = handleKeyDown(9, false) // Tab
        equal(typeof returnValue, 'undefined')
      })

      test('does not handle Shift+Tab', () => {
        // This allows Grid Support Navigation to handle navigation.
        const returnValue = handleKeyDown(9, true) // Shift+Tab
        equal(typeof returnValue, 'undefined')
      })

      test('Enter opens the the "Options" menu', () => {
        handleKeyDown(13) // Enter
        ok($menuContent)
      })

      test('returns false for Enter', () => {
        // This prevents additional behavior in Grid Support Navigation.
        const returnValue = handleKeyDown(13) // Enter
        strictEqual(returnValue, false)
      })
    })

    QUnit.module('when the header does not have focus', () => {
      test('does not handle Tab', () => {
        const returnValue = handleKeyDown(9, false) // Tab
        equal(typeof returnValue, 'undefined')
      })

      test('does not handle Shift+Tab', () => {
        const returnValue = handleKeyDown(9, true) // Shift+Tab
        equal(typeof returnValue, 'undefined')
      })

      test('does not handle Enter', () => {
        const returnValue = handleKeyDown(13) // Enter
        equal(typeof returnValue, 'undefined')
      })
    })
  })

  QUnit.module('focus', hooks => {
    hooks.beforeEach(() => {
      mountComponent()
    })

    test('#focusAtStart() sets focus on the "Options" menu trigger', () => {
      component.focusAtStart()
      strictEqual(document.activeElement, getOptionsMenuTrigger())
    })

    test('#focusAtEnd() sets focus on the "Options" menu trigger', () => {
      component.focusAtEnd()
      strictEqual(document.activeElement, getOptionsMenuTrigger())
    })

    test('adds the "focused" class to the header when the "Options" menu trigger receives focus', () => {
      getOptionsMenuTrigger().focus()
      ok($container.firstChild.classList.contains('focused'))
    })

    test('removes the "focused" class from the header when focus leaves', () => {
      getOptionsMenuTrigger().focus()
      blurElement(getOptionsMenuTrigger())
      notOk($container.firstChild.classList.contains('focused'))
    })
  })
})
