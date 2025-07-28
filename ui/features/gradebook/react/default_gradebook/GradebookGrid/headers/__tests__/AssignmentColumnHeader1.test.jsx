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
import {render, cleanup, fireEvent} from '@testing-library/react'
import '@testing-library/jest-dom/extend-expect'

import AssignmentColumnHeader from '../AssignmentColumnHeader'

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

  describe('assignment name', () => {
    beforeEach(mountComponent)

    test('is present as a link', () => {
      expect(getAssignmentLink()).toBeInTheDocument()
    })

    test('links to the assignment url', () => {
      expect(getAssignmentLink()).toHaveAttribute('href', 'http://localhost/assignments/2301')
    })
  })

  describe('header indicators', () => {
    function getColumnHeaderIcon(name = null) {
      const iconSpecifier = name != null ? `svg[name="${name}"]` : 'svg'
      return container.querySelector(`.Gradebook__ColumnHeaderIndicators ${iconSpecifier}`)
    }

    beforeEach(() => {
      props.postGradesAction.enabledForUser = true
    })

    describe('when the assignment is auto-posted', () => {
      test('displays no icon when no submissions are graded but unposted', () => {
        props.allStudents.forEach(student => {
          if (student.submission.score != null) {
            student.submission.postedAt = new Date()
          }
        })

        mountComponent()
        expect(getColumnHeaderIcon()).not.toBeInTheDocument()
      })

      test('displays an "off" icon when submissions are graded but unposted', () => {
        mountComponent()
        expect(getColumnHeaderIcon('IconOff')).toBeInTheDocument()
      })
    })

    describe('when the assignment is manually-posted', () => {
      beforeEach(() => {
        props.assignment.postManually = true
      })

      test('does not display an "off" icon when no submissions are graded but unposted', () => {
        props.allStudents.forEach(student => {
          if (student.submission.workflowState === 'graded') {
            student.submission.postedAt = new Date()
          }
        })

        mountComponent()
        expect(getColumnHeaderIcon('IconOff')).not.toBeInTheDocument()
      })
    })

    test('displays no icon when submissions have not been loaded', () => {
      props.submissionsLoaded = false
      mountComponent()
      expect(getColumnHeaderIcon()).not.toBeInTheDocument()
    })
  })

  describe('secondary details', () => {
    function getSecondaryDetailText() {
      return container.querySelector('.Gradebook__ColumnHeaderDetail--secondary').textContent
    }

    test('displays points possible', () => {
      mountComponent()
      expect(getSecondaryDetailText()).toBe('Out of 10')
    })

    test('displays points possible when zero', () => {
      props.assignment.pointsPossible = 0
      mountComponent()
      expect(getSecondaryDetailText()).toBe('Out of 0')
    })

    test('displays an anonymous status when students are anonymized', () => {
      props.assignment.anonymizeStudents = true
      mountComponent()
      expect(getSecondaryDetailText()).toBe('Anonymous')
    })

    describe('when the assignment is not published', () => {
      beforeEach(() => {
        props.assignment.published = false
      })

      test('displays an unpublished status', () => {
        mountComponent()
        expect(getSecondaryDetailText()).toBe('Unpublished')
      })

      test('displays an unpublished status when students are anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        expect(getSecondaryDetailText()).toBe('Unpublished')
      })
    })

    describe('when the assignment is manually posted', () => {
      beforeEach(() => {
        props.assignment.postManually = true
      })

      test('displays post policy "Manual" text', () => {
        mountComponent()
        expect(getSecondaryDetailText()).toContain('Manual')
      })

      test('prioritizes "Anonymous" text when the assignment is anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        expect(getSecondaryDetailText()).toBe('Anonymous')
      })
    })

    test('does not display "Manual" text when the assignment is auto-posted', () => {
      mountComponent()
      expect(getSecondaryDetailText()).not.toContain('Manual')
    })
  })

  describe('"Options" menu trigger', () => {
    test('is present for a published assignment', () => {
      mountComponent()
      expect(getOptionsMenuTrigger()).toBeInTheDocument()
    })

    test('is not present for an unpublished assignment', () => {
      props.assignment.published = false
      mountComponent()
      expect(getOptionsMenuTrigger()).not.toBeInTheDocument()
    })

    test('is labeled with the assignment name', () => {
      mountComponent()
      const trigger = getOptionsMenuTrigger()
      expect(trigger.textContent).toContain('Math 1.1 Options')
    })

    test('opens the options menu when clicked', () => {
      mountComponent()
      fireEvent.click(getOptionsMenuTrigger())
      expect(getOptionsMenuContent()).toBeInTheDocument()
    })

    test('closes the options menu when clicked', () => {
      mountAndOpenOptionsMenu()
      fireEvent.click(getOptionsMenuTrigger())
      expect(getOptionsMenuContent()).not.toBeInTheDocument()
    })
  })

  describe('"Options" menu', () => {
    describe('when opened', () => {
      beforeEach(() => {
        mountAndOpenOptionsMenu()
      })

      test('is added as a Gradebook element', () => {
        expect(gradebookElements.indexOf(menuContent)).not.toBe(-1)
      })

      test('adds the "menuShown" class to the action container', () => {
        const actionContainer = container.querySelector('.Gradebook__ColumnHeaderAction')
        expect(actionContainer.classList).toContain('menuShown')
      })
    })

    describe('when closed', () => {
      beforeEach(() => {
        props.onMenuDismiss = jest.fn()
        mountAndOpenOptionsMenu()
        closeOptionsMenu()
      })

      test('is removed as a Gradebook element', () => {
        expect(gradebookElements.indexOf(menuContent)).toBe(-1)
      })

      test('calls the onMenuDismiss callback', () => {
        expect(props.onMenuDismiss).toHaveBeenCalledTimes(1)
      })

      test('removes the "menuShown" class from the action container', () => {
        const actionContainer = container.querySelector('.Gradebook__ColumnHeaderAction')
        expect(actionContainer.classList).not.toContain('menuShown')
      })
    })
  })
})
