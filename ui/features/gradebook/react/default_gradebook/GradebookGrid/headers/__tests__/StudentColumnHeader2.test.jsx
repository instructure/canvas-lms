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
import {waitFor} from '@testing-library/react'

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

  async function openOptionsMenu() {
    getOptionsMenuTrigger().click()
    await waitFor(() => {
      $menuContent = getOptionsMenuContent()
      expect($menuContent).toBeInTheDocument()
    })
  }

  async function mountAndOpenOptionsMenu() {
    mountComponent()
    await openOptionsMenu()
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

    it('closes the options menu when clicked', async () => {
      await mountAndOpenOptionsMenu()
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


    it('is removed as a Gradebook element when closed', async () => {
      await mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Sort by')
      closeOptionsMenu()
      expect(gradebookElements.indexOf($sortByMenuContent)).toBe(-1)
    })

    it('is disabled when all options are disabled', async () => {
      props.disabled = true
      await mountAndOpenOptionsMenu()
      expect(getMenuItem($menuContent, 'Sort by').getAttribute('aria-disabled')).toBe('true')
    })

    describe('"Type" menu group', () => {
      describe('"Name" option', () => {
        it('is selected when sorting by sortable name', async () => {
          props.sortBySetting.settingKey = 'sortable_name'
          await mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by sortable name', async () => {
          props.sortBySetting.settingKey = 'login_id'
          await mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', async () => {
          props.sortBySetting.isSortColumn = false
          await mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', async () => {
          props.sortBySetting.disabled = true
          await mountAndOpenOptionsMenu()
          expect(getSortByNameOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortBySortableName = vi.fn()
          })

          it('calls the .sortBySetting.onSortBySortableName callback', async () => {
            await mountAndOpenOptionsMenu()
            getSortByNameOption().click()
            expect(props.sortBySetting.onSortBySortableName).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', async () => {
            await mountAndOpenOptionsMenu()
            getSortByNameOption().focus()
            getSortByNameOption().click()
            await waitFor(() => {
              expect(document.activeElement).toBe(getOptionsMenuTrigger())
            })
          })
        })
      })

      describe('"SIS ID" option', () => {
        it('is selected when sorting by SIS ID', async () => {
          props.sortBySetting.settingKey = 'sis_user_id'
          await mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by SIS ID', async () => {
          props.sortBySetting.settingKey = 'login_id'
          await mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', async () => {
          props.sortBySetting.isSortColumn = false
          await mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', async () => {
          props.sortBySetting.disabled = true
          await mountAndOpenOptionsMenu()
          expect(getSortBySisIdOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortBySisId = vi.fn()
          })

          it('calls the .sortBySetting.onSortBySisId callback', async () => {
            await mountAndOpenOptionsMenu()
            getSortBySisIdOption().click()
            expect(props.sortBySetting.onSortBySisId).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', async () => {
            await mountAndOpenOptionsMenu()
            getSortBySisIdOption().focus()
            getSortBySisIdOption().click()
            await waitFor(() => {
              expect(document.activeElement).toBe(getOptionsMenuTrigger())
            })
          })
        })
      })

      describe('"Integration ID" option', () => {
        it('is selected when sorting by integration ID', async () => {
          props.sortBySetting.settingKey = 'integration_id'
          await mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by integration ID', async () => {
          props.sortBySetting.settingKey = 'login_id'
          await mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', async () => {
          props.sortBySetting.isSortColumn = false
          await mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', async () => {
          props.sortBySetting.disabled = true
          await mountAndOpenOptionsMenu()
          expect(getSortByIntegrationIdOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortByIntegrationId = vi.fn()
          })

          it('calls the .sortBySetting.onSortByIntegrationId callback', async () => {
            await mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().click()
            expect(props.sortBySetting.onSortByIntegrationId).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', async () => {
            await mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().focus()
            getSortByIntegrationIdOption().click()
            await waitFor(() => {
              expect(document.activeElement).toBe(getOptionsMenuTrigger())
            })
          })
        })
      })

      describe('"Login ID" option', () => {
        it('is selected when sorting by login ID', async () => {
          props.sortBySetting.settingKey = 'login_id'
          await mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting by login ID', async () => {
          props.sortBySetting.settingKey = 'sortable_name'
          await mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', async () => {
          props.sortBySetting.isSortColumn = false
          await mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', async () => {
          props.sortBySetting.disabled = true
          await mountAndOpenOptionsMenu()
          expect(getSortByLoginIdOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortByLoginId = vi.fn()
          })

          it('calls the .sortBySetting.onSortByLoginId callback', async () => {
            await mountAndOpenOptionsMenu()
            getSortByLoginIdOption().click()
            expect(props.sortBySetting.onSortByLoginId).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', async () => {
            await mountAndOpenOptionsMenu()
            getSortByLoginIdOption().focus()
            getSortByLoginIdOption().click()
            await waitFor(() => {
              expect(document.activeElement).toBe(getOptionsMenuTrigger())
            })
          })
        })
      })
    })

    describe('"Order" menu group', () => {
      describe('"A–Z" option', () => {
        it('is selected when sorting in ascending order', async () => {
          props.sortBySetting.direction = 'ascending'
          await mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting in ascending order', async () => {
          props.sortBySetting.direction = 'descending'
          await mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', async () => {
          props.sortBySetting.isSortColumn = false
          await mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', async () => {
          props.sortBySetting.disabled = true
          await mountAndOpenOptionsMenu()
          expect(getAscendingSortOrderOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortInAscendingOrder = vi.fn()
          })

          it('calls the .sortBySetting.onSortInAscendingOrder callback', async () => {
            await mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().click()
            expect(props.sortBySetting.onSortInAscendingOrder).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', async () => {
            await mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().focus()
            getAscendingSortOrderOption().click()
            await waitFor(() => {
              expect(document.activeElement).toBe(getOptionsMenuTrigger())
            })
          })
        })
      })

      describe('"Z–A" option', () => {
        it('is selected when sorting in descending order', async () => {
          props.sortBySetting.direction = 'descending'
          await mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-checked')).toBe('true')
        })

        it('is not selected when not sorting in descending order', async () => {
          props.sortBySetting.direction = 'ascending'
          await mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is not selected when isSortColumn is false', async () => {
          props.sortBySetting.isSortColumn = false
          await mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-checked')).toBe('false')
        })

        it('is optionally disabled', async () => {
          props.sortBySetting.disabled = true
          await mountAndOpenOptionsMenu()
          expect(getDescendingSortOrderOption().getAttribute('aria-disabled')).toBe('true')
        })

        describe('when clicked', () => {
          beforeEach(() => {
            props.sortBySetting.onSortInDescendingOrder = vi.fn()
          })

          it('calls the .sortBySetting.onSortInDescendingOrder callback', async () => {
            await mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().click()
            expect(props.sortBySetting.onSortInDescendingOrder).toHaveBeenCalledTimes(1)
          })

          it('returns focus to the "Options" menu trigger', async () => {
            await mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().focus()
            getDescendingSortOrderOption().click()
            await waitFor(() => {
              expect(document.activeElement).toBe(getOptionsMenuTrigger())
            })
          })
        })
      })
    })
  })
})
