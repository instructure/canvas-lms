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

import StudentColumnHeader from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/StudentColumnHeader.js'
import studentRowHeaderConstants from 'ui/features/gradebook/react/default_gradebook/constants/studentRowHeaderConstants.js'
import {blurElement, getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

/* eslint-disable qunit/no-identical-names */
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
        settingKey: 'sortable_name'
      },
      studentGroupsEnabled: true
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
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

    test('is added as a Gradebook element when opened', () => {
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

  QUnit.module('"Options" > "Display as" setting', () => {
    function getDisplayAsOption(label) {
      return getMenuItem($menuContent, 'Display as', label)
    }

    test('is added as a Gradebook element when opened', () => {
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

  QUnit.module('"Options" > "Secondary info" setting', () => {
    function getSecondaryInfoOption(label) {
      return getMenuItem($menuContent, 'Secondary info', label)
    }

    test('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Secondary info')
      notEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    test('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Secondary info')
      closeOptionsMenu()
      strictEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    test('is disabled when all options are disabled', () => {
      props.disabled = true
      mountAndOpenOptionsMenu()
      strictEqual(getMenuItem($menuContent, 'Secondary info').getAttribute('aria-disabled'), 'true')
    })

    QUnit.module('"Section" option', () => {
      test('is present when the course is using sections', () => {
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('Section'))
      })

      test('is not present when the course is not using sections', () => {
        props.sectionsEnabled = false
        mountAndOpenOptionsMenu()
        notOk(getSecondaryInfoOption('Section'))
      })

      test('is selected when displaying sections for secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Section').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'sis_id'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Section').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectSecondaryInfo = sinon.stub()
        })

        test('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          strictEqual(props.onSelectSecondaryInfo.callCount, 1)
        })

        test('includes "section" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          const [secondaryInfoType] = props.onSelectSecondaryInfo.lastCall.args
          equal(secondaryInfoType, 'section')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').focus()
          getSecondaryInfoOption('Section').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .onSelectSecondaryInfo callback when already selected',
          () => {
            props.selectedSecondaryInfo = 'section'
            mountAndOpenOptionsMenu()
            getSecondaryInfoOption('Section').click()
            strictEqual(props.onSelectSecondaryInfo.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"Group" option', () => {
      test('is present when the course has student groups', () => {
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('Group'))
      })

      test('is not present when the course has no student groups', () => {
        props.studentGroupsEnabled = false
        mountAndOpenOptionsMenu()
        notOk(getSecondaryInfoOption('Group'))
      })

      test('is selected when displaying student groups for secondary info', () => {
        props.selectedSecondaryInfo = 'group'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Group').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'sis_id'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Group').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectSecondaryInfo = sinon.stub()
        })

        test('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          strictEqual(props.onSelectSecondaryInfo.callCount, 1)
        })

        test('includes "group" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          const [secondaryInfoType] = props.onSelectSecondaryInfo.lastCall.args
          equal(secondaryInfoType, 'group')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').focus()
          getSecondaryInfoOption('Group').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .onSelectSecondaryInfo callback when already selected',
          () => {
            props.selectedSecondaryInfo = 'group'
            mountAndOpenOptionsMenu()
            getSecondaryInfoOption('Group').click()
            strictEqual(props.onSelectSecondaryInfo.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"SIS ID" option', () => {
      test('displays the configured SIS name', () => {
        props.sisName = 'Powerschool'
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('Powerschool'))
      })

      test('displays "SIS ID" when no SIS is configured', () => {
        props.sisName = null
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('SIS ID'))
      })

      test('is selected when displaying SIS ids for secondary info', () => {
        props.selectedSecondaryInfo = 'sis_id'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('SIS ID').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('SIS ID').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectSecondaryInfo = sinon.stub()
        })

        test('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          strictEqual(props.onSelectSecondaryInfo.callCount, 1)
        })

        test('includes "sis_id" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          const [secondaryInfoType] = props.onSelectSecondaryInfo.lastCall.args
          equal(secondaryInfoType, 'sis_id')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').focus()
          getSecondaryInfoOption('SIS ID').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .onSelectSecondaryInfo callback when already selected',
          () => {
            props.selectedSecondaryInfo = 'sis_id'
            mountAndOpenOptionsMenu()
            getSecondaryInfoOption('SIS ID').click()
            strictEqual(props.onSelectSecondaryInfo.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"Integration ID" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('Integration ID'))
      })

      test('is selected when displaying integration ids for secondary info', () => {
        props.selectedSecondaryInfo = 'integration_id'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Integration ID').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Integration ID').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectSecondaryInfo = sinon.stub()
        })

        test('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          strictEqual(props.onSelectSecondaryInfo.callCount, 1)
        })

        test('includes "integration_id" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          const [secondaryInfoType] = props.onSelectSecondaryInfo.lastCall.args
          equal(secondaryInfoType, 'integration_id')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').focus()
          getSecondaryInfoOption('Integration ID').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .onSelectSecondaryInfo callback when already selected',
          () => {
            props.selectedSecondaryInfo = 'integration_id'
            mountAndOpenOptionsMenu()
            getSecondaryInfoOption('Integration ID').click()
            strictEqual(props.onSelectSecondaryInfo.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"Login ID" option', () => {
      test('displays the configured login id name', () => {
        props.loginHandleName = 'Email'
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('Email'))
      })

      test('displays "Login ID" when no login id name is configured', () => {
        props.sisName = null
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('Login ID'))
      })

      test('is selected when displaying login ids for secondary info', () => {
        props.selectedSecondaryInfo = 'login_id'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Login ID').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('Login ID').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectSecondaryInfo = sinon.stub()
        })

        test('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          strictEqual(props.onSelectSecondaryInfo.callCount, 1)
        })

        test('includes "login_id" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          const [secondaryInfoType] = props.onSelectSecondaryInfo.lastCall.args
          equal(secondaryInfoType, 'login_id')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').focus()
          getSecondaryInfoOption('Login ID').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .onSelectSecondaryInfo callback when already selected',
          () => {
            props.selectedSecondaryInfo = 'login_id'
            mountAndOpenOptionsMenu()
            getSecondaryInfoOption('Login ID').click()
            strictEqual(props.onSelectSecondaryInfo.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"None" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        ok(getSecondaryInfoOption('None'))
      })

      test('is selected when not displaying secondary info', () => {
        props.selectedSecondaryInfo = 'none'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('None').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when displaying secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        strictEqual(getSecondaryInfoOption('None').getAttribute('aria-checked'), 'false')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.onSelectSecondaryInfo = sinon.stub()
        })

        test('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          strictEqual(props.onSelectSecondaryInfo.callCount, 1)
        })

        test('includes "none" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          const [secondaryInfoType] = props.onSelectSecondaryInfo.lastCall.args
          equal(secondaryInfoType, 'none')
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').focus()
          getSecondaryInfoOption('None').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .onSelectSecondaryInfo callback when already selected',
          () => {
            props.selectedSecondaryInfo = 'none'
            mountAndOpenOptionsMenu()
            getSecondaryInfoOption('None').click()
            strictEqual(props.onSelectSecondaryInfo.callCount, 0)
          }
        )
      })
    })
  })

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
/* eslint-enable qunit/no-identical-names */
