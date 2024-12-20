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

  QUnit.module('"Options" > "Secondary info" setting', () => {
    function getSecondaryInfoOption(label) {
      return getMenuItem($menuContent, 'Secondary info', label)
    }

    QUnit.skip('is added as a Gradebook element when opened', () => {
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
})
