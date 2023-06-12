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

import AsyncComponents from 'ui/features/gradebook/react/default_gradebook/AsyncComponents'
import AssignmentColumnHeader from 'ui/features/gradebook/react/default_gradebook/GradebookGrid/headers/AssignmentColumnHeader'
import MessageStudentsWhoDialog from 'ui/features/gradebook/react/shared/MessageStudentsWhoDialog'
import {blurElement, getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

/* eslint-disable qunit/no-identical-names */
QUnit.module('GradebookGrid AssignmentColumnHeader', suiteHooks => {
  let $container
  let $menuContent
  let component
  let gradebookElements
  let props
  let students

  suiteHooks.beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))

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
      addGradebookElement($el) {
        gradebookElements.push($el)
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

      removeGradebookElement($el) {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
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

  suiteHooks.afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    component = ReactDOM.render(<AssignmentColumnHeader {...props} />, $container)
  }

  function getAssignmentLink() {
    return [...$container.querySelectorAll('a')].find($link => $link.textContent === 'Math 1.1')
  }

  function getOptionsMenuTrigger() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Math 1.1 Options'
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

  QUnit.module('assignment name', hooks => {
    hooks.beforeEach(mountComponent)

    test('is present as a link', () => {
      ok(getAssignmentLink())
    })

    test('links to the assignment url', () => {
      equal(getAssignmentLink().href, 'http://localhost/assignments/2301')
    })
  })

  QUnit.module('header indicators', hooks => {
    function getColumnHeaderIcon(name = null) {
      const iconSpecifier = name != null ? `svg[name="${name}"]` : 'svg'
      return $container.querySelector(`.Gradebook__ColumnHeaderIndicators ${iconSpecifier}`)
    }

    hooks.beforeEach(() => {
      props.postGradesAction.enabledForUser = true
    })

    QUnit.module('when the assignment is auto-posted', () => {
      test('displays no icon when no submissions are graded but unposted', () => {
        props.allStudents.forEach(student => {
          if (student.submission.score != null) {
            student.submission.postedAt = new Date()
          }
        })

        mountComponent()
        notOk(getColumnHeaderIcon())
      })

      test('displays an "off" icon when submissions are graded but unposted', () => {
        mountComponent()
        ok(getColumnHeaderIcon('IconOff'))
      })
    })

    QUnit.module('when the assignment is manually-posted', manualPostingHooks => {
      manualPostingHooks.beforeEach(() => {
        props.assignment.postManually = true
      })

      test('does not display an "off" icon when no submissions are graded but unposted', () => {
        props.allStudents.forEach(student => {
          if (student.submission.workflowState === 'graded') {
            student.submission.postedAt = new Date()
          }
        })

        mountComponent()
        notOk(getColumnHeaderIcon('IconOff'))
      })
    })

    test('displays no icon when submissions have not been loaded', () => {
      props.submissionsLoaded = false
      mountComponent()
      notOk(getColumnHeaderIcon())
    })
  })

  QUnit.module('secondary details', () => {
    function getSecondaryDetailText() {
      return $container.querySelector('.Gradebook__ColumnHeaderDetail--secondary').textContent
    }

    test('displays points possible', () => {
      mountComponent()
      equal(getSecondaryDetailText(), 'Out of 10')
    })

    test('displays points possible when zero', () => {
      props.assignment.pointsPossible = 0
      mountComponent()
      equal(getSecondaryDetailText(), 'Out of 0')
    })

    test('displays an anonymous status when students are anonymized', () => {
      props.assignment.anonymizeStudents = true
      mountComponent()
      equal(getSecondaryDetailText(), 'Anonymous')
    })

    QUnit.module('when the assignment is not published', contextHooks => {
      contextHooks.beforeEach(() => {
        props.assignment.published = false
      })

      test('displays an unpublished status', () => {
        mountComponent()
        equal(getSecondaryDetailText(), 'Unpublished')
      })

      test('displays an unpublished status when students are anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        equal(getSecondaryDetailText(), 'Unpublished')
      })
    })

    QUnit.module('when the assignment is manually posted', manualPostHooks => {
      manualPostHooks.beforeEach(() => {
        props.assignment.postManually = true
      })

      test('displays post policy "Manual" text', () => {
        mountComponent()
        ok(getSecondaryDetailText().includes('Manual'))
      })

      test('prioritizes "Anonymous" text when the assignment is anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        equal(getSecondaryDetailText(), 'Anonymous')
      })
    })

    test('does not display "Manual" text when the assignment is auto-posted', () => {
      mountComponent()
      notOk(getSecondaryDetailText().includes('Manual'))
    })
  })

  QUnit.module('"Options" menu trigger', () => {
    test('is present for a published assignment', () => {
      mountComponent()
      ok(getOptionsMenuTrigger())
    })

    test('is not present for an unpublished assignment', () => {
      props.assignment.published = false
      mountComponent()
      notOk(getOptionsMenuTrigger())
    })

    test('is labeled with the assignment name', () => {
      mountComponent()
      const $trigger = getOptionsMenuTrigger()
      ok($trigger.textContent.includes('Math 1.1 Options'))
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

    QUnit.module('"Missing" option', () => {
      test('is selected when sorting by missing', () => {
        props.sortBySetting.settingKey = 'missing'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Missing').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Missing').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Missing').getAttribute('aria-checked'), 'false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Missing').getAttribute('aria-disabled'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.sortBySetting.onSortByMissing = sinon.stub()
        })

        test('calls the .sortBySetting.onSortByMissing callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Missing').click()
          strictEqual(props.sortBySetting.onSortByMissing.callCount, 1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Missing').focus()
          getSortByOption('Missing').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .sortBySetting.onSortByMissing callback when already selected',
          () => {
            props.sortBySetting.settingKey = 'grade'
            props.sortBySetting.direction = 'ascending'
            mountAndOpenOptionsMenu()
            getSortByOption('Missing').click()
            strictEqual(props.sortBySetting.onSortByMissing.callCount, 0)
          }
        )
      })
    })

    QUnit.module('"Late" option', () => {
      test('is selected when sorting by late', () => {
        props.sortBySetting.settingKey = 'late'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Late').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Late').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Late').getAttribute('aria-checked'), 'false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Late').getAttribute('aria-disabled'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.sortBySetting.onSortByLate = sinon.stub()
        })

        test('calls the .sortBySetting.onSortByLate callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Late').click()
          strictEqual(props.sortBySetting.onSortByLate.callCount, 1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Late').focus()
          getSortByOption('Late').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip(
          'does not call the .sortBySetting.onSortByLate callback when already selected',
          () => {
            props.sortBySetting.settingKey = 'grade'
            props.sortBySetting.direction = 'ascending'
            mountAndOpenOptionsMenu()
            getSortByOption('Late').click()
            strictEqual(props.sortBySetting.onSortByLate.callCount, 0)
          }
        )
      })
    })
  })

  QUnit.module('"Options" > "SpeedGrader" action', () => {
    test('is present', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'SpeedGrader'))
    })

    test('links to SpeedGrader for the current assignment', () => {
      mountAndOpenOptionsMenu()
      const menuItem = getMenuItem($menuContent, 'SpeedGrader')
      ok(menuItem.href.includes('/courses/1201/gradebook/speed_grader?assignment_id=2301'))
    })
  })

  QUnit.module('"Options" > "Message Students Who" action', hooks => {
    let loadMessageStudentsWhoDialogPromise

    hooks.beforeEach(() => {
      loadMessageStudentsWhoDialogPromise = Promise.resolve(MessageStudentsWhoDialog)

      sandbox
        .stub(AsyncComponents, 'loadMessageStudentsWhoDialog')
        .returns(loadMessageStudentsWhoDialogPromise)
      sandbox.stub(MessageStudentsWhoDialog, 'show')
    })

    test('is always present', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Message Students Who'))
    })

    test('is disabled when anonymizing students', () => {
      props.assignment.anonymizeStudents = true
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Message Students Who')
      strictEqual($menuItem.getAttribute('aria-disabled'), 'true')
    })

    test('is disabled when submissions are not loaded', () => {
      props.submissionsLoaded = false
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Message Students Who')
      strictEqual($menuItem.getAttribute('aria-disabled'), 'true')
    })

    test('is not disabled when submissions are loaded', () => {
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Message Students Who')
      strictEqual($menuItem.getAttribute('aria-disabled'), null)
    })

    QUnit.module('when clicked', () => {
      test('does not restore focus to the "Options" menu trigger', async () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        await loadMessageStudentsWhoDialogPromise
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('includes a callback for restoring focus upon dialog close', async () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        await loadMessageStudentsWhoDialogPromise
        const [, onClose] = MessageStudentsWhoDialog.show.lastCall.args
        onClose()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('includes non-test students in the "settings" hash', async () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        await loadMessageStudentsWhoDialogPromise
        const [settings] = MessageStudentsWhoDialog.show.lastCall.args
        strictEqual(settings.students.length, 2)
      })

      test('excludes test students from the "settings" hash', async () => {
        students[0].isTestStudent = true

        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        await loadMessageStudentsWhoDialogPromise
        const [settings] = MessageStudentsWhoDialog.show.lastCall.args
        deepEqual(
          settings.students.map(student => student.name),
          ['Betty Ford']
        )
      })
    })
  })

  QUnit.module('"Options" > "Curve Grades" action', () => {
    test('is always present', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Curve Grades'))
    })

    test('is disabled when .curveGradesAction.isDisabled is true', () => {
      props.curveGradesAction.isDisabled = true
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Curve Grades')
      strictEqual($menuItem.getAttribute('aria-disabled'), 'true')
    })

    test('is not disabled when .curveGradesAction.isDisabled is false', () => {
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Curve Grades')
      strictEqual($menuItem.getAttribute('aria-disabled'), null)
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.curveGradesAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Curve Grades').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .curveGradesAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Curve Grades').click()
        strictEqual(props.curveGradesAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Curve Grades').click()
        const [callback] = props.curveGradesAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Set Default Grade" action', () => {
    test('is always present', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Set Default Grade'))
    })

    test('is disabled when .setDefaultGradeAction.disabled is true', () => {
      props.setDefaultGradeAction.disabled = true
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Set Default Grade')
      strictEqual($menuItem.getAttribute('aria-disabled'), 'true')
    })

    test('is not disabled when .setDefaultGradeAction.disabled is false', () => {
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Set Default Grade')
      strictEqual($menuItem.getAttribute('aria-disabled'), null)
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.setDefaultGradeAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Set Default Grade').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .setDefaultGradeAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Set Default Grade').click()
        strictEqual(props.setDefaultGradeAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Set Default Grade').click()
        const [callback] = props.setDefaultGradeAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Post grades" action', hooks => {
    hooks.beforeEach(() => {
      props.postGradesAction.enabledForUser = true
      props.postGradesAction.hasGradesOrCommentsToPost = true
    })

    QUnit.module('when the current user can edit grades', () => {
      test('has the default text when submissions can be posted', () => {
        mountAndOpenOptionsMenu()
        ok(getMenuItem($menuContent, 'Post grades'))
      })

      test('is enabled when submissions can be posted', () => {
        mountAndOpenOptionsMenu()
        strictEqual(getMenuItem($menuContent, 'Post grades').getAttribute('aria-disabled'), null)
      })

      test('has the text "All grades posted" when no submissions can be posted', () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false
        mountAndOpenOptionsMenu()
        ok(getMenuItem($menuContent, 'All grades posted'))
      })

      test('has the text "No grades to post" when no submissions are graded or have comments', () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false
        props.postGradesAction.hasGradesOrPostableComments = false
        mountAndOpenOptionsMenu()
        ok(getMenuItem($menuContent, 'No grades to post'))
      })

      test('is disabled when no submissions can be posted', () => {
        props.postGradesAction.hasGradesOrCommentsToPost = false
        mountAndOpenOptionsMenu()
        strictEqual(
          getMenuItem($menuContent, 'All grades posted').getAttribute('aria-disabled'),
          'true'
        )
      })
    })

    test('does not appear when posting is not enabled for this user', () => {
      props.postGradesAction.enabledForUser = false
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Post grades'))
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.postGradesAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Post grades').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .postGradesAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Post grades').click()
        strictEqual(props.postGradesAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Post grades').click()
        const [callback] = props.postGradesAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Hide grades" action', hooks => {
    hooks.beforeEach(() => {
      props.postGradesAction.enabledForUser = true
      props.hideGradesAction.hasGradesOrCommentsToHide = true
    })

    QUnit.module('when post policies is enabled', () => {
      test('has the default text when submissions can be hidden', () => {
        mountAndOpenOptionsMenu()
        ok(getMenuItem($menuContent, 'Hide grades'))
      })

      test('is enabled when submissions can be hidden', () => {
        mountAndOpenOptionsMenu()
        strictEqual(getMenuItem($menuContent, 'Hide grades').getAttribute('aria-disabled'), null)
      })

      test('has the text "All grades hidden" when no submissions can be hidden', () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false
        mountAndOpenOptionsMenu()
        ok(getMenuItem($menuContent, 'All grades hidden'))
      })

      test('has the text "No grades to hide" when no submissions are graded or have comments', () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false
        props.hideGradesAction.hasGradesOrPostableComments = false
        mountAndOpenOptionsMenu()
        ok(getMenuItem($menuContent, 'No grades to hide'))
      })

      test('is disabled when no submissions can be hidden', () => {
        props.hideGradesAction.hasGradesOrCommentsToHide = false
        mountAndOpenOptionsMenu()
        strictEqual(
          getMenuItem($menuContent, 'All grades hidden').getAttribute('aria-disabled'),
          'true'
        )
      })
    })

    test('is present when the current user can post grades', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Hide grades'))
    })

    test('is not present when the current user cannot post grades', () => {
      props.postGradesAction.enabledForUser = false
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Hide grades'))
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.hideGradesAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Hide grades').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .hideGradesAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Hide grades').click()
        strictEqual(props.hideGradesAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Hide grades').click()
        const [callback] = props.hideGradesAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Grade Posting Policy" action', hooks => {
    hooks.beforeEach(() => {
      props.postGradesAction.enabledForUser = true
    })

    test('is present when the current user can post grades', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Grade Posting Policy'))
    })

    test('is not present when the current user cannot post grades', () => {
      props.postGradesAction.enabledForUser = false
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Grade Posting Policy'))
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.showGradePostingPolicyAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Grade Posting Policy').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .showGradePostingPolicyAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Grade Posting Policy').click()
        strictEqual(props.showGradePostingPolicyAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Grade Posting Policy').click()
        const [callback] = props.showGradePostingPolicyAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Enter Grades as" setting', () => {
    function getEnterGradesAsOption(label) {
      return getMenuItem($menuContent, 'Enter Grades as', label)
    }

    test('is present when .enterGradesAsSetting.hidden is false', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Enter Grades as'))
    })

    test('is not present when .enterGradesAsSetting.hidden is true', () => {
      props.enterGradesAsSetting.hidden = true
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Enter Grades as'))
    })

    // TODO: GRADE-____
    QUnit.skip('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Enter Grades as')
      notEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    // TODO: GRADE-____
    QUnit.skip('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Enter Grades as')
      closeOptionsMenu()
      strictEqual(gradebookElements.indexOf($sortByMenuContent), -1)
    })

    QUnit.module('"Points" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        ok(getEnterGradesAsOption('Points'))
      })

      test('is optionally selected', () => {
        props.enterGradesAsSetting.selected = 'points'
        mountAndOpenOptionsMenu()
        strictEqual(getEnterGradesAsOption('Points').getAttribute('aria-checked'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.enterGradesAsSetting.selected = 'percent'
          props.enterGradesAsSetting.onSelect = sinon.stub()
        })

        test('calls the onSelect callback', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Points').click()
          strictEqual(props.enterGradesAsSetting.onSelect.callCount, 1)
        })

        test('calls the onSelect callback with "points"', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Points').click()
          const [selected] = props.enterGradesAsSetting.onSelect.lastCall.args
          equal(selected, 'points')
        })

        // TODO: GRADE-____
        QUnit.skip('does not call the onSelect callback when already selected', () => {
          props.enterGradesAsSetting.selected = 'points'
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Points').click()
          strictEqual(props.enterGradesAsSetting.onSelect.callCount, 0)
        })
      })
    })

    QUnit.module('"Percentage" option', () => {
      test('is always present', () => {
        mountAndOpenOptionsMenu()
        ok(getEnterGradesAsOption('Percentage'))
      })

      test('is optionally selected', () => {
        props.enterGradesAsSetting.selected = 'percent'
        mountAndOpenOptionsMenu()
        strictEqual(getEnterGradesAsOption('Percentage').getAttribute('aria-checked'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.enterGradesAsSetting.selected = 'points'
          props.enterGradesAsSetting.onSelect = sinon.stub()
        })

        test('calls the onSelect callback', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Percentage').click()
          strictEqual(props.enterGradesAsSetting.onSelect.callCount, 1)
        })

        test('calls the onSelect callback with "percent"', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Percentage').click()
          const [selected] = props.enterGradesAsSetting.onSelect.lastCall.args
          equal(selected, 'percent')
        })

        // TODO: GRADE-____
        QUnit.skip('does not call the onSelect callback when already selected', () => {
          props.enterGradesAsSetting.selected = 'percent'
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Percentage').click()
          strictEqual(props.enterGradesAsSetting.onSelect.callCount, 0)
        })
      })
    })

    QUnit.module('"Grading Scheme" option', () => {
      test('is present when "showGradingSchemeOption" is true', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = true
        mountAndOpenOptionsMenu()
        ok(getEnterGradesAsOption('Grading Scheme'))
      })

      test('is not present when "showGradingSchemeOption" is false', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = false
        mountAndOpenOptionsMenu()
        notOk(getEnterGradesAsOption('Grading Scheme'))
      })

      test('is optionally selected', () => {
        props.enterGradesAsSetting.showGradingSchemeOption = true
        props.enterGradesAsSetting.selected = 'gradingScheme'
        mountAndOpenOptionsMenu()
        strictEqual(getEnterGradesAsOption('Grading Scheme').getAttribute('aria-checked'), 'true')
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.enterGradesAsSetting.selected = 'points'
          props.enterGradesAsSetting.onSelect = sinon.stub()
        })

        test('calls the onSelect callback', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Grading Scheme').click()
          strictEqual(props.enterGradesAsSetting.onSelect.callCount, 1)
        })

        test('calls the onSelect callback with "gradingScheme"', () => {
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Grading Scheme').click()
          const [selected] = props.enterGradesAsSetting.onSelect.lastCall.args
          equal(selected, 'gradingScheme')
        })

        // TODO: GRADE-____
        QUnit.skip('does not call the onSelect callback when already selected', () => {
          props.enterGradesAsSetting.selected = 'gradingScheme'
          mountAndOpenOptionsMenu()
          getEnterGradesAsOption('Grading Scheme').click()
          strictEqual(props.enterGradesAsSetting.onSelect.callCount, 0)
        })
      })
    })
  })

  QUnit.module('"Options" > "Download Submissions" action', () => {
    test('is present when .downloadSubmissionsAction.hidden is false', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Download Submissions'))
    })

    test('is not present when .downloadSubmissionsAction.hidden is true', () => {
      props.downloadSubmissionsAction.hidden = true
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Download Submissions'))
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.downloadSubmissionsAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Download Submissions').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .downloadSubmissionsAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Download Submissions').click()
        strictEqual(props.downloadSubmissionsAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Download Submissions').click()
        const [callback] = props.downloadSubmissionsAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Re-Upload Submissions" action', () => {
    test('is present when .reuploadSubmissionsAction.hidden is false', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Re-Upload Submissions'))
    })

    test('is not present when .reuploadSubmissionsAction.hidden is true', () => {
      props.reuploadSubmissionsAction.hidden = true
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Re-Upload Submissions'))
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.reuploadSubmissionsAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Re-Upload Submissions').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .reuploadSubmissionsAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Re-Upload Submissions').click()
        strictEqual(props.reuploadSubmissionsAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Re-Upload Submissions').click()
        const [callback] = props.reuploadSubmissionsAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
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

    QUnit.module('when the assignment link has focus', contextHooks => {
      contextHooks.beforeEach(() => {
        getAssignmentLink().focus()
      })

      test('Tab sets focus on the "Options" menu trigger', () => {
        handleKeyDown(9, false) // Tab
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('prevents default behavior for Tab', () => {
        handleKeyDown(9, false) // Tab
        strictEqual(preventDefault.callCount, 1)
      })

      test('returns false for Tab', () => {
        // This prevents additional behavior in Grid Support Navigation.
        const returnValue = handleKeyDown(9, false) // Tab
        strictEqual(returnValue, false)
      })

      test('does not handle Shift+Tab', () => {
        // This allows Grid Support Navigation to handle navigation.
        const returnValue = handleKeyDown(9, true) // Shift+Tab
        equal(typeof returnValue, 'undefined')
      })
    })

    QUnit.module('when the "Options" menu trigger has focus', contextHooks => {
      contextHooks.beforeEach(() => {
        getOptionsMenuTrigger().focus()
      })

      test('Shift+Tab sets focus on the assignment link', () => {
        handleKeyDown(9, true) // Shift+Tab
        strictEqual(document.activeElement, getAssignmentLink())
      })

      test('prevents default behavior for Shift+Tab', () => {
        handleKeyDown(9, true) // Shift+Tab
        strictEqual(preventDefault.callCount, 1)
      })

      test('returns false for Shift+Tab', () => {
        // This prevents additional behavior in Grid Support Navigation.
        const returnValue = handleKeyDown(9, true) // Shift+Tab
        strictEqual(returnValue, false)
      })

      test('does not handle Tab', () => {
        // This allows Grid Support Navigation to handle navigation.
        const returnValue = handleKeyDown(9, false) // Tab
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

    function focusElement($element) {
      const event = document.createEvent('Event')
      event.initEvent('focus', true, true)
      $element.dispatchEvent(event)
    }

    test('#focusAtStart() sets focus on the assignment link', () => {
      component.focusAtStart()
      strictEqual(document.activeElement, getAssignmentLink())
    })

    test('#focusAtEnd() sets focus on the "Options" menu trigger', () => {
      component.focusAtEnd()
      strictEqual(document.activeElement, getOptionsMenuTrigger())
    })

    test('adds the "focused" class to the header when the assignment link receives focus', () => {
      focusElement(getAssignmentLink())
      ok($container.firstChild.classList.contains('focused'))
    })

    test('adds the "focused" class to the header when the "Options" menu trigger receives focus', () => {
      focusElement(getOptionsMenuTrigger())
      ok($container.firstChild.classList.contains('focused'))
    })

    test('removes the "focused" class from the header when focus leaves', () => {
      focusElement(getOptionsMenuTrigger())
      blurElement(getOptionsMenuTrigger())
      notOk($container.firstChild.classList.contains('focused'))
    })
  })
})
/* eslint-enable qunit/no-identical-names */
