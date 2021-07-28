/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {MockedProvider} from '@apollo/react-testing'
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
import {within} from '@testing-library/dom'
import React from 'react'
import {createCache} from '@canvas/apollo'
import OutcomeManagementPanel from '../index'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {
  accountMocks,
  courseMocks,
  groupDetailMocks,
  groupMocks,
  updateOutcomeGroupMock
} from '@canvas/outcomes/mocks/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/rce/RichContentEditor')
jest.useFakeTimers()

describe('OutcomeManagementPanel', () => {
  let cache
  let showFlashAlertSpy

  beforeEach(() => {
    cache = createCache()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    window.ENV = {
      PERMISSIONS: {
        manage_outcomes: true
      }
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
    window.ENV = null
  })

  const groupDetailDefaultProps = {
    contextType: 'Course',
    contextId: '2',
    mocks: [
      ...courseMocks({childGroupsCount: 2}),
      ...groupMocks({groupId: '200'}),
      ...groupDetailMocks({
        title: 'Course folder 0',
        groupId: '200',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false
      })
    ]
  }

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      canManage = true,
      mocks = accountMocks({childGroupsCount: 0})
    } = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId, canManage}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders the empty billboard for accounts without child groups and outcomes', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: accountMocks({childGroupsCount: 0, outcomesCount: 0})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText(/Outcomes have not been added to this account yet/)).not.toBeNull()
  })

  it('renders the empty billboard for courses without child outcomes and groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 0, outcomesCount: 0})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText(/Outcomes have not been added to this course yet/)).not.toBeNull()
  })

  it('does not render the empty billboard if the root group has child outcomes', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({outcomesCount: 1, childGroupsCount: 0})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Root course folder')).toBeInTheDocument()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
      mocks: accountMocks({childGroupsCount: 2})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root account folder')).toBeInTheDocument()
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Account folder 1')).toBeInTheDocument()
    expect(getAllByText('2 Groups | 2 Outcomes').length).toBe(3)
  })

  it('loads outcome group data for Course', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 2})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root course folder')).toBeInTheDocument()
    expect(getByText('Course folder 0')).toBeInTheDocument()
    expect(getByText('Course folder 1')).toBeInTheDocument()
    expect(getAllByText('10 Groups | 2 Outcomes').length).toBe(2)
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: [
        ...accountMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '100'}),
        ...groupDetailMocks({groupId: '100', contextType: 'Account', contextId: '1'})
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('displays a screen reader error and text error on failed request for course outcome groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: []
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading course learning outcome groups.',
      srOnly: true,
      type: 'error'
    })
    expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
  })

  it('displays a screen reader error and text error on failed request for account outcome groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: []
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      srOnly: true,
      type: 'error'
    })
    expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
  })

  it('displays a flash alert if a child group fails to load', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: [...accountMocks({childGroupsCount: 2})]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      type: 'error',
      srOnly: false
    })
  })

  it('loads group detail data correctly', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
    expect(getByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
    expect(getByText('Outcome 2 - Course folder 0')).toBeInTheDocument()
  })

  it('shows remove group modal if remove option from group menu is selected', async () => {
    const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Outcome Group Menu'))
    fireEvent.click(within(getByRole('menu')).getByText('Remove'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Remove Group?')).toBeInTheDocument()
  })

  it('hides the "Outcome Group Menu" for the root group', async () => {
    const {getByText, queryByText} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Root course folder'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(queryByText('Outcome Group Menu')).not.toBeInTheDocument()
  })

  it('selects/unselects outcome via checkbox', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Select outcome')[0])
    expect(getByText('1 Outcome Selected')).toBeInTheDocument()
    fireEvent.click(getAllByText('Select outcome')[0])
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
  })

  it('shows remove outcome modal if remove option from individual outcome menu is selected', async () => {
    const {getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Remove'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Remove Outcome?')).toBeInTheDocument()
  })

  it('shows edit outcome modal if edit option from individual outcome menu is selected', async () => {
    const {getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('shows move outcome modal if move option from individual outcome menu is selected', async () => {
    const {getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Move'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Where would you like to move this outcome?')).toBeInTheDocument()
  })

  it('clears selected outcome when edit outcome modal is closed', async () => {
    const {getByText, getAllByText, queryByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Edit Outcome')).not.toBeInTheDocument()
  })

  it('clears selected outcome when remove outcome modal is closed', async () => {
    const {getByText, getAllByText, queryByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Remove'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
  })

  it('clears selected outcome when move outcome modal is closed', async () => {
    const {getByText, getAllByText, queryByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Move'))
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Move "Outcome 1 - Course folder 0"')).not.toBeInTheDocument()
  })

  it('hides the Outcome Menu if the user doesnt have permission to edit the outcome', async () => {
    const {getByText, queryByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '200'}),
        ...groupDetailMocks({groupId: '200', contextType: 'Course', contextId: '2', canEdit: false})
      ]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(queryByText('Outcome Menu')).not.toBeInTheDocument()
  })

  it('should not disable search input and clear search button (X) if there are no results', async () => {
    const {getByText, getByLabelText, queryByTestId} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('2 Outcomes')).toBeInTheDocument()
    fireEvent.change(getByLabelText('Search field'), {target: {value: 'no matched results'}})
    await act(async () => jest.advanceTimersByTime(500))
    expect(getByLabelText('Search field')).toBeEnabled()
    expect(queryByTestId('clear-search-icon')).toBeInTheDocument()
  })

  it('debounces search string typed by user', async () => {
    const {getByText, getByLabelText} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps,
      mocks: [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '200'}),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false
        })
      ]
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('All Course folder 0 Outcomes')).toBeInTheDocument()
    const searchInput = getByLabelText('Search field')
    fireEvent.change(searchInput, {target: {value: 'Outcome'}})
    await act(async () => jest.advanceTimersByTime(100))
    expect(getByText('2 Outcomes')).toBeInTheDocument()
    fireEvent.change(searchInput, {target: {value: 'Outcome '}})
    await act(async () => jest.advanceTimersByTime(300))
    expect(getByText('2 Outcomes')).toBeInTheDocument()
    fireEvent.change(searchInput, {target: {value: 'Outcome 1'}})
    await act(async () => jest.advanceTimersByTime(500))
    expect(getByText('1 Outcome')).toBeInTheDocument()
  })

  describe('Bulk remove outcomes', () => {
    it('shows bulk remove outcomes modal if outcomes are selected and remove button is clicked', async () => {
      const {getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getByRole('button', {name: /remove/i}))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Remove Outcomes?')).toBeInTheDocument()
    })
  })

  describe('Bulk move outcomes', () => {
    it('shows bulk move outcomes modal if outcomes are selected and move button is clicked', async () => {
      const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Move 2 Outcomes?')).toBeInTheDocument()
    })

    it('closes modal and clears selected outcomes when destination group for move is selected and "Move" button is clicked', async () => {
      const {getByText, getByRole, getAllByText, queryByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => jest.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
      expect(queryByText('Move 2 Outcomes?')).not.toBeInTheDocument()
    })
  })

  describe('Moving a group', () => {
    it('show parent group in the RHS when moving a group succeeds', async () => {
      const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps,
        mocks: [
          ...courseMocks({childGroupsCount: 2}),
          ...groupMocks({groupId: '200'}),
          ...groupDetailMocks({
            groupId: '200',
            contextType: 'Course',
            contextId: '2',
            withMorePage: false
          }),
          ...groupMocks({groupId: '300', childGroupOffset: 400}),
          ...groupDetailMocks({
            groupId: '300',
            contextType: 'Course',
            contextId: '2',
            withMorePage: false
          }),
          updateOutcomeGroupMock({
            id: '300',
            parentOutcomeGroupId: '201',
            title: null,
            description: null,
            vendorGuid: null
          })
        ]
      })
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Outcome Group Menu'))
      fireEvent.click(within(getByRole('menu')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      // Move Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runAllTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runAllTimers())
      expect(getByText('2 Outcomes')).toBeInTheDocument()
    })
  })

  describe('can_manage permissions are false', () => {
    beforeEach(() => {
      window.ENV = {
        PERMISSIONS: {
          manage_outcomes: false
        }
      }
    })

    it('ManageOutcomesFooter is not displayed', async () => {
      const {queryByTestId} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      expect(queryByTestId('manage-outcomes-footer')).not.toBeInTheDocument()
    })
  })

  it('shows move group modal if move option from group menu is selected', async () => {
    const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Outcome Group Menu'))
    fireEvent.click(within(getByRole('menu')).getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Where would you like to move this group?')).toBeInTheDocument()
  })

  it('shows edit group modal if edit option from group menu is selected', async () => {
    const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Outcome Group Menu'))
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Edit Group')).toBeInTheDocument()
  })
})
