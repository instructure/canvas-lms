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
import studentRowHeaderConstants from '../../../constants/studentRowHeaderConstants'
import StudentColumnHeader from '../StudentColumnHeader'
import {getMenuContent, getMenuItem} from './ColumnHeaderSpecHelpers'

describe('GradebookGrid StudentColumnHeader', () => {
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

  afterEach(() => {
    ReactDOM.unmountComponentAtNode($container)
    $container.remove()
  })

  function mountComponent() {
    // eslint-disable-next-line react/no-render-return-value
    component = ReactDOM.render(<StudentColumnHeader {...props} />, $container)
  }

  function getOptionsMenuTrigger() {
    return [...$container.querySelectorAll('button')].find(
      $button => $button.textContent === 'Student Name Options',
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

  describe('"Options" > "Secondary info" setting', () => {
    function getSecondaryInfoOption(label) {
      return getMenuItem($menuContent, 'Secondary info', label)
    }

    it.skip('is added as a Gradebook element when opened', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Secondary info')
      expect(gradebookElements.indexOf($sortByMenuContent)).not.toBe(-1)
    })

    it('is removed as a Gradebook element when closed', () => {
      mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Secondary info')
      closeOptionsMenu()
      expect(gradebookElements.indexOf($sortByMenuContent)).toBe(-1)
    })

    it('is disabled when all options are disabled', () => {
      props.disabled = true
      mountAndOpenOptionsMenu()
      expect(getMenuItem($menuContent, 'Secondary info').getAttribute('aria-disabled')).toBe('true')
    })

    describe('"Section" option', () => {
      it('is present when the course is using sections', () => {
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section')).toBeTruthy()
      })

      it('is not present when the course is not using sections', () => {
        props.sectionsEnabled = false
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section')).toBeFalsy()
      })

      it('is selected when displaying sections for secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'sis_id'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = jest.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "section" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('section')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').focus()
          getSecondaryInfoOption('Section').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectSecondaryInfo callback when already selected', () => {
          props.selectedSecondaryInfo = 'section'
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          expect(props.onSelectSecondaryInfo).not.toHaveBeenCalled()
        })
      })
    })

    describe('"Group" option', () => {
      it('is present when the course has student groups', () => {
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group')).toBeTruthy()
      })

      it('is not present when the course has no student groups', () => {
        props.studentGroupsEnabled = false
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group')).toBeFalsy()
      })

      it('is selected when displaying student groups for secondary info', () => {
        props.selectedSecondaryInfo = 'group'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'sis_id'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = jest.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "group" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('group')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').focus()
          getSecondaryInfoOption('Group').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectSecondaryInfo callback when already selected', () => {
          props.selectedSecondaryInfo = 'group'
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          expect(props.onSelectSecondaryInfo).not.toHaveBeenCalled()
        })
      })
    })

    describe('"SIS ID" option', () => {
      it('displays the configured SIS name', () => {
        props.sisName = 'Powerschool'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Powerschool')).toBeTruthy()
      })

      it('displays "SIS ID" when no SIS is configured', () => {
        props.sisName = null
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('SIS ID')).toBeTruthy()
      })

      it('is selected when displaying SIS ids for secondary info', () => {
        props.selectedSecondaryInfo = 'sis_id'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('SIS ID').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('SIS ID').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = jest.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "sis_id" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('sis_id')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').focus()
          getSecondaryInfoOption('SIS ID').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectSecondaryInfo callback when already selected', () => {
          props.selectedSecondaryInfo = 'sis_id'
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          expect(props.onSelectSecondaryInfo).not.toHaveBeenCalled()
        })
      })
    })

    describe('"Integration ID" option', () => {
      it('is always present', () => {
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Integration ID')).toBeTruthy()
      })

      it('is selected when displaying integration ids for secondary info', () => {
        props.selectedSecondaryInfo = 'integration_id'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Integration ID').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Integration ID').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = jest.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "integration_id" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('integration_id')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').focus()
          getSecondaryInfoOption('Integration ID').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectSecondaryInfo callback when already selected', () => {
          props.selectedSecondaryInfo = 'integration_id'
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          expect(props.onSelectSecondaryInfo).not.toHaveBeenCalled()
        })
      })
    })

    describe('"Login ID" option', () => {
      it('displays the configured login id name', () => {
        props.loginHandleName = 'Email'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Email')).toBeTruthy()
      })

      it('displays "Login ID" when no login id name is configured', () => {
        props.loginHandleName = null
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Login ID')).toBeTruthy()
      })

      it('is selected when displaying login ids for secondary info', () => {
        props.selectedSecondaryInfo = 'login_id'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Login ID').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Login ID').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = jest.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "login_id" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('login_id')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').focus()
          getSecondaryInfoOption('Login ID').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectSecondaryInfo callback when already selected', () => {
          props.selectedSecondaryInfo = 'login_id'
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          expect(props.onSelectSecondaryInfo).not.toHaveBeenCalled()
        })
      })
    })

    describe('"None" option', () => {
      it('is always present', () => {
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('None')).toBeTruthy()
      })

      it('is selected when not displaying secondary info', () => {
        props.selectedSecondaryInfo = 'none'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('None').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying secondary info', () => {
        props.selectedSecondaryInfo = 'section'
        mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('None').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = jest.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "none" when calling the .onSelectSecondaryInfo callback', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('none')
        })

        it('returns focus to the "Options" menu trigger', () => {
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').focus()
          getSecondaryInfoOption('None').click()
          expect(document.activeElement).toBe(getOptionsMenuTrigger())
        })

        // TODO: GRADE-____
        it.skip('does not call the .onSelectSecondaryInfo callback when already selected', () => {
          props.selectedSecondaryInfo = 'none'
          mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          expect(props.onSelectSecondaryInfo).not.toHaveBeenCalled()
        })
      })
    })
  })
})
