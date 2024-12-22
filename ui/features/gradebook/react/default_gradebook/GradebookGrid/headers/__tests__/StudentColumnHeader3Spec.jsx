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
import {getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

QUnit.module('GradebookGrid StudentColumnHeader', suiteHooks => {
  let $container
  let component
  let $menuContent
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

  function closeOptionsMenu() {
    getOptionsMenuTrigger().click()
  }

  QUnit.module('"Options" > "Display as" setting', () => {
    function getDisplayAsOption(label) {
      return getMenuItem($menuContent, 'Display as', label)
    }

    QUnit.skip('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Display as')
      notEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    test('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Display as')
      closeOptionsMenu()
      strictEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    test('is disabled when all options are disabled', () => {
      props.disabled = true
      mountAndOpenOptionsMenu()
      strictEqual(getMenuItem($menuContent, 'Display as').getAttribute('aria-disabled'), 'true')
    })

    QUnit.module('"First, Last Name" option', () => {
      test('is selected when displaying first name before last', () => {
        props.selectedPrimaryInfo = 'first_last'
        mountAndOpenOptionsMenu()
        strictEqual(getDisplayAsOption('First, Last Name').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying last name before first', () => {
        props.selectedPrimaryInfo = 'last_first'
        mountAndOpenOptionsMenu()
        strictEqual(getDisplayAsOption('First, Last Name').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectPrimaryInfo = sinon.stub()
        })

        test('calls the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').click()
          strictEqual(props.onSelectPrimaryInfo.callCount, 1)
        })

        test('includes "first_last" when calling the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').click()
          const [primaryInfoType] = props.onSelectPrimaryInfo.lastCall.args
          equal(primaryInfoType, 'first_last')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').focus()
          getDisplayAsOption('First, Last Name').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip('does not call the .onSelectPrimaryInfo callback when already selected', () => {
          props.selectedPrimaryInfo = 'first_last'
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').click()
          strictEqual(props.onSelectPrimaryInfo.callCount, 0)
        })
      })
    })

    QUnit.module('"Last, First Name" option', () => {
      test('is selected when displaying last name before first', () => {
        props.selectedPrimaryInfo = 'last_first'
        mountAndOpenOptionsMenu()
        strictEqual(getDisplayAsOption('Last, First Name').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying first name before last', () => {
        props.selectedPrimaryInfo = 'first_last'
        mountAndOpenOptionsMenu()
        strictEqual(getDisplayAsOption('Last, First Name').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectPrimaryInfo = sinon.stub()
        })

        test('calls the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').click()
          strictEqual(props.onSelectPrimaryInfo.callCount, 1)
        })

        test('includes "last_first" when calling the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').click()
          const [primaryInfoType] = props.onSelectPrimaryInfo.lastCall.args
          equal(primaryInfoType, 'last_first')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').focus()
          getDisplayAsOption('Last, First Name').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip('does not call the .onSelectPrimaryInfo callback when already selected', () => {
          props.selectedPrimaryInfo = 'last_first'
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').click()
          strictEqual(props.onSelectPrimaryInfo.callCount, 0)
        })
      })
    })
  })
})
