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

import AssignmentGroupColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/AssignmentGroupColumnHeader'
import {blurElement, getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid AssignmentGroupColumnHeader', suiteHooks => {
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

      assignmentGroup: {
        groupWeight: 35.5,
        name: 'Homework'
      },

      onMenuDismiss() {},

      removeGradebookElement($el) {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
      },

      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByGradeAscending() {},
        onSortByGradeDescending() {},
        settingKey: 'grade'
      },

      weightedGroups: true
    }
  })

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    component = ReactDOM.render(<AssignmentGroupColumnHeader {...props} />, $container)
  }

  function getOptionsMenuTrigger() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Homework Options'
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

  test('displays the assignment group name', () => {
    mountComponent()
    ok($container.textContent.includes('Homework'))
  })

  QUnit.module('secondary details', () => {
    function getSecondaryDetail() {
      return $container.querySelector('.Gradebook__ColumnHeaderDetailLine:nth-child(2)')
    }

    test('displays the group weight as a percentage when groups are weighted', () => {
      mountComponent()
      equal(getSecondaryDetail().textContent, '35.5% of grade')
    })

    test('displays "0%" when group weight is zero', () => {
      props.assignmentGroup.groupWeight = 0
      mountComponent()
      equal(getSecondaryDetail().textContent, '0% of grade')
    })

    test('are not present when groups are not weighted', () => {
      props.weightedGroups = false
      mountComponent()
      strictEqual(getSecondaryDetail(), null)
    })
  })

  QUnit.module('"Options" menu trigger', () => {
    test('is labeled with the assignment group name', () => {
      mountComponent()
      const $trigger = getOptionsMenuTrigger()
      ok($trigger.textContent.includes('Homework Options'))
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

  QUnit.module('"Options" menu', () => {
    QUnit.module('when opened', contextHooks => {
      contextHooks.beforeEach(() => {
        mountAndOpenOptionsMenu()
      })

      test('is added as a Gradebook element', () => {
        notEqual(gradebookElements.indexOf($menuContent), -1)
      })

      test('adds the "menuShown" class to the action container', () => {
        const $actionContainer = $container.querySelector('.Gradebook__ColumnHeaderAction')
        ok($actionContainer.classList.contains('menuShown'))
      })
    })

    QUnit.module('when closed', contextHooks => {
      contextHooks.beforeEach(() => {
        props.onMenuDismiss = sinon.stub()
        mountAndOpenOptionsMenu()
        closeOptionsMenu()
      })

      test('is removed as a Gradebook element', () => {
        strictEqual(gradebookElements.indexOf($menuContent), -1)
      })

      test('calls the onMenuDismiss callback', () => {
        strictEqual(props.onMenuDismiss.callCount, 1)
      })

      test('removes the "menuShown" class from the action container', () => {
        const $actionContainer = $container.querySelector('.Gradebook__ColumnHeaderAction')
        notOk($actionContainer.classList.contains('menuShown'))
      })
    })
  })

  QUnit.module('"Options" > "Sort by" setting', () => {
    function getSortByOption(label) {
      return getMenuItem($menuContent, 'Sort by', label)
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

    QUnit.module('"Grade - Low to High" option', () => {
      test('is selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - Low to High').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'descending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - Low to High').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - Low to High').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - Low to High').getAttribute('aria-checked'), 'false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - Low to High').getAttribute('aria-disabled'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.sortBySetting.onSortByGradeAscending = sinon.stub()
        })

        test('calls the .sortBySetting.onSortByGradeAscending callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').click()
          strictEqual(props.sortBySetting.onSortByGradeAscending.callCount, 1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').focus()
          getSortByOption('Grade - Low to High').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .sortBySetting.onSortByGradeAscending callback when already selected',
          () => {
            props.sortBySetting.settingKey = 'grade'
            props.sortBySetting.direction = 'ascending'
            mountAndOpenOptionsMenu()
            getSortByOption('Grade - Low to High').click()
            strictEqual(props.sortBySetting.onSortByGradeAscending.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"Grade - High to Low" option', () => {
      test('is selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'descending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - High to Low').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - High to Low').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - High to Low').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - High to Low').getAttribute('aria-checked'), 'false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Grade - High to Low').getAttribute('aria-disabled'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.sortBySetting.onSortByGradeDescending = sinon.stub()
        })

        test('calls the .sortBySetting.onSortByGradeDescending callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').click()
          strictEqual(props.sortBySetting.onSortByGradeDescending.callCount, 1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').focus()
          getSortByOption('Grade - High to Low').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .sortBySetting.onSortByGradeDescending callback when already selected',
          () => {
            props.sortBySetting.settingKey = 'grade'
            props.sortBySetting.direction = 'ascending'
            mountAndOpenOptionsMenu()
            getSortByOption('Grade - High to Low').click()
            strictEqual(props.sortBySetting.onSortByGradeDescending.callCount, 0)
          }
        )
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
