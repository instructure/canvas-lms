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

describe('GradebookGrid StudentColumnHeader', () => {
  let $container
  let $menuContent
  let component
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

  it('displays "Student Name" as the column title', () => {
    mountComponent()
    expect($container.textContent.includes('Student Name')).toBeTruthy()
  })

  describe('"Options" menu trigger', () => {
    it('is labeled with "Student Name Options"', () => {
      mountComponent()
      const $trigger = getOptionsMenuTrigger()
      expect($trigger.textContent.includes('Student Name Options')).toBeTruthy()
    })

    it('opens the options menu when clicked', () => {
      mountComponent()
      getOptionsMenuTrigger().click()
      expect(getOptionsMenuContent()).toBeTruthy()
    })

    it('closes the options menu when clicked', () => {
      mountAndOpenOptionsMenu()
      getOptionsMenuTrigger().click()
      expect(getOptionsMenuContent()).toBeFalsy()
    })
  })

  describe('"Options" > "Sort by" setting', () => {
    function getSortTypeOption(label) {
      return getMenuItem($menuContent, 'Sort by', label)
    }

    function getSortOrderOption(label) {
      return getMenuItem($menuContent, 'Sort by', label)
    }

    function getSortByNameOption() {
      return getSortTypeOption('Name')
    }

    function getSortByLoginIdOption() {
      return getSortTypeOption('Login ID')
    }

    function getSortBySisIdOption() {
      return getSortTypeOption('SIS ID')
    }

    function getSortByIntegrationIdOption() {
      return getSortTypeOption('Integration ID')
    }

    function getAscendingSortOrderOption() {
      return getSortOrderOption('A–Z')
    }

    function getDescendingSortOrderOption() {
      return getSortOrderOption('Z–A')
    }

    it.skip('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Sort by')
      expect(gradebookElements.indexOf($sortByMenuContent)).not.toBe(-1)
    })

    it('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Sort by')
      closeOptionsMenu()
      expect(gradebookElements.indexOf($sortByMenuContent)).toBe(-1)
    })

    it('is disabled when all options are disabled', () => {
      props.disabled = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem($menuContent, 'Sort by').getAttribute('aria-disabled')).toBe('true')
    })

    describe('"Type" menu group', () => {
      describe('"Name" option', () => {
        it('is selected when sorting by sortable name', () => {
          props.sortBySetting.settingKey = 'sortable_name'
          mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by sortable name', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortBySortableName = jest.fn()
          })

          it('calls the .sortBySetting.onSortBySortableName callback', () => {
            mountAndOpenOptionsMenu()
            getSortByNameOption().click()
            expect(props.sortBySetting.onSortBySortableName).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortByNameOption().focus()
            getSortByNameOption().click()
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          it.skip('does not call the .sortBySetting.onSortBySortableName callback when already selected', () => {
            props.sortBySetting.settingKey = 'sortable_name'
            mountAndOpenOptionsMenu()
            getSortByNameOption().focus()
            expect(props.sortBySetting.onSortBySortableName).not.toHaveBeenCalled()
          })
        })
      })

      describe('"SIS ID" option', () => {
        it('is selected when sorting by SIS ID', () => {
          props.sortBySetting.settingKey = 'sis_user_id'
          mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by SIS ID', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortBySisId = jest.fn()
          })

          it('calls the .sortBySetting.onSortBySisId callback', () => {
            mountAndOpenOptionsMenu()
            getSortBySisIdOption().click()
            expect(props.sortBySetting.onSortBySisId).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortBySisIdOption().focus()
            getSortBySisIdOption().click()
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          it.skip('does not call the .sortBySetting.onSortBySisId callback when already selected', () => {
            props.sortBySetting.settingKey = 'sis_user_id'
            mountAndOpenOptionsMenu()
            getSortBySisIdOption().focus()
            expect(props.sortBySetting.onSortBySisId).not.toHaveBeenCalled()
          })
        })
      })

      describe('"Integration ID" option', () => {
        it('is selected when sorting by integration ID', () => {
          props.sortBySetting.settingKey = 'integration_id'
          mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by integration ID', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortByIntegrationId = jest.fn()
          })

          it('calls the .sortBySetting.onSortByIntegrationId callback', () => {
            mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().click()
            expect(props.sortBySetting.onSortByIntegrationId).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().focus()
            getSortByIntegrationIdOption().click()
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          it.skip('does not call the .sortBySetting.onSortByIntegrationId callback when already selected', () => {
            props.sortBySetting.settingKey = 'integration_id'
            mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().focus()
            expect(props.sortBySetting.onSortByIntegrationId).not.toHaveBeenCalled()
          })
        })
      })

      describe('"Login ID" option', () => {
        it('is selected when sorting by login ID', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by login ID', () => {
          props.sortBySetting.settingKey = 'sortable_name'
          mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortByLoginId = jest.fn()
          })

          it('calls the .sortBySetting.onSortByLoginId callback', () => {
            mountAndOpenOptionsMenu()
            getSortByLoginIdOption().click()
            expect(props.sortBySetting.onSortByLoginId).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortByLoginIdOption().focus()
            getSortByLoginIdOption().click()
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          it.skip('does not call the .sortBySetting.onSortByLoginId callback when already selected', () => {
            props.sortBySetting.settingKey = 'login_id'
            mountAndOpenOptionsMenu()
            getSortByLoginIdOption().focus()
            expect(props.sortBySetting.onSortByLoginId).not.toHaveBeenCalled()
          })
        })
      })
    })

    describe('"Order" menu group', () => {
      describe('"A–Z" option', () => {
        it('is selected when sorting in ascending order', () => {
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting in ascending order', () => {
          props.sortBySetting.direction = 'descending'
          mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortInAscendingOrder = jest.fn()
          })

          it('calls the .sortBySetting.onSortInAscendingOrder callback', () => {
            mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().click()
            expect(props.sortBySetting.onSortInAscendingOrder).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().focus()
            getAscendingSortOrderOption().click()
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          it.skip('does not call the .sortBySetting.onSortInAscendingOrder callback when already selected', () => {
            props.sortBySetting.direction = 'ascending'
            mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().click()
            expect(props.sortBySetting.onSortBySortableNameAscending).not.toHaveBeenCalled()
          })
        })
      })

      describe('"Z–A" option', () => {
        it('is selected when sorting in descending order', () => {
          props.sortBySetting.direction = 'descending'
          mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting in descending order', () => {
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortInDescendingOrder = jest.fn()
          })

          it('calls the .sortBySetting.onSortInDescendingOrder callback', () => {
            mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().click()
            expect(props.sortBySetting.onSortInDescendingOrder).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().focus()
            getDescendingSortOrderOption().click()
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          it.skip('does not call the .sortBySetting.onSortInDescendingOrder callback when already selected', () => {
            props.sortBySetting.direction = 'ascending'
            mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().click()
            expect(props.sortBySetting.onSortBySortableNameDescending).not.toHaveBeenCalled()
          })
        })
      })
    })
  })
})
