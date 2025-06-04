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

import AssignmentGroupColumnHeader from '../AssignmentGroupColumnHeader'
import {blurElement, getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid AssignmentGroupColumnHeader', () => {
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

      assignmentGroup: {
        groupWeight: 35.5,
        name: 'Homework',
      },

      onMenuDismiss() {},

      removeGradebookElement($el) {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
      },

      showMessageStudentsWithObserversDialog: true,

      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByGradeAscending() {},
        onSortByGradeDescending() {},
        settingKey: 'grade',
      },

      getAllStudents: () => [
        {id: '1', name: 'Student 1'},
        {id: '2', name: 'Student 2'},
      ],

      isRunningScoreToUngraded: false,

      userId: '123',
      courseId: '1',

      pointsBasedGradingScheme: true,
      viewUngradedAsZero: false,
      weightedGroups: true,
    }
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent(overrides) {
    // eslint-disable-next-line react/no-render-return-value
    component = ReactDOM.render(
      <AssignmentGroupColumnHeader {...props} {...overrides} />,
      $container,
    )
  }

  function getOptionsMenuTrigger() {
    const buttons = Array.from($container.querySelectorAll('button'))
    return buttons.find(b => b.textContent === 'Homework Options')
  }

  function getOptionsMenuContent() {
    const $button = getOptionsMenuTrigger()
    return document.querySelector(`[aria-labelledby="${$button.id}"]`)
  }

  function openOptionsMenu() {
    getOptionsMenuTrigger().click()
    $menuContent = getOptionsMenuContent()
  }

  function mountAndOpenOptionsMenu(overrides = {}) {
    mountComponent(overrides)
    openOptionsMenu()
  }

  function closeOptionsMenu() {
    getOptionsMenuTrigger().click()
  }

  it('displays the assignment group name', () => {
    mountComponent()
    expect($container.textContent.includes('Homework')).toBeTruthy()
  })

  describe('secondary details', () => {
    function getSecondaryDetail() {
      return $container.querySelector('.Gradebook__ColumnHeaderDetailLine:nth-child(2)')
    }

    it('displays the group weight as a percentage when groups are weighted', () => {
      mountComponent()
      expect(getSecondaryDetail().textContent).toBe('35.5% of grade')
    })

    it('displays the group weight and "Ungraded as 0" when both apply', () => {
      props.viewUngradedAsZero = true
      mountComponent()
      expect(getSecondaryDetail().textContent).toBe('35.5% of grade/Ungraded as 0')
    })

    it('displays "0%" when group weight is zero', () => {
      props.assignmentGroup.groupWeight = 0
      mountComponent()
      expect(getSecondaryDetail().textContent).toBe('0% of grade')
    })

    it('displays "Ungraded as 0" when view ungraded as 0 is selected', () => {
      props.viewUngradedAsZero = true
      props.weightedGroups = false
      mountComponent()
      expect(getSecondaryDetail().textContent).toBe('Ungraded as 0')
    })

    it('are not present when groups are not weighted and not viewing ungraded as 0', () => {
      props.weightedGroups = false
      mountComponent()
      expect(getSecondaryDetail()).toBeNull()
    })
  })

  describe('"Options" menu trigger', () => {
    it('is labeled with the assignment group name', () => {
      mountComponent()
      const $trigger = getOptionsMenuTrigger()
      expect($trigger.textContent.includes('Homework Options')).toBeTruthy()
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

  describe('"Options" menu', () => {
    describe('when opened', () => {
      beforeEach(() => {
        mountAndOpenOptionsMenu()
      })

      it('is added as a Gradebook element', () => {
        expect(gradebookElements.indexOf($menuContent)).not.toBe(-1)
      })

      it('adds the "menuShown" class to the action container', () => {
        const $actionContainer = $container.querySelector('.Gradebook__ColumnHeaderAction')
        expect($actionContainer.classList.contains('menuShown')).toBe(true)
      })
    })

    describe('when closed', () => {
      beforeEach(() => {
        props.onMenuDismiss = jest.fn()
        mountAndOpenOptionsMenu()
        closeOptionsMenu()
      })

      it('is removed as a Gradebook element', () => {
        expect(gradebookElements.indexOf($menuContent)).toBe(-1)
      })

      it('calls the onMenuDismiss callback', () => {
        expect(props.onMenuDismiss).toHaveBeenCalledTimes(1)
      })

      it('removes the "menuShown" class from the action container', () => {
        const $actionContainer = $container.querySelector('.Gradebook__ColumnHeaderAction')
        expect($actionContainer.classList.contains('menuShown')).toBe(false)
      })
    })
  })

  describe('"Options" > "Sort by" setting', () => {
    function getSortByOption(label) {
      return getMenuItem($menuContent, 'Sort by', label)
    }

    it('is added as a Gradebook element when opened', () => {
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

    describe('"Grade - Low to High" option', () => {
      it('is selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'descending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false')
      })

      it('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false')
      })

      it('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false')
      })

      it('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-disabled')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByGradeAscending = jest.fn()
        })

        it('calls the .sortBySetting.onSortByGradeAscending callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').click()
          expect(props.sortBySetting.onSortByGradeAscending).toHaveBeenCalledTimes(1)
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').focus()
          getSortByOption('Grade - Low to High').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .sortBySetting.onSortByGradeAscending callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').focus()
          expect(props.sortBySetting.onSortByGradeAscending).not.toHaveBeenCalled()
        })
      })
    })

    describe('"Grade - High to Low" option', () => {
      it('is selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'descending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false')
      })

      it('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false')
      })

      it('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false')
      })

      it('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-disabled')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByGradeDescending = jest.fn()
        })

        it('calls the .sortBySetting.onSortByGradeDescending callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').click()
          expect(props.sortBySetting.onSortByGradeDescending).toHaveBeenCalledTimes(1)
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').focus()
          getSortByOption('Grade - High to Low').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .sortBySetting.onSortByGradeDescending callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').click()
          expect(props.sortBySetting.onSortByGradeDescending).not.toHaveBeenCalled()
        })
      })
    })
  })

  describe('"Options" > "Message Students Who" action', () => {
    it('is present when "showMessageStudentsWithObserversDialog" is true', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem($menuContent, 'Message Students Who')).toBeTruthy()
    })

    it('is not present when "showMessageStudentsWithObserversDialog" is false', () => {
      mountAndOpenOptionsMenu({showMessageStudentsWithObserversDialog: false})
      expect(getMenuItem($menuContent, 'Message Students Who')).toBeFalsy()
    })

    describe('when clicked', () => {
      it('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Apply Score to Ungraded" menu item', () => {
    const applyScoreToUngradedItem = (opts = {showAlternativeText: false}) => {
      return getMenuItem(
        $menuContent,
        opts.showAlternativeText ? 'Applying Score to Ungraded' : 'Apply Score to Ungraded',
      )
    }

    it('is present when the onApplyScoreToUngraded prop is non-null', () => {
      props.onApplyScoreToUngraded = jest.fn()
      mountAndOpenOptionsMenu()

      expect(applyScoreToUngradedItem()).toBeTruthy()
    })

    it('calls the onApplyScoreToUngraded prop when clicked', () => {
      props.onApplyScoreToUngraded = jest.fn()
      mountAndOpenOptionsMenu()

      applyScoreToUngradedItem().click()
      expect(props.onApplyScoreToUngraded).toHaveBeenCalledTimes(1)
    })

    it('is not present when the onApplyScoreToUngraded prop is null', () => {
      mountAndOpenOptionsMenu()
      expect(applyScoreToUngradedItem()).toBeFalsy()
    })

    it('is enabled when isRunningScoreToUngraded is false', () => {
      props.onApplyScoreToUngraded = jest.fn()
      mountAndOpenOptionsMenu()
      expect(applyScoreToUngradedItem().getAttribute('aria-disabled')).toBeNull()
    })

    it('is disabled when isRunningScoreToUngraded is true', () => {
      props.onApplyScoreToUngraded = jest.fn()
      props.isRunningScoreToUngraded = true
      mountAndOpenOptionsMenu()
      const menuItem = applyScoreToUngradedItem({showAlternativeText: true})
      expect(menuItem.getAttribute('aria-disabled')).toBe('true')
    })
  })

  describe('#handleKeyDown()', () => {
    let preventDefault

    beforeEach(() => {
      preventDefault = jest.fn()
      mountComponent()
    })

    function handleKeyDown(which, shiftKey = false) {
      return component.handleKeyDown({which, shiftKey, preventDefault})
    }

    describe('when the "Options" menu trigger has focus', () => {
      beforeEach(() => {
        getOptionsMenuTrigger().focus()
      })

      it('does not handle Tab', () => {
        // This allows Grid Support Navigation to handle navigation.
        const returnValue = handleKeyDown(9, false) // Tab
        expect(typeof returnValue).toBe('undefined')
      })

      it('does not handle Shift+Tab', () => {
        // This allows Grid Support Navigation to handle navigation.
        const returnValue = handleKeyDown(9, true) // Shift+Tab
        expect(typeof returnValue).toBe('undefined')
      })

      it('Enter opens the "Options" menu', () => {
        handleKeyDown(13) // Enter
        expect(getOptionsMenuContent()).toBeTruthy()
      })

      it('returns false for Enter', () => {
        // This prevents additional behavior in Grid Support Navigation.
        const returnValue = handleKeyDown(13) // Enter
        expect(returnValue).toBe(false)
      })
    })

    describe('when the header does not have focus', () => {
      it('does not handle Tab', () => {
        const returnValue = handleKeyDown(9, false) // Tab
        expect(typeof returnValue).toBe('undefined')
      })

      it('does not handle Shift+Tab', () => {
        const returnValue = handleKeyDown(9, true) // Shift+Tab
        expect(typeof returnValue).toBe('undefined')
      })

      it('does not handle Enter', () => {
        const returnValue = handleKeyDown(13) // Enter
        expect(typeof returnValue).toBe('undefined')
      })
    })
  })

  describe('focus', () => {
    beforeEach(() => {
      mountComponent()
    })

    it('#focusAtStart() sets focus on the "Options" menu trigger', () => {
      component.focusAtStart()
      expect(document.activeElement).toBe(getOptionsMenuTrigger())
    })

    it('#focusAtEnd() sets focus on the "Options" menu trigger', () => {
      component.focusAtEnd()
      expect(document.activeElement).toBe(getOptionsMenuTrigger())
    })

    it('adds the "focused" class to the header when the "Options" menu trigger receives focus', () => {
      getOptionsMenuTrigger().focus()
      expect($container.firstChild.classList.contains('focused')).toBe(true)
    })

    it('removes the "focused" class from the header when focus leaves', () => {
      getOptionsMenuTrigger().focus()
      blurElement(getOptionsMenuTrigger())
      expect($container.firstChild.classList.contains('focused')).toBe(false)
    })
  })
})
