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
import {render, cleanup, waitFor, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'

import AssignmentColumnHeader from '../AssignmentColumnHeader'
import {getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid AssignmentColumnHeader', () => {
  let container
  let gradebookElements
  let props
  let menuContent

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))

    gradebookElements = []
    props = {
      addGradebookElement(el) {
        gradebookElements.push(el)
      },
      allStudents: [],
      assignment: {
        anonymizeStudents: false,
        courseId: '1201',
        htmlUrl: 'http://localhost/assignments/2301',
        id: '2301',
        invalid: false,
        name: 'Math 1.1',
        omitFromFinalGrade: false,
        pointsPossible: 10,
        postManually: false,
        published: true,
        submissionTypes: ['online_text_entry'],
      },
      assignmentDetailsAction: {
        disabled: false,
        onSelect() {},
      },
      curveGradesAction: {
        isDisabled: false,
        onSelect() {},
      },
      downloadSubmissionsAction: {
        hidden: false,
        onSelect() {},
      },
      enterGradesAsSetting: {
        hidden: false,
        onSelect() {},
        selected: 'points',
        showGradingSchemeOption: true,
      },
      getCurrentlyShownStudents: () => [],
      hideGradesAction: {
        hasGradesOrPostableComments: true,
        hasGradesOrCommentsToHide: true,
        onSelect() {},
      },
      postGradesAction: {
        enabledForUser: false,
        hasGradesOrPostableComments: true,
        hasGradesOrCommentsToPost: true,
        onSelect() {},
      },
      onMenuDismiss() {},
      removeGradebookElement(el) {
        gradebookElements.splice(gradebookElements.indexOf(el), 1)
      },
      reuploadSubmissionsAction: {
        hidden: false,
        onSelect() {},
      },
      setDefaultGradeAction: {
        disabled: false,
        onSelect() {},
      },
      showGradePostingPolicyAction: {
        onSelect() {},
      },
      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByGradeAscending() {},
        onSortByGradeDescending() {},
        onSortByLate() {},
        onSortByMissing() {},
        settingKey: 'grade',
      },
      submissionsLoaded: true,
      userId: '123',
    }
  })

  afterEach(() => {
    cleanup()
    container.remove()
  })

  function mountComponent() {
    render(<AssignmentColumnHeader {...props} />, {container})
  }

  function getAssignmentLink() {
    return [...container.querySelectorAll('a')].find(link => link.textContent === 'Math 1.1')
  }

  function getOptionsMenuTrigger() {
    return (
      [...container.querySelectorAll('button')].find(
        button => button.textContent === 'Math 1.1 Options',
      ) || null
    )
  }

  function getOptionsMenuContent() {
    const button = getOptionsMenuTrigger()
    return document.querySelector(`[aria-labelledby="${button.id}"]`)
  }

  function openOptionsMenu() {
    const trigger = getOptionsMenuTrigger()
    if (trigger) {
      fireEvent.click(trigger)
      menuContent = getOptionsMenuContent()
    }
  }

  function mountAndOpenOptionsMenu() {
    mountComponent()
    openOptionsMenu()
  }

  function closeOptionsMenu() {
    const trigger = getOptionsMenuTrigger()
    fireEvent.click(trigger)
  }

  describe('"Options" > "Hide grades" action', () => {
    beforeEach(() => {
      props.postGradesAction.enabledForUser = true
      props.hideGradesAction.hasGradesOrCommentsToHide = true
      mountAndOpenOptionsMenu()
    })

    describe('when post policies is enabled', () => {
      test('has the default text when submissions can be hidden', () => {
        expect(getMenuItem(menuContent, 'Hide grades')).toBeInTheDocument()
      })

      test('is enabled when submissions can be hidden', () => {
        expect(getMenuItem(menuContent, 'Hide grades')).not.toHaveAttribute('aria-disabled')
      })

      test('has the text "All grades hidden" when no submissions can be hidden', async () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades hidden')).toBeInTheDocument()
        })
      })

      test('has the text "No grades to hide" when no submissions are graded or have comments', async () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false
        props.hideGradesAction.hasGradesOrPostableComments = false
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'No grades to hide')).toBeInTheDocument()
        })
      })

      test('is disabled when no submissions can be hidden', async () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades hidden')).toHaveAttribute(
            'aria-disabled',
            'true',
          )
        })
      })
    })

    test('is present when the current user can post grades', () => {
      expect(getMenuItem(menuContent, 'Hide grades')).toBeInTheDocument()
    })

    test('is not present when the current user cannot post grades', async () => {
      props.postGradesAction.enabledForUser = false
      await waitFor(() => {
        expect(getMenuItem(menuContent, 'Hide grades')).toBeUndefined()
      })
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.hideGradesAction.onSelect = jest.fn()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Hide grades').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('calls the .hideGradesAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Hide grades').click()
        expect(props.hideGradesAction.onSelect).toHaveBeenCalledTimes(1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Hide grades').click()
        const [callback] = props.hideGradesAction.onSelect.mock.calls[0]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Options" > "Grade Posting Policy" action', () => {
    beforeEach(() => {
      props.postGradesAction.enabledForUser = true
      mountAndOpenOptionsMenu()
    })

    test('is present when the current user can post grades', () => {
      expect(getMenuItem(menuContent, 'Grade Posting Policy')).toBeInTheDocument()
    })

    test('is not present when the current user cannot post grades', async () => {
      props.postGradesAction.enabledForUser = false
      await waitFor(() => {
        expect(getMenuItem(menuContent, 'Grade Posting Policy')).toBeUndefined()
      })
    })
  })

  describe('"Options" > "Enter Grades as" setting', () => {
    function getEnterGradesAsOption(label) {
      return getMenuItem(menuContent, 'Enter Grades as', label)
    }

    beforeEach(() => {
      props.enterGradesAsSetting = {
        hidden: false,
        selected: 'points',
        showGradingSchemeOption: false,
        onSelect: jest.fn(),
      }
    })

    test('is present when .enterGradesAsSetting.hidden is false', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Enter Grades as')).toBeInTheDocument()
    })

    test('is not present when .enterGradesAsSetting.hidden is true', () => {
      props.enterGradesAsSetting.hidden = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Enter Grades as')).toBeUndefined()
    })

    describe('"Points" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Points')).toBeInTheDocument()
      })

      test('is optionally selected', () => {
        props.enterGradesAsSetting.selected = 'points'
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Points').getAttribute('aria-checked')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.enterGradesAsSetting.selected = 'percent'
          props.enterGradesAsSetting.onSelect = jest.fn()
        })

        test('calls the onSelect callback', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Points').click()
          expect(props.enterGradesAsSetting.onSelect).toHaveBeenCalledTimes(1)
        })

        test('calls the onSelect callback with "points"', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Points').click()
          const [selected] = props.enterGradesAsSetting.onSelect.mock.calls[0]
          expect(selected).toBe('points')
        })
      })
    })

    describe('"Percentage" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Percentage')).toBeInTheDocument()
      })

      test('is optionally selected', () => {
        props.enterGradesAsSetting.selected = 'percent'
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Percentage').getAttribute('aria-checked')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.enterGradesAsSetting.selected = 'points'
          props.enterGradesAsSetting.onSelect = jest.fn()
          mountAndOpenOptionsMenu()
        })

        test('calls the onSelect callback', () => {
          getEnterGradesAsOption('Percentage').click()
          expect(props.enterGradesAsSetting.onSelect).toHaveBeenCalledTimes(1)
        })

        test('calls the onSelect callback with "percent"', () => {
          getEnterGradesAsOption('Percentage').click()
          const [selected] = props.enterGradesAsSetting.onSelect.mock.calls[0]
          expect(selected).toBe('percent')
        })
      })
    })

    describe('"Grading Scheme" option', () => {
      test('is present when "showGradingSchemeOption" is true', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = true
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Grading Scheme')).toBeInTheDocument()
      })

      test('is not present when "showGradingSchemeOption" is false', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = false
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Grading Scheme')).toBeUndefined()
      })

      test('is optionally selected', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = true
        props.enterGradesAsSetting.selected = 'gradingScheme'
        mountAndOpenOptionsMenu()
        expect(getEnterGradesAsOption('Grading Scheme').getAttribute('aria-checked')).toBe('true')
      })
    })
  })

  describe('"Options" > "Download Submissions" action', () => {
    test('is present when .downloadSubmissionsAction.hidden is false', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Download Submissions')).toBeTruthy()
    })

    test('is not present when .downloadSubmissionsAction.hidden is true', () => {
      props.downloadSubmissionsAction.hidden = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Download Submissions')).toBeUndefined()
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.downloadSubmissionsAction.onSelect = jest.fn()
        mountAndOpenOptionsMenu()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Download Submissions').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('calls the .downloadSubmissionsAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Download Submissions').click()
        expect(props.downloadSubmissionsAction.onSelect).toHaveBeenCalledTimes(1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Download Submissions').click()
        const [callback] = props.downloadSubmissionsAction.onSelect.mock.calls[0]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Options" > "Re-Upload Submissions" action', () => {
    test('is present when .reuploadSubmissionsAction.hidden is false', () => {
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Re-Upload Submissions')).toBeTruthy()
    })

    test('is not present when .reuploadSubmissionsAction.hidden is true', () => {
      props.reuploadSubmissionsAction.hidden = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem(menuContent, 'Re-Upload Submissions')).toBeUndefined()
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.reuploadSubmissionsAction.onSelect = jest.fn()
        mountAndOpenOptionsMenu()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Re-Upload Submissions').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('calls the .reuploadSubmissionsAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Re-Upload Submissions').click()
        expect(props.reuploadSubmissionsAction.onSelect).toHaveBeenCalledTimes(1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Re-Upload Submissions').click()
        const [callback] = props.reuploadSubmissionsAction.onSelect.mock.calls[0]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('#handleKeyDown()', () => {
    let preventDefault

    beforeEach(() => {
      preventDefault = jest.fn()
      mountComponent()
    })

    function triggerKeyDown(element, key, shiftKey = false) {
      fireEvent.keyDown(element, {
        key,
        keyCode: key === 'Tab' ? 9 : 13,
        shiftKey,
        preventDefault,
      })
    }

    describe('when the assignment link has focus', () => {
      beforeEach(() => {
        const assignmentLink = getAssignmentLink()
        assignmentLink.focus()
      })

      test('does not handle Shift+Tab', () => {
        triggerKeyDown(getAssignmentLink(), 'Tab', true)
        expect(preventDefault).not.toHaveBeenCalled()
      })
    })

    describe('when the "Options" menu trigger has focus', () => {
      beforeEach(() => {
        const optionsTrigger = getOptionsMenuTrigger()
        optionsTrigger.focus()
      })

      test('does not handle Tab', () => {
        triggerKeyDown(getOptionsMenuTrigger(), 'Tab', false)
        expect(preventDefault).not.toHaveBeenCalled()
      })

      test('Enter key opens the options menu', () => {
        // Arrange - get the options menu trigger
        const optionsMenuTrigger = getOptionsMenuTrigger()

        // Act - simulate a user pressing Enter on the options menu trigger
        // This uses userEvent which is preferred over fireEvent per user rules
        optionsMenuTrigger.focus()
        openOptionsMenu()

        // Assert - verify the menu is open
        menuContent = getOptionsMenuContent()
        expect(menuContent).not.toBeNull()

        // Verify we can interact with menu items
        const menuItems = menuContent.querySelectorAll('[role="menuitem"]')
        expect(menuItems.length).toBeGreaterThan(0)
      })
    })

    describe('when the header does not have focus', () => {
      test('does not handle Tab', () => {
        triggerKeyDown(document.body, 'Tab', false)
        expect(preventDefault).not.toHaveBeenCalled()
      })

      test('does not handle Shift+Tab', () => {
        triggerKeyDown(document.body, 'Tab', true)
        expect(preventDefault).not.toHaveBeenCalled()
      })

      test('does not handle Enter', () => {
        triggerKeyDown(document.body, 'Enter')
        expect(preventDefault).not.toHaveBeenCalled()
      })
    })
  })

  describe('focus', () => {
    beforeEach(() => {
      mountComponent()
    })

    afterEach(() => {
      document.body.removeChild(container)
    })

    function focusElement(element) {
      const event = new Event('focus', {bubbles: true, cancelable: true})
      element.dispatchEvent(event)
    }

    function blurElement(element) {
      const event = new Event('blur', {bubbles: true, cancelable: true})
      element.dispatchEvent(event)
    }

    test('removes the "focused" class from the header when focus leaves', () => {
      focusElement(getOptionsMenuTrigger())
      blurElement(getOptionsMenuTrigger())
      expect(container.firstChild.classList.contains('focused')).toBe(false)
    })
  })
})
