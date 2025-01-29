/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import studentRowHeaderConstants from '../../../constants/studentRowHeaderConstants'
import StudentColumnHeader from '../StudentColumnHeader'
import {getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid StudentColumnHeader', () => {
  let $container
  let component
  let $menuContent
  let gradebookElements
  let props

  beforeEach(() => {
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

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    // eslint-disable-next-line react/no-render-return-value
    component = ReactDOM.render(<StudentColumnHeader {...props} />, $container)
  }

  function getOptionsMenuTrigger() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Student Name Options',
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

  describe('"Options" > "Display as" setting', () => {
    function getDisplayAsOption(label) {
      return getMenuItem($menuContent, 'Display as', label)
    }

    it.skip('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Display as')
      expect(gradebookElements.indexOf($sortByMenuContent)).not.toBe(-1)
    })

    it('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Display as')
      closeOptionsMenu()
      expect(gradebookElements.indexOf($sortByMenuContent)).toBe(-1)
    })

    it('is disabled when all options are disabled', () => {
      props.disabled = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem($menuContent, 'Display as').getAttribute('aria-disabled')).toBe('true')
    })

    describe('"First, Last Name" option', () => {
      it('is selected when displaying first name before last', () => {
        props.selectedPrimaryInfo = 'first_last'
        mountAndOpenOptionsMenu()
        expect(getDisplayAsOption('First, Last Name').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying last name before first', () => {
        props.selectedPrimaryInfo = 'last_first'
        mountAndOpenOptionsMenu()
        expect(getDisplayAsOption('First, Last Name').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectPrimaryInfo = jest.fn()
        })

        it('calls the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').click()
          expect(props.onSelectPrimaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "first_last" when calling the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').click()
          const [primaryInfoType] =
            props.onSelectPrimaryInfo.mock.calls[props.onSelectPrimaryInfo.mock.calls.length - 1]
          expect(primaryInfoType).toBe('first_last')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').focus()
          getDisplayAsOption('First, Last Name').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectPrimaryInfo callback when already selected', () => {
          props.selectedPrimaryInfo = 'first_last'
          mountAndOpenOptionsMenu()
          getDisplayAsOption('First, Last Name').click()
          expect(props.onSelectPrimaryInfo).not.toHaveBeenCalled()
        })
      })
    })

    describe('"Last, First Name" option', () => {
      it('is selected when displaying last name before first', () => {
        props.selectedPrimaryInfo = 'last_first'
        mountAndOpenOptionsMenu()
        expect(getDisplayAsOption('Last, First Name').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying first name before last', () => {
        props.selectedPrimaryInfo = 'first_last'
        mountAndOpenOptionsMenu()
        expect(getDisplayAsOption('Last, First Name').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectPrimaryInfo = jest.fn()
        })

        it('calls the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').click()
          expect(props.onSelectPrimaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "last_first" when calling the .onSelectPrimaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').click()
          const [primaryInfoType] =
            props.onSelectPrimaryInfo.mock.calls[props.onSelectPrimaryInfo.mock.calls.length - 1]
          expect(primaryInfoType).toBe('last_first')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').focus()
          getDisplayAsOption('Last, First Name').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectPrimaryInfo callback when already selected', () => {
          props.selectedPrimaryInfo = 'last_first'
          mountAndOpenOptionsMenu()
          getDisplayAsOption('Last, First Name').click()
          expect(props.onSelectPrimaryInfo).not.toHaveBeenCalled()
        })
      })
    })
  })
})
