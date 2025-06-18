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

import AsyncComponents from '../../../AsyncComponents'
import AssignmentColumnHeader from '../AssignmentColumnHeader'
import MessageStudentsWhoDialog from '../../../../shared/MessageStudentsWhoDialog'
import {getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid AssignmentColumnHeader', () => {
  let container
  let component
  let gradebookElements
  let props
  let students
  let menuContent

  beforeEach(() => {
    container = document.body.appendChild(document.createElement('div'))

    students = [
      {
        id: '1001',
        isInactive: false,
        isTestStudent: false,
        name: 'Adam Jones',
        sortableName: 'Jones, Adam',
        submission: {
          excused: false,
          postedAt: null,
          score: 7,
          submittedAt: null,
          workflowState: 'graded',
        },
      },
      {
        id: '1002',
        isInactive: false,
        isTestStudent: false,
        name: 'Betty Ford',
        sortableName: 'Ford, Betty',
        submission: {
          excused: false,
          postedAt: null,
          score: 8,
          submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)'),
          workflowState: 'graded',
        },
      },
      {
        id: '1003',
        isInactive: false,
        isTestStudent: false,
        name: 'Charlie Xi',
        sortableName: 'Xi, Charlie',
        submission: {
          excused: false,
          postedAt: null,
          score: null,
          submittedAt: null,
          workflowState: 'unsubmitted',
        },
      },
    ]

    gradebookElements = []
    props = {
      addGradebookElement(el) {
        gradebookElements.push(el)
      },
      allStudents: [...students],
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
      getCurrentlyShownStudents: () => students.slice(0, 2),
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
    component = render(<AssignmentColumnHeader {...props} />, {container})
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

  describe('"Options" > "Sort by" setting', () => {
    function getSortByOption(label) {
      return getMenuItem(menuContent, 'Sort by', label)
    }

    test('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const sortByMenuContent = getMenuContent(menuContent, 'Sort by')
      expect(gradebookElements.indexOf(sortByMenuContent)).not.toBe(-1)
    })

    test('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const sortByMenuContent = getMenuContent(menuContent, 'Sort by')
      closeOptionsMenu()
      expect(gradebookElements.indexOf(sortByMenuContent)).toBe(-1)
    })

    describe('"Grade - Low to High" option', () => {
      test('is selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('true')
      })

      test('is not selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'descending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-checked')).toBe('false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - Low to High').getAttribute('aria-disabled')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByGradeAscending = jest.fn()
        })

        test('calls the .sortBySetting.onSortByGradeAscending callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').click()
          expect(props.sortBySetting.onSortByGradeAscending).toHaveBeenCalledTimes(1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').focus()
          getSortByOption('Grade - Low to High').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })
      })
    })

    describe('"Grade - High to Low" option', () => {
      test('is selected when sorting by grade descending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'descending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('true')
      })

      test('is not selected when sorting by grade ascending', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-checked')).toBe('false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Grade - High to Low').getAttribute('aria-disabled')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByGradeDescending = jest.fn()
        })

        test('calls the .sortBySetting.onSortByGradeDescending callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').click()
          expect(props.sortBySetting.onSortByGradeDescending).toHaveBeenCalledTimes(1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').focus()
          getSortByOption('Grade - High to Low').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })
      })
    })

    describe('"Missing" option', () => {
      test('is selected when sorting by missing', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Missing').getAttribute('aria-checked')).toBe('true')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Missing').getAttribute('aria-checked')).toBe('false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Missing').getAttribute('aria-checked')).toBe('false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Missing').getAttribute('aria-disabled')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByMissing = jest.fn()
        })

        test('calls the .sortBySetting.onSortByMissing callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Missing').click()
          expect(props.sortBySetting.onSortByMissing).toHaveBeenCalledTimes(1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Missing').focus()
          getSortByOption('Missing').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })
      })
    })

    describe('"Late" option', () => {
      test('is selected when sorting by late', () => {
        props.sortBySetting.settingKey = 'late'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Late').getAttribute('aria-checked')).toBe('true')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Late').getAttribute('aria-checked')).toBe('false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Late').getAttribute('aria-checked')).toBe('false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        expect(getSortByOption('Late').getAttribute('aria-disabled')).toBe('true')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.sortBySetting.onSortByLate = jest.fn()
        })

        test('calls the .sortBySetting.onSortByLate callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Late').click()
          expect(props.sortBySetting.onSortByLate).toHaveBeenCalledTimes(1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Late').focus()
          getSortByOption('Late').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })
      })
    })
  })

  describe('"Options" > "SpeedGrader" action', () => {
    beforeEach(() => {
      mountAndOpenOptionsMenu()
    })

    test('is present', () => {
      const menuItem = getMenuItem(menuContent, 'SpeedGrader')
      expect(menuItem).toBeInTheDocument()
    })

    test('links to SpeedGrader for the current assignment', () => {
      const menuItem = getMenuItem(menuContent, 'SpeedGrader')
      expect(menuItem.href).toContain('/courses/1201/gradebook/speed_grader?assignment_id=2301')
    })
  })

  describe('"Options" > "Message Students Who" action', () => {
    let loadMessageStudentsWhoDialogPromise

    beforeEach(() => {
      loadMessageStudentsWhoDialogPromise = Promise.resolve(MessageStudentsWhoDialog)
      jest
        .spyOn(AsyncComponents, 'loadMessageStudentsWhoDialog')
        .mockReturnValue(loadMessageStudentsWhoDialogPromise)
      jest.spyOn(MessageStudentsWhoDialog, 'show').mockImplementation(() => {})
      mountAndOpenOptionsMenu()
    })

    afterEach(() => {
      jest.restoreAllMocks()
    })

    test('is always present', () => {
      expect(menuContent).not.toBeNull()
      const menuItem = getMenuItem(menuContent, 'Message Students Who')
      expect(menuItem).toBeInTheDocument()
    })

    test('is disabled when anonymizing students', async () => {
      props.assignment.anonymizeStudents = true
      expect(menuContent).not.toBeNull()
      const menuItem = getMenuItem(menuContent, 'Message Students Who')
      await waitFor(() => {
        expect(menuItem).toHaveAttribute('aria-disabled', 'true')
      })
    })

    test('is not disabled when submissions are loaded', () => {
      expect(menuContent).not.toBeNull()
      const menuItem = getMenuItem(menuContent, 'Message Students Who')
      expect(menuItem).not.toHaveAttribute('aria-disabled')
    })

    describe('when clicked', () => {
      test('does not restore focus to the "Options" menu trigger', () => {
        expect(menuContent).not.toBeNull()
        const menuItem = getMenuItem(menuContent, 'Message Students Who')
        fireEvent.click(menuItem)
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('includes a callback for restoring focus upon dialog close', async () => {
        expect(menuContent).not.toBeNull()
        const menuItem = getMenuItem(menuContent, 'Message Students Who')
        fireEvent.click(menuItem)
        await loadMessageStudentsWhoDialogPromise
        const [, onClose] =
          MessageStudentsWhoDialog.show.mock.calls[
            MessageStudentsWhoDialog.show.mock.calls.length - 1
          ]
        onClose()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })

      test('includes non-test students in the "settings" hash', async () => {
        expect(menuContent).not.toBeNull()
        const menuItem = getMenuItem(menuContent, 'Message Students Who')
        fireEvent.click(menuItem)
        await loadMessageStudentsWhoDialogPromise
        const [settings] =
          MessageStudentsWhoDialog.show.mock.calls[
            MessageStudentsWhoDialog.show.mock.calls.length - 1
          ]
        expect(settings.students).toHaveLength(2)
      })

      test('excludes test students from the "settings" hash', async () => {
        students[0].isTestStudent = true
        expect(menuContent).not.toBeNull()
        const menuItem = getMenuItem(menuContent, 'Message Students Who')
        fireEvent.click(menuItem)
        await loadMessageStudentsWhoDialogPromise
        const [settings] =
          MessageStudentsWhoDialog.show.mock.calls[
            MessageStudentsWhoDialog.show.mock.calls.length - 1
          ]
        expect(settings.students.map(student => student.name)).toEqual(['Betty Ford'])
      })
    })
  })

  describe('"Options" > "Curve Grades" action', () => {
    beforeEach(() => {
      mountAndOpenOptionsMenu()
    })

    test('is always present', () => {
      const menuItem = getMenuItem(menuContent, 'Curve Grades')
      expect(menuItem).toBeInTheDocument()
    })

    test('is disabled when .curveGradesAction.isDisabled is true', async () => {
      props.curveGradesAction.isDisabled = true
      const menuItem = getMenuItem(menuContent, 'Curve Grades')
      await waitFor(() => {
        expect(menuItem).toHaveAttribute('aria-disabled', 'true')
      })
    })

    test('is not disabled when .curveGradesAction.isDisabled is false', () => {
      const menuItem = getMenuItem(menuContent, 'Curve Grades')
      expect(menuItem).not.toHaveAttribute('aria-disabled')
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.curveGradesAction.onSelect = jest.fn()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        const menuItem = getMenuItem(menuContent, 'Curve Grades')
        fireEvent.click(menuItem)
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('calls the .curveGradesAction.onSelect callback', () => {
        const menuItem = getMenuItem(menuContent, 'Curve Grades')
        fireEvent.click(menuItem)
        expect(props.curveGradesAction.onSelect).toHaveBeenCalledTimes(1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        const menuItem = getMenuItem(menuContent, 'Curve Grades')
        fireEvent.click(menuItem)
        const [callback] =
          props.curveGradesAction.onSelect.mock.calls[
            props.curveGradesAction.onSelect.mock.calls.length - 1
          ]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Options" > "Set Default Grade" action', () => {
    beforeEach(() => {
      mountAndOpenOptionsMenu()
    })

    test('is always present', () => {
      const menuItem = getMenuItem(menuContent, 'Set Default Grade')
      expect(menuItem).toBeInTheDocument()
    })

    test('is disabled when .setDefaultGradeAction.disabled is true', async () => {
      props.setDefaultGradeAction.disabled = true
      const menuItem = getMenuItem(menuContent, 'Set Default Grade')
      await waitFor(() => {
        expect(menuItem).toHaveAttribute('aria-disabled', 'true')
      })
    })

    test('is not disabled when .setDefaultGradeAction.disabled is false', () => {
      const menuItem = getMenuItem(menuContent, 'Set Default Grade')
      expect(menuItem).not.toHaveAttribute('aria-disabled')
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.setDefaultGradeAction.onSelect = jest.fn()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        const menuItem = getMenuItem(menuContent, 'Set Default Grade')
        fireEvent.click(menuItem)
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('calls the .setDefaultGradeAction.onSelect callback', () => {
        const menuItem = getMenuItem(menuContent, 'Set Default Grade')
        fireEvent.click(menuItem)
        expect(props.setDefaultGradeAction.onSelect).toHaveBeenCalledTimes(1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        const menuItem = getMenuItem(menuContent, 'Set Default Grade')
        fireEvent.click(menuItem)
        const [callback] =
          props.setDefaultGradeAction.onSelect.mock.calls[
            props.setDefaultGradeAction.onSelect.mock.calls.length - 1
          ]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })

  describe('"Options" > "Post grades" action', () => {
    beforeEach(() => {
      props.postGradesAction.enabledForUser = true
      props.postGradesAction.hasGradesOrCommentsToPost = true
      mountAndOpenOptionsMenu()
    })

    describe('when the current user can edit grades', () => {
      test('has the default text when submissions can be posted', () => {
        expect(getMenuItem(menuContent, 'Post grades')).toBeInTheDocument()
      })

      test('is enabled when submissions can be posted', () => {
        expect(getMenuItem(menuContent, 'Post grades')).not.toHaveAttribute('aria-disabled')
      })

      test('has the text "All grades posted" when no submissions can be posted', async () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades posted')).toBeInTheDocument()
        })
      })

      test('has the text "No grades to post" when no submissions are graded or have comments', async () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false
        props.postGradesAction.hasGradesOrPostableComments = false
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'No grades to post')).toBeInTheDocument()
        })
      })

      test('is disabled when no submissions can be posted', async () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false
        await waitFor(() => {
          expect(getMenuItem(menuContent, 'All grades posted')).toHaveAttribute(
            'aria-disabled',
            'true',
          )
        })
      })
    })

    test('does not appear when posting is not enabled for this user', async () => {
      props.postGradesAction.enabledForUser = false
      await waitFor(() => {
        expect(getMenuItem(menuContent, 'Post grades')).toBeUndefined()
      })
    })

    describe('when clicked', () => {
      beforeEach(() => {
        props.postGradesAction.onSelect = jest.fn()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        getMenuItem(menuContent, 'Post grades').click()
        expect(document.activeElement).not.toBe(getOptionsMenuTrigger())
      })

      test('calls the .postGradesAction.onSelect callback', () => {
        getMenuItem(menuContent, 'Post grades').click()
        expect(props.postGradesAction.onSelect).toHaveBeenCalledTimes(1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        getMenuItem(menuContent, 'Post grades').click()
        const [callback] =
          props.postGradesAction.onSelect.mock.calls[
            props.postGradesAction.onSelect.mock.calls.length - 1
          ]
        callback()
        expect(document.activeElement).toBe(getOptionsMenuTrigger())
      })
    })
  })
})
