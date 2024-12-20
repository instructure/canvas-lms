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

  function closeOptionsMenu() {
    getOptionsMenuTrigger().click()
  }

  test('displays "Student Name" as the column title', () => {
    mountComponent()
    ok($container.textContent.includes('Student Name'))
  })

  QUnit.module('"Options" menu trigger', () => {
    test('is labeled with "Student Name Options"', () => {
      mountComponent()
      const $trigger = getOptionsMenuTrigger()
      ok($trigger.textContent.includes('Student Name Options'))
    })

    test('opens the options menu when clicked', () => {
      mountComponent()
      getOptionsMenuTrigger().click()
      ok(getOptionsMenuContent())
    })

    test('closes the options menu when clicked', () => {
      mountAndOpenOptionsMenu()
      getOptionsMenuTrigger().click()
      notOk(getOptionsMenuContent())
    })
  })

  QUnit.module('"Options" > "Sort by" setting', () => {
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

    QUnit.skip('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Sort by')
      notEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    test('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Sort by')
      closeOptionsMenu()
      strictEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    test('is disabled when all options are disabled', () => {
      props.disabled = true
      mountAndOpenOptionsMenu()
      strictEqual(getMenuItem($menuContent, 'Sort by').getAttribute('aria-disabled'), 'true')
    })

    QUnit.module('"Type" menu group', () => {
      QUnit.module('"Name" option', () => {
        test('is selected when sorting by sortable name', () => {
          props.sortBySetting.settingKey = 'sortable_name'
          mountAndOpenOptionsMenu()
          strictEqual(getSortByNameOption().getAttribute('aria-checked'), 'true')
        })

        test('is not selected when not sorting by sortable name', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          strictEqual(getSortByNameOption().getAttribute('aria-checked'), 'false')
        })

        test('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          strictEqual(getSortByNameOption().getAttribute('aria-checked'), 'false')
        })

        test('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          strictEqual(getSortByNameOption().getAttribute('aria-disabled'), 'true')
        })

        QUnit.module('when clicked', contextHooks => {
          contextHooks.beforeEach(() => {
            props.sortBySetting.onSortBySortableName = sinon.stub()
          })

          test('calls the .sortBySetting.onSortBySortableName callback', () => {
            mountAndOpenOptionsMenu()
            getSortByNameOption().click()
            strictEqual(props.sortBySetting.onSortBySortableName.callCount, 1)
          })

          test('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortByNameOption().focus()
            getSortByNameOption().click()
            strictEqual(document.activeElement, getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          QUnit.skip(
            'does not call the .sortBySetting.onSortBySortableName callback when already selected',
            () => {
              props.sortBySetting.settingKey = 'sortable_name'
              mountAndOpenOptionsMenu()
              getSortByNameOption().focus()
              strictEqual(props.sortBySetting.onSortBySortableName.callCount, 0)
            }
          )
        })
      })

      QUnit.module('"SIS ID" option', () => {
        test('is selected when sorting by SIS ID', () => {
          props.sortBySetting.settingKey = 'sis_user_id'
          mountAndOpenOptionsMenu()
          strictEqual(getSortBySisIdOption().getAttribute('aria-checked'), 'true')
        })

        test('is not selected when not sorting by SIS ID', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          strictEqual(getSortBySisIdOption().getAttribute('aria-checked'), 'false')
        })

        test('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          strictEqual(getSortBySisIdOption().getAttribute('aria-checked'), 'false')
        })

        test('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          strictEqual(getSortBySisIdOption().getAttribute('aria-disabled'), 'true')
        })

        QUnit.module('when clicked', contextHooks => {
          contextHooks.beforeEach(() => {
            props.sortBySetting.onSortBySisId = sinon.stub()
          })

          test('calls the .sortBySetting.onSortBySisId callback', () => {
            mountAndOpenOptionsMenu()
            getSortBySisIdOption().click()
            strictEqual(props.sortBySetting.onSortBySisId.callCount, 1)
          })

          test('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortBySisIdOption().focus()
            getSortBySisIdOption().click()
            strictEqual(document.activeElement, getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          QUnit.skip(
            'does not call the .sortBySetting.onSortBySisId callback when already selected',
            () => {
              props.sortBySetting.settingKey = 'sis_user_id'
              mountAndOpenOptionsMenu()
              getSortBySisIdOption().focus()
              strictEqual(props.sortBySetting.onSortBySisId.callCount, 0)
            }
          )
        })
      })

      QUnit.module('"Integration ID" option', () => {
        test('is selected when sorting by integration ID', () => {
          props.sortBySetting.settingKey = 'integration_id'
          mountAndOpenOptionsMenu()
          strictEqual(getSortByIntegrationIdOption().getAttribute('aria-checked'), 'true')
        })

        test('is not selected when not sorting by integration ID', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          strictEqual(getSortByIntegrationIdOption().getAttribute('aria-checked'), 'false')
        })

        test('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          strictEqual(getSortByIntegrationIdOption().getAttribute('aria-checked'), 'false')
        })

        test('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          strictEqual(getSortByIntegrationIdOption().getAttribute('aria-disabled'), 'true')
        })

        QUnit.module('when clicked', contextHooks => {
          contextHooks.beforeEach(() => {
            props.sortBySetting.onSortByIntegrationId = sinon.stub()
          })

          test('calls the .sortBySetting.onSortByIntegrationId callback', () => {
            mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().click()
            strictEqual(props.sortBySetting.onSortByIntegrationId.callCount, 1)
          })

          test('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortByIntegrationIdOption().focus()
            getSortByIntegrationIdOption().click()
            strictEqual(document.activeElement, getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          QUnit.skip(
            'does not call the .sortBySetting.onSortByIntegrationId callback when already selected',
            () => {
              props.sortBySetting.settingKey = 'integration_id'
              mountAndOpenOptionsMenu()
              getSortByIntegrationIdOption().focus()
              strictEqual(props.sortBySetting.onSortByIntegrationId.callCount, 0)
            }
          )
        })
      })

      QUnit.module('"Login ID" option', () => {
        test('is selected when sorting by login ID', () => {
          props.sortBySetting.settingKey = 'login_id'
          mountAndOpenOptionsMenu()
          strictEqual(getSortByLoginIdOption().getAttribute('aria-checked'), 'true')
        })

        test('is not selected when not sorting by login ID', () => {
          props.sortBySetting.settingKey = 'sortable_name'
          mountAndOpenOptionsMenu()
          strictEqual(getSortByLoginIdOption().getAttribute('aria-checked'), 'false')
        })

        test('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          strictEqual(getSortByLoginIdOption().getAttribute('aria-checked'), 'false')
        })

        test('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          strictEqual(getSortByLoginIdOption().getAttribute('aria-disabled'), 'true')
        })

        QUnit.module('when clicked', contextHooks => {
          contextHooks.beforeEach(() => {
            props.sortBySetting.onSortByLoginId = sinon.stub()
          })

          test('calls the .sortBySetting.onSortByLoginId callback', () => {
            mountAndOpenOptionsMenu()
            getSortByLoginIdOption().click()
            strictEqual(props.sortBySetting.onSortByLoginId.callCount, 1)
          })

          test('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getSortByLoginIdOption().focus()
            getSortByLoginIdOption().click()
            strictEqual(document.activeElement, getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          QUnit.skip(
            'does not call the .sortBySetting.onSortByLoginId callback when already selected',
            () => {
              props.sortBySetting.settingKey = 'login_id'
              mountAndOpenOptionsMenu()
              getSortByLoginIdOption().focus()
              strictEqual(props.sortBySetting.onSortByLoginId.callCount, 0)
            }
          )
        })
      })
    })

    QUnit.module('"Order" menu group', () => {
      QUnit.module('"A–Z" option', () => {
        test('is selected when sorting in ascending order', () => {
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          strictEqual(getAscendingSortOrderOption().getAttribute('aria-checked'), 'true')
        })

        test('is not selected when not sorting in ascending order', () => {
          props.sortBySetting.direction = 'descending'
          mountAndOpenOptionsMenu()
          strictEqual(getAscendingSortOrderOption().getAttribute('aria-checked'), 'false')
        })

        test('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          strictEqual(getAscendingSortOrderOption().getAttribute('aria-checked'), 'false')
        })

        test('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          strictEqual(getAscendingSortOrderOption().getAttribute('aria-disabled'), 'true')
        })

        QUnit.module('when clicked', contextHooks => {
          contextHooks.beforeEach(() => {
            props.sortBySetting.onSortInAscendingOrder = sinon.stub()
          })

          test('calls the .sortBySetting.onSortInAscendingOrder callback', () => {
            mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().click()
            strictEqual(props.sortBySetting.onSortInAscendingOrder.callCount, 1)
          })

          test('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getAscendingSortOrderOption().focus()
            getAscendingSortOrderOption().click()
            strictEqual(document.activeElement, getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          QUnit.skip(
            'does not call the .sortBySetting.onSortInAscendingOrder callback when already selected',
            () => {
              props.sortBySetting.direction = 'ascending'
              mountAndOpenOptionsMenu()
              getAscendingSortOrderOption().click()
              strictEqual(props.sortBySetting.onSortBySortableNameAscending.callCount, 0)
            }
          )
        })
      })

      QUnit.module('"Z–A" option', () => {
        test('is selected when sorting in descending order', () => {
          props.sortBySetting.direction = 'descending'
          mountAndOpenOptionsMenu()
          strictEqual(getDescendingSortOrderOption().getAttribute('aria-checked'), 'true')
        })

        test('is not selected when not sorting in descending order', () => {
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          strictEqual(getDescendingSortOrderOption().getAttribute('aria-checked'), 'false')
        })

        test('is not selected when isSortColumn is false', () => {
          props.sortBySetting.isSortColumn = false
          mountAndOpenOptionsMenu()
          strictEqual(getDescendingSortOrderOption().getAttribute('aria-checked'), 'false')
        })

        test('is optionally disabled', () => {
          props.sortBySetting.disabled = true
          mountAndOpenOptionsMenu()
          strictEqual(getDescendingSortOrderOption().getAttribute('aria-disabled'), 'true')
        })

        QUnit.module('when clicked', contextHooks => {
          contextHooks.beforeEach(() => {
            props.sortBySetting.onSortInDescendingOrder = sinon.stub()
          })

          test('calls the .sortBySetting.onSortInDescendingOrder callback', () => {
            mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().click()
            strictEqual(props.sortBySetting.onSortInDescendingOrder.callCount, 1)
          })

          test('returns focus to the "Options" menu trigger', () => {
            mountAndOpenOptionsMenu()
            getDescendingSortOrderOption().focus()
            getDescendingSortOrderOption().click()
            strictEqual(document.activeElement, getOptionsMenuTrigger())
          })

          // TODO: GRADE-____
          QUnit.skip(
            'does not call the .sortBySetting.onSortInDescendingOrder callback when already selected',
            () => {
              props.sortBySetting.direction = 'ascending'
              mountAndOpenOptionsMenu()
              getDescendingSortOrderOption().click()
              strictEqual(props.sortBySetting.onSortBySortableNameDescending.callCount, 0)
            }
          )
        })
      })
    })
  })
})
