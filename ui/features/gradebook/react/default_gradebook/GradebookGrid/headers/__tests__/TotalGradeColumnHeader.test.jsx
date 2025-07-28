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

import TotalGradeColumnHeader from '../TotalGradeColumnHeader'
import {blurElement, getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid TotalGradeColumnHeader', () => {
  let container
  let menuContent
  let component
  let gradebookElements
  let props

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))

    gradebookElements = []
    props = {
      addGradebookElement($el) {
        gradebookElements.push($el)
      },

      gradeDisplay: {
        currentDisplay: 'points',
        disabled: false,
        hidden: false,
        onSelect: jest.fn(),
      },

      onMenuDismiss: jest.fn(),

      position: {
        isInBack: false,
        isInFront: false,
        onMoveToBack: jest.fn(),
        onMoveToFront: jest.fn(),
      },

      removeGradebookElement($el) {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
      },

      showMessageStudentsWithObserversDialog: true,

      getAllStudents: jest.fn(),

      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByGradeAscending: jest.fn(),
        onSortByGradeDescending: jest.fn(),
        settingKey: 'grade',
      },

      isRunningScoreToUngraded: false,

      viewUngradedAsZero: false,

      pointsBasedGradingScheme: false,
    }
  })

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(container)
    container.remove()
  })

  function mountComponent(overrides) {
    // eslint-disable-next-line react/no-render-return-value
    component = ReactDOM.render(<TotalGradeColumnHeader {...props} {...overrides} />, container)
  }

  function getOptionsMenuTrigger() {
    return [...container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Total Options',
    )
  }

  function getOptionsMenuContent() {
    const $button = getOptionsMenuTrigger()
    return document.querySelector(`[aria-labelledby="${$button.id}"]`)
  }

  function openOptionsMenu() {
    getOptionsMenuTrigger().click()
    menuContent = getOptionsMenuContent()
  }

  function mountAndOpenOptionsMenu(overrides = {}) {
    mountComponent(overrides)
    openOptionsMenu()
  }

  function closeOptionsMenu() {
    getOptionsMenuTrigger().click()
  }

  it('displays "Total" as the column title', () => {
    mountComponent()
    expect(container.textContent).toContain('Total')
  })

  describe('secondary details', () => {
    function getSecondaryDetail() {
      return container.querySelector('.Gradebook__ColumnHeaderDetailLine:nth-child(2)')
    }

    it('displays "Ungraded as 0" when view ungraded as 0 is selected', () => {
      props.viewUngradedAsZero = true
      mountComponent()
      expect(getSecondaryDetail().textContent).toBe('Ungraded as 0')
    })

    it('are not present when not viewing ungraded as 0', () => {
      mountComponent()
      expect(getSecondaryDetail()).toBeNull()
    })
  })

  describe('"Options" menu trigger', () => {
    it('is labeled with "Total Options"', () => {
      mountComponent()
      const trigger = getOptionsMenuTrigger()
      expect(trigger.textContent).toContain('Total Options')
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
        expect(gradebookElements.indexOf(menuContent)).not.toBe(-1)
      })

      it('adds the "menuShown" class to the action container', () => {
        const actionContainer = container.querySelector('.Gradebook__ColumnHeaderAction')
        expect(actionContainer.classList.contains('menuShown')).toBe(true)
      })
    })

    describe('when closed', () => {
      beforeEach(() => {
        props.onMenuDismiss.mockClear()
        mountAndOpenOptionsMenu()
        closeOptionsMenu()
      })

      it('is removed as a Gradebook element', () => {
        expect(gradebookElements.indexOf(menuContent)).toBe(-1)
      })

      it('calls the onMenuDismiss callback', () => {
        expect(props.onMenuDismiss).toHaveBeenCalledTimes(1)
      })

      it('removes the "menuShown" class from the action container', () => {
        const actionContainer = container.querySelector('.Gradebook__ColumnHeaderAction')
        expect(actionContainer.classList.contains('menuShown')).toBe(false)
      })
    })
  })

  describe('"Options" > "Sort by" setting', () => {
    function getSortByOption(label) {
      return getMenuItem(menuContent, 'Sort by', label)
    }

    it('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const sortByMenuContent = getMenuContent(menuContent, 'Sort by')
      expect(gradebookElements.indexOf(sortByMenuContent)).not.toBe(-1)
    })

    it('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const sortByMenuContent = getMenuContent(menuContent, 'Sort by')
      closeOptionsMenu()
      expect(gradebookElements.indexOf(sortByMenuContent)).toBe(-1)
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
          props.sortBySetting.onSortByGradeAscending.mockClear()
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

        it.skip('does not call the .sortBySetting.onSortByGradeAscending callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').click()
          expect(props.sortBySetting.onSortByGradeAscending).not.toHaveBeenCalled()
        })
      })
    })

    describe('"Options" > "Message Students Who" action', () => {
      it('is present when "showMessageStudentsWithObserversDialog" is true', () => {
        mountAndOpenOptionsMenu()
        expect(getMenuItem(menuContent, 'Message Students Who')).toBeTruthy()
      })

      it('is not present when "showMessageStudentsWithObserversDialog" is false', () => {
        mountAndOpenOptionsMenu({showMessageStudentsWithObserversDialog: false})
        expect(getMenuItem(menuContent, 'Message Students Who')).toBeFalsy()
      })

      describe('when clicked', () => {
        it('does not restore focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getMenuItem(menuContent, 'Message Students Who').click()
          expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
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
          props.sortBySetting.onSortByGradeDescending.mockClear()
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

  describe('"Options" > "Display as Percentage" action', () => {
    beforeEach(() => {
      props.gradeDisplay.currentDisplay = 'points'
    })

    it('is present when the total grade is being displayed as points', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Display as Percentage')).toBeTruthy()
    })

    it('is not present when the total grade is being displayed as a percentage', () => {
      props.gradeDisplay.currentDisplay = 'percentage'
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Display as Percentage')).toBeFalsy()
    })

    it('is not present when the total grade display cannot be changed', () => {
      props.gradeDisplay.hidden = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Display as Percentage')).toBeFalsy()
    })

    it('is disabled when .gradeDisplay.disabled is true', () => {
      props.gradeDisplay.disabled = true
      mountAndOpenOptionsMenu()
      const menuItem = getMenuItem(menuContent, 'Display as Percentage')
      expect(menuItem.getAttribute('aria-disabled')).toBe('true')
    })

    it('is not disabled when .gradeDisplay.disabled is false', () => {
      props.gradeDisplay.disabled = false
      mountAndOpenOptionsMenu()
      const menuItem = getMenuItem(menuContent, 'Display as Percentage')
      expect(menuItem.getAttribute('aria-disabled')).toBeNull()
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.gradeDisplay.onSelect.mockClear()
      })

      it('does not immediately restore focus', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Display as Percentage').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      it('calls the .gradeDisplay.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Display as Percentage').click()
        expect(props.gradeDisplay.onSelect).toHaveBeenCalledTimes(1)
      })

      it('includes a focus-restoring callback when calling .gradeDisplay.onSelect', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Display as Percentage').click()
        const [callback] =
          props.gradeDisplay.onSelect.mock.calls[props.gradeDisplay.onSelect.mock.calls.length - 1]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Options" > "Display as Points" action', () => {
    beforeEach(() => {
      props.gradeDisplay.currentDisplay = 'percentage'
    })

    it('is present when the total grade is being displayed as percentage', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Display as Points')).toBeTruthy()
    })

    it('is not present when the total grade is being displayed as points', () => {
      props.gradeDisplay.currentDisplay = 'points'
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Display as Points')).toBeFalsy()
    })

    it('is not present when the total grade display cannot be changed', () => {
      props.gradeDisplay.hidden = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Display as Points')).toBeFalsy()
    })

    it('is disabled when .gradeDisplay.disabled is true', () => {
      props.gradeDisplay.disabled = true
      mountAndOpenOptionsMenu()
      const menuItem = getMenuItem(menuContent, 'Display as Points')
      expect(menuItem.getAttribute('aria-disabled')).toBe('true')
    })

    it('is not disabled when .gradeDisplay.disabled is false', () => {
      props.gradeDisplay.disabled = false
      mountAndOpenOptionsMenu()
      const menuItem = getMenuItem(menuContent, 'Display as Points')
      expect(menuItem.getAttribute('aria-disabled')).toBeNull()
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.gradeDisplay.onSelect.mockClear()
      })

      it('does not immediately restore focus', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Display as Points').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      it('calls the .gradeDisplay.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Display as Points').click()
        expect(props.gradeDisplay.onSelect).toHaveBeenCalledTimes(1)
      })

      it('includes a focus-restoring callback when calling .gradeDisplay.onSelect', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Display as Points').click()
        const [callback] =
          props.gradeDisplay.onSelect.mock.calls[props.gradeDisplay.onSelect.mock.calls.length - 1]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Options" > "Move to Front" action', () => {
    beforeEach(() => {
      props.position.isInFront = false
    })

    it('is present when the column is in the scrollable section', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Move to Front')).toBeTruthy()
    })

    it('is not present when the column is in the frozen section', () => {
      props.position.isInFront = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Move to Front')).toBeFalsy()
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.position.onMoveToFront.mockClear()
      })

      it('restores focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Move to Front').click()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })

      it('calls the .position.onMoveToFront callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Move to Front').click()
        expect(props.position.onMoveToFront).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('"Options" > "Move to End" action', () => {
    beforeEach(() => {
      props.position.isInBack = false
    })

    it('is present when the column is in the scrollable section', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Move to End')).toBeTruthy()
    })

    it('is not present when the column is in the frozen section', () => {
      props.position.isInBack = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Move to End')).toBeFalsy()
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.position.onMoveToBack.mockClear()
      })

      it('restores focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Move to End').click()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })

      it('calls the .position.onMoveToBack callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem(menuContent, 'Move to End').click()
        expect(props.position.onMoveToBack).toHaveBeenCalledTimes(1)
      })
    })
  })

  describe('"Apply Score to Ungraded" menu item', () => {
    const applyScoreToUngradedItem = (opts = {showAlternativeText: false}) => {
      return getMenuItem(
        menuContent,
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
      expect(
        applyScoreToUngradedItem({showAlternativeText: true}).getAttribute('aria-disabled'),
      ).toBe('true')
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
        expect(component.state.menuShown).toBe(true)
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
      expect(container.firstChild.classList.contains('focused')).toBe(true)
    })

    it('removes the "focused" class from the header when focus leaves', () => {
      getOptionsMenuTrigger().focus()
      blurElement(getOptionsMenuTrigger())
      expect(container.firstChild.classList.contains('focused')).toBe(false)
    })
  })
})
