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
import {waitFor} from '@testing-library/react'
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

  async function openOptionsMenu() {
    getOptionsMenuTrigger().click()
    await waitFor(() => {
      $menuContent = getOptionsMenuContent()
      expect($menuContent).toBeInTheDocument()
    })
  }

  async function mountAndOpenOptionsMenu() {
    mountComponent()
    await openOptionsMenu()
  }

  function closeOptionsMenu() {
    getOptionsMenuTrigger().click()
  }

  describe('"Options" > "Secondary info" setting', () => {
    function getSecondaryInfoOption(label) {
      return getMenuItem($menuContent, 'Secondary info', label)
    }


    it('is removed as a Gradebook element when closed', async () => {
      await mountAndOpenOptionsMenu()
      const $sortByMenuContent = getMenuContent($menuContent, 'Secondary info')
      closeOptionsMenu()
      expect(gradebookElements.indexOf($sortByMenuContent)).toBe(-1)
    })

    it('is disabled when all options are disabled', async () => {
      props.disabled = true
      await mountAndOpenOptionsMenu()
      expect(getMenuItem($menuContent, 'Secondary info').getAttribute('aria-disabled')).toBe('true')
    })

    describe('"Section" option', () => {
      it('is present when the course is using sections', async () => {
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section')).toBeTruthy()
      })

      it('is not present when the course is not using sections', async () => {
        props.sectionsEnabled = false
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section')).toBeFalsy()
      })

      it('is selected when displaying sections for secondary info', async () => {
        props.selectedSecondaryInfo = 'section'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', async () => {
        props.selectedSecondaryInfo = 'sis_id'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Section').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = vi.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "section" when calling the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('section')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Section').focus()
          getSecondaryInfoOption('Section').click()
          await waitFor(() => {
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })
        })
      })
    })

    describe('"Group" option', () => {
      it('is present when the course has student groups', async () => {
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group')).toBeTruthy()
      })

      it('is not present when the course has no student groups', async () => {
        props.studentGroupsEnabled = false
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group')).toBeFalsy()
      })

      it('is selected when displaying student groups for secondary info', async () => {
        props.selectedSecondaryInfo = 'group'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', async () => {
        props.selectedSecondaryInfo = 'sis_id'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Group').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = vi.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "group" when calling the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('group')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Group').focus()
          getSecondaryInfoOption('Group').click()
          await waitFor(() => {
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })
        })
      })
    })

    describe('"SIS ID" option', () => {
      it('displays the configured SIS name', async () => {
        props.sisName = 'Powerschool'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Powerschool')).toBeTruthy()
      })

      it('displays "SIS ID" when no SIS is configured', async () => {
        props.sisName = null
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('SIS ID')).toBeTruthy()
      })

      it('is selected when displaying SIS ids for secondary info', async () => {
        props.selectedSecondaryInfo = 'sis_id'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('SIS ID').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', async () => {
        props.selectedSecondaryInfo = 'section'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('SIS ID').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = vi.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "sis_id" when calling the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('sis_id')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('SIS ID').focus()
          getSecondaryInfoOption('SIS ID').click()
          await waitFor(() => {
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })
        })
      })
    })

    describe('"Integration ID" option', () => {
      it('is always present', async () => {
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Integration ID')).toBeTruthy()
      })

      it('is selected when displaying integration ids for secondary info', async () => {
        props.selectedSecondaryInfo = 'integration_id'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Integration ID').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', async () => {
        props.selectedSecondaryInfo = 'section'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Integration ID').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = vi.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "integration_id" when calling the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('integration_id')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Integration ID').focus()
          getSecondaryInfoOption('Integration ID').click()
          await waitFor(() => {
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })
        })
      })
    })

    describe('"Login ID" option', () => {
      it('displays the configured login id name', async () => {
        props.loginHandleName = 'Email'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Email')).toBeTruthy()
      })

      it('displays "Login ID" when no login id name is configured', async () => {
        props.loginHandleName = null
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Login ID')).toBeTruthy()
      })

      it('is selected when displaying login ids for secondary info', async () => {
        props.selectedSecondaryInfo = 'login_id'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Login ID').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying different secondary info', async () => {
        props.selectedSecondaryInfo = 'section'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('Login ID').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = vi.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "login_id" when calling the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('login_id')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('Login ID').focus()
          getSecondaryInfoOption('Login ID').click()
          await waitFor(() => {
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })
        })
      })
    })

    describe('"None" option', () => {
      it('is always present', async () => {
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('None')).toBeTruthy()
      })

      it('is selected when not displaying secondary info', async () => {
        props.selectedSecondaryInfo = 'none'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('None').getAttribute('aria-checked')).toBe('true')
      })

      it('is not selected when displaying secondary info', async () => {
        props.selectedSecondaryInfo = 'section'
        await mountAndOpenOptionsMenu()
        expect(getSecondaryInfoOption('None').getAttribute('aria-checked')).toBe('false')
      })

      describe('when clicked', () => {
        beforeEach(() => {
          props.onSelectSecondaryInfo = vi.fn()
        })

        it('calls the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          expect(props.onSelectSecondaryInfo).toHaveBeenCalledTimes(1)
        })

        it('includes "none" when calling the .onSelectSecondaryInfo callback', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').click()
          const [secondaryInfoType] =
            props.onSelectSecondaryInfo.mock.calls[
              props.onSelectSecondaryInfo.mock.calls.length - 1
            ]
          expect(secondaryInfoType).toBe('none')
        })

        it('returns focus to the "Options" menu trigger', async () => {
          await mountAndOpenOptionsMenu()
          getSecondaryInfoOption('None').focus()
          getSecondaryInfoOption('None').click()
          await waitFor(() => {
            expect(document.activeElement).toBe(getOptionsMenuTrigger())
          })
        })
      })
    })
  })
})
