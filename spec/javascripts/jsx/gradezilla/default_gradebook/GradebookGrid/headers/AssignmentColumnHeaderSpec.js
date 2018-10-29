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

import AssignmentColumnHeader from 'jsx/gradezilla/default_gradebook/GradebookGrid/headers/AssignmentColumnHeader'
import {blurElement, getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

/* eslint-disable qunit/no-identical-names */
QUnit.module('AssignmentColumnHeader', suiteHooks => {
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

      assignment: {
        anonymizeStudents: false,
        courseId: '1201',
        htmlUrl: 'http://localhost/assignments/2301',
        id: '2301',
        invalid: false,
        muted: false,
        name: 'Math 1.1',
        omitFromFinalGrade: false,
        pointsPossible: 10,
        published: true,
        submissionTypes: ['online_text_entry']
      },

      assignmentDetailsAction: {
        disabled: false,
        onSelect() {}
      },

      curveGradesAction: {
        isDisabled: false,
        onSelect() {}
      },

      downloadSubmissionsAction: {
        hidden: false,
        onSelect() {}
      },

      enterGradesAsSetting: {
        hidden: false,
        onSelect() {},
        selected: 'points',
        showGradingSchemeOption: true
      },

      muteAssignmentAction: {
        disabled: false,
        onSelect() {}
      },

      onMenuDismiss() {},

      removeGradebookElement($el) {
        gradebookElements.splice(gradebookElements.indexOf($el), 1)
      },

      reuploadSubmissionsAction: {
        hidden: false,
        onSelect() {}
      },

      setDefaultGradeAction: {
        disabled: false,
        onSelect() {}
      },

      showUnpostedMenuItem: true,

      sortBySetting: {
        direction: 'ascending',
        disabled: false,
        isSortColumn: true,
        onSortByGradeAscending() {},
        onSortByGradeDescending() {},
        onSortByLate() {},
        onSortByMissing() {},
        onSortByUnposted() {},
        settingKey: 'grade'
      },

      students: [
        {
          id: '1001',
          isInactive: false,
          name: 'Adam Jones',
          submission: {
            excused: false,
            score: 7,
            submittedAt: null
          }
        },

        {
          id: '1002',
          isInactive: false,
          name: 'Betty Ford',
          submission: {
            excused: false,
            score: 8,
            submittedAt: new Date('Thu Feb 02 2017 16:33:19 GMT-0500 (EST)')
          }
        },

        {
          id: '1003',
          isInactive: false,
          name: 'Charlie Xi',
          submission: {
            excused: false,
            score: null,
            submittedAt: null
          }
        }
      ],

      submissionsLoaded: true
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

    QUnit.module('when the assignment is muted', () => {
      test('displays a muted status', () => {
        props.assignment.muted = true
        mountComponent()
        ok(getSecondaryDetailText().includes('Muted'))
      })

      test('displays points possible', () => {
        props.assignment.muted = true
        mountComponent()
        ok(getSecondaryDetailText().includes('Out of 10'))
      })
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

      test('displays an unpublished status when the assignment is muted', () => {
        props.assignment.muted = true
        mountComponent()
        equal(getSecondaryDetailText(), 'Unpublished')
      })

      test('displays an unpublished status when students are anonymized', () => {
        props.assignment.anonymizeStudents = true
        mountComponent()
        equal(getSecondaryDetailText(), 'Unpublished')
      })
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
        QUnit.skip('does not call the .sortBySetting.onSortByGradeAscending callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - Low to High').click()
          strictEqual(props.sortBySetting.onSortByGradeAscending.callCount, 0)
        })
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
        QUnit.skip('does not call the .sortBySetting.onSortByGradeDescending callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Grade - High to Low').click()
          strictEqual(props.sortBySetting.onSortByGradeDescending.callCount, 0)
        })
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
        QUnit.skip('does not call the .sortBySetting.onSortByMissing callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Missing').click()
          strictEqual(props.sortBySetting.onSortByMissing.callCount, 0)
        })
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
        QUnit.skip('does not call the .sortBySetting.onSortByLate callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Late').click()
          strictEqual(props.sortBySetting.onSortByLate.callCount, 0)
        })
      })
    })

    QUnit.module('"Unposted" option', () => {
      test('is selected when sorting by unposted', () => {
        props.sortBySetting.settingKey = 'unposted'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Unposted').getAttribute('aria-checked'), 'true')
      })

      test('is not selected when sorting by a different setting', () => {
        props.sortBySetting.settingKey = 'grade'
        props.sortBySetting.direction = 'ascending'
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Unposted').getAttribute('aria-checked'), 'false')
      })

      test('is not selected when isSortColumn is false', () => {
        props.sortBySetting.isSortColumn = false
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Unposted').getAttribute('aria-checked'), 'false')
      })

      test('is optionally disabled', () => {
        props.sortBySetting.disabled = true
        mountAndOpenOptionsMenu()
        strictEqual(getSortByOption('Unposted').getAttribute('aria-disabled'), 'true')
      })

      test('is optionally excluded', () => {
        props.showUnpostedMenuItem = false
        mountAndOpenOptionsMenu()
        notOk(getSortByOption('Unposted'))
      })

      QUnit.module('when clicked', contextHooks => {
        contextHooks.beforeEach(() => {
          props.sortBySetting.onSortByUnposted = sinon.stub()
        })

        test('calls the .sortBySetting.onSortByUnposted callback', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Unposted').click()
          strictEqual(props.sortBySetting.onSortByUnposted.callCount, 1)
        })

        test('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSortByOption('Unposted').focus()
          getSortByOption('Unposted').click()
          strictEqual(document.activeElement, getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        QUnit.skip('does not call the .sortBySetting.onSortByUnposted callback when already selected', () => {
          props.sortBySetting.settingKey = 'grade'
          props.sortBySetting.direction = 'ascending'
          mountAndOpenOptionsMenu()
          getSortByOption('Unposted').click()
          strictEqual(props.sortBySetting.onSortByUnposted.callCount, 0)
        })
      })
    })
  })

  QUnit.module('"Options" > "Message Students Who" action', hooks => {
    hooks.beforeEach(() => {
      sandbox.stub(window, 'messageStudents')
    })

    test('is always present', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Message Students Who'))
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
      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('opens the message students dialog', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        strictEqual(window.messageStudents.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Message Students Who').click()
        const [settings] = window.messageStudents.lastCall.args
        settings.onClose()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
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

  QUnit.module('"Options" > "Mute Assignment" action', () => {
    test('is present when the assignment is not muted', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Mute Assignment'))
    })

    test('is not present when the assignment is muted', () => {
      props.assignment.muted = true
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Mute Assignment'))
    })

    test('is disabled when .muteAssignmentAction.disabled is true', () => {
      props.muteAssignmentAction.disabled = true
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Mute Assignment')
      strictEqual($menuItem.getAttribute('aria-disabled'), 'true')
    })

    test('is not disabled when .muteAssignmentAction.disabled is false', () => {
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Mute Assignment')
      strictEqual($menuItem.getAttribute('aria-disabled'), null)
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.muteAssignmentAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Mute Assignment').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .muteAssignmentAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Mute Assignment').click()
        strictEqual(props.muteAssignmentAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Mute Assignment').click()
        const [callback] = props.muteAssignmentAction.onSelect.lastCall.args
        callback()
        strictEqual(document.activeElement, getOptionsMenuTrigger())
      })
    })
  })

  QUnit.module('"Options" > "Unmute Assignment" action', hooks => {
    hooks.beforeEach(() => {
      props.assignment.muted = true
    })

    test('is present when the assignment is muted', () => {
      mountAndOpenOptionsMenu()
      ok(getMenuItem($menuContent, 'Unmute Assignment'))
    })

    test('is not present when the assignment is not muted', () => {
      props.assignment.muted = false
      mountAndOpenOptionsMenu()
      notOk(getMenuItem($menuContent, 'Unmute Assignment'))
    })

    test('is disabled when .muteAssignmentAction.disabled is true', () => {
      props.muteAssignmentAction.disabled = true
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Unmute Assignment')
      strictEqual($menuItem.getAttribute('aria-disabled'), 'true')
    })

    test('is not disabled when .muteAssignmentAction.disabled is false', () => {
      mountAndOpenOptionsMenu()
      const $menuItem = getMenuItem($menuContent, 'Unmute Assignment')
      strictEqual($menuItem.getAttribute('aria-disabled'), null)
    })

    QUnit.module('when clicked', contextHooks => {
      contextHooks.beforeEach(() => {
        props.muteAssignmentAction.onSelect = sinon.stub()
      })

      test('does not restore focus to the "Options" menu trigger', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Unmute Assignment').click()
        notEqual(document.activeElement, getOptionsMenuTrigger())
      })

      test('calls the .muteAssignmentAction.onSelect callback', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Unmute Assignment').click()
        strictEqual(props.muteAssignmentAction.onSelect.callCount, 1)
      })

      test('includes a callback for restoring focus upon dialog close', () => {
        mountAndOpenOptionsMenu()
        getMenuItem($menuContent, 'Unmute Assignment').click()
        const [callback] = props.muteAssignmentAction.onSelect.lastCall.args
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

    test('#focusAtStart() sets focus on the assignment link', () => {
      component.focusAtStart()
      strictEqual(document.activeElement, getAssignmentLink())
    })

    test('#focusAtEnd() sets focus on the "Options" menu trigger', () => {
      component.focusAtEnd()
      strictEqual(document.activeElement, getOptionsMenuTrigger())
    })

    test('adds the "focused" class to the header when the assignment link receives focus', () => {
      getAssignmentLink().focus()
      ok($container.firstChild.classList.contains('focused'))
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
