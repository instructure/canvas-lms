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
  deleteOutcomeMock,
  groupDetailMocks,
  groupMocks,
  moveOutcomeMock,
  updateOutcomeGroupMock
} from '@canvas/outcomes/mocks/Management'
import * as api from '@canvas/outcomes/graphql/Management'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/rce/RichContentEditor')
jest.useFakeTimers()

describe('OutcomeManagementPanel', () => {
  let cache
  let showFlashAlertSpy
  let defaultMocks
  let groupDetailDefaultProps
  let isMobileView = false

  beforeEach(() => {
    cache = createCache()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')

    window.ENV = {
      PERMISSIONS: {
        manage_outcomes: true
      }
    }

    defaultMocks = [
      ...courseMocks({childGroupsCount: 2}),
      ...groupMocks({groupId: '200'}),
      ...groupDetailMocks({
        title: 'Course folder 0',
        description: 'Course folder 0 group description',
        groupId: '200',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false
      })
    ]

    groupDetailDefaultProps = {
      contextType: 'Course',
      contextId: '2',
      mocks: defaultMocks
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
    window.ENV = null
  })

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
      <OutcomesContext.Provider value={{env: {contextType, contextId, canManage, isMobileView}}}>
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders the tree browser for empty root groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: accountMocks({childGroupsCount: 0})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText('Root account folder')).toBeInTheDocument()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      mocks: accountMocks({childGroupsCount: 2})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root account folder')).toBeInTheDocument()
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Account folder 1')).toBeInTheDocument()
  })

  it('loads outcome group data for Course', async () => {
    const {getByText} = render(<OutcomeManagementPanel />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 2})
    })
    await act(async () => jest.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root course folder')).toBeInTheDocument()
    expect(getByText('Course folder 0')).toBeInTheDocument()
    expect(getByText('Course folder 1')).toBeInTheDocument()
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

  describe('Removing a group', () => {
    it('Show parent group in the RHS', async () => {
      // API mock
      jest.spyOn(api, 'removeOutcomeGroup').mockImplementation(() => Promise.resolve({status: 200}))

      const {getByText, queryByText, getByRole} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps,
        mocks: [
          ...courseMocks({childGroupsCount: 2}),
          ...groupMocks({groupId: '200'}),
          ...groupDetailMocks({
            title: 'Course folder 0',
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
          })
        ]
      })
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(queryByText('Course folder 0 Outcomes')).not.toBeInTheDocument()
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Outcome Group Menu'))
      fireEvent.click(within(getByRole('menu')).getByText('Remove'))
      await act(async () => jest.runOnlyPendingTimers())
      // Remove Modal
      fireEvent.click(getByText('Remove Group'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
    })
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
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('shows move outcome modal if move option from individual outcome menu is selected', async () => {
    const {getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Move'))
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

  it('Removes outcome from the list', async () => {
    const {queryByText, getByText, getAllByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps,
      mocks: [...defaultMocks, deleteOutcomeMock({ids: ['1']})]
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(queryByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
    expect(queryByText('2 Outcomes')).toBeInTheDocument()
    fireEvent.click(getAllByText('Select outcome')[0])
    fireEvent.click(getByRole('button', {name: /remove/i}))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(queryByText('Outcome 1 - Course folder 0')).not.toBeInTheDocument()
    expect(queryByText('1 Outcome')).toBeInTheDocument()
  })

  it('clears selected outcome when move outcome modal is closed', async () => {
    const {getByText, getAllByText, queryByText, getByRole} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getAllByText('Outcome Menu')[0])
    fireEvent.click(within(getByRole('menu')).getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
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
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
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
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
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

    it('outcome names are passed to the remove modal when using bulk remove', async () => {
      const {getByText, getAllByText, getByRole, getByTestId, getAllByTestId} = render(
        <OutcomeManagementPanel />,
        {
          ...groupDetailDefaultProps
        }
      )
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      const itemOneTitle = getAllByTestId('outcome-management-item-title')[0].textContent
      const itemTwoTitle = getAllByTestId('outcome-management-item-title')[1].textContent
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getByRole('button', {name: /remove/i}))
      await act(async () => jest.runOnlyPendingTimers())
      const removeModal = getByTestId('outcome-management-remove-modal')
      expect(within(removeModal).getByText('Remove Outcomes?')).toBeInTheDocument()
      expect(within(removeModal).getByText(itemOneTitle)).toBeInTheDocument()
      expect(within(removeModal).getByText(itemTwoTitle)).toBeInTheDocument()
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
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
      expect(queryByText('Move 2 Outcomes?')).not.toBeInTheDocument()
    })

    it('removes outcomes from the list if moving to group outside the selected group', async () => {
      const {getByText, getByRole, getAllByText, queryByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps,
        mocks: [
          ...defaultMocks,
          moveOutcomeMock({
            groupId: '201'
          })
        ]
      })
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => jest.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(queryByText('Outcome 1 - Course folder 0')).not.toBeInTheDocument()
    })

    it('keeps outcomes in the list if moving to the selected group', async () => {
      const {getByText, getByRole, getAllByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps,
        mocks: [
          ...defaultMocks,
          moveOutcomeMock({
            groupId: '200'
          })
        ]
      })
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => jest.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
    })

    it('keeps outcomes in the list if moving to a children group of the selected group', async () => {
      const {getByText, getByRole, getAllByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps,
        mocks: [
          ...defaultMocks,
          ...groupMocks({groupId: '200'}),
          ...groupDetailMocks({
            groupId: '300',
            contextType: 'Course',
            contextId: '2',
            withMorePage: false
          }),
          moveOutcomeMock({
            groupId: '300'
          })
        ]
      })
      await act(async () => jest.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => jest.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Group 200 folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Outcome 1 - Course folder 0')).toBeInTheDocument()
    })
  })

  describe('Moving a group', () => {
    const mocks = [
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
        parentOutcomeGroupId: '2',
        title: null,
        description: null,
        vendorGuid: null
      })
    ]

    const moveSelectedGroup = async getByRole => {
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => jest.runOnlyPendingTimers())
    }

    it('show old parent group in the RHS when moving a group succeeds', async () => {
      const {getByText, getByRole} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps,
        mocks
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
      // Move Modal
      await moveSelectedGroup(getByRole)
      expect(getByText('2 Outcomes')).toBeInTheDocument()
    })

    it('shows groups created in the modal immediately on the LHS', async () => {
      const newGroup = {
        id: 101,
        title: 'new group name',
        description: '',
        isRootGroup: false,
        parent_outcome_group: {id: '2'}
      }
      jest
        .spyOn(api, 'addOutcomeGroup')
        .mockImplementation(() => Promise.resolve({status: 200, data: newGroup}))
      const {getByText, getByRole, getByLabelText} = render(<OutcomeManagementPanel />, {
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
      fireEvent.click(within(getByRole('dialog')).getByText('Root course folder'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {
        target: {value: 'new group name'}
      })
      fireEvent.click(within(getByRole('dialog')).getByText('Create new group'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Cancel'))
      expect(getByText('new group name')).toBeInTheDocument()
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
  })

  describe('Selected outcomes popover', () => {
    it('shows selected outcomes popover if outcomes are selected and Outcomes Selected link is clicked', async () => {
      const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      const selectedOutcomesLink = getByText('2 Outcomes Selected')
      fireEvent.click(selectedOutcomesLink)
      expect(selectedOutcomesLink).not.toHaveAttribute('aria-disabled')
      expect(selectedOutcomesLink).toHaveAttribute('aria-expanded')
    })

    it('closes popover and clears selected outcomes when Clear all link in popover is clicked', async () => {
      const {getByText, getAllByText} = render(<OutcomeManagementPanel />, {
        ...groupDetailDefaultProps
      })
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => jest.runOnlyPendingTimers())
      fireEvent.click(getAllByText('Select outcome')[0])
      fireEvent.click(getAllByText('Select outcome')[1])
      const selectedOutcomesLink = getByText('2 Outcomes Selected')
      fireEvent.click(selectedOutcomesLink)
      fireEvent.click(getByText('Clear all'))
      expect(selectedOutcomesLink).toHaveAttribute('aria-disabled')
      expect(selectedOutcomesLink.getAttribute('aria-expanded')).toBe('false')
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
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

  it('shows selected group title within edit group modal', async () => {
    const {getByText, getByRole, getByTestId} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Outcome Group Menu'))
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runOnlyPendingTimers())
    const editModal = getByTestId('outcome-management-edit-modal')
    expect(within(editModal).getByDisplayValue('Course folder 0')).toBeInTheDocument()
  })

  it('shows selected group description within edit group modal', async () => {
    const {getByText, getByRole, getByTestId} = render(<OutcomeManagementPanel />, {
      ...groupDetailDefaultProps
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Outcome Group Menu'))
    fireEvent.click(within(getByRole('menu')).getByText('Edit'))
    await act(async () => jest.runOnlyPendingTimers())
    const editModal = getByTestId('outcome-management-edit-modal')
    expect(within(editModal).getByText('Group Description 4')).toBeInTheDocument()
  })

  describe('mobile', () => {
    beforeEach(() => {
      isMobileView = true
    })

    const clickWithinMobileSelect = async selectNode => {
      fireEvent.click(selectNode)
      await act(async () => jest.runOnlyPendingTimers())
    }

    it('renders the action drilldown', async () => {
      const {getByText} = render(<OutcomeManagementPanel />, {
        mocks: accountMocks({childGroupsCount: 2})
      })
      await act(async () => jest.runOnlyPendingTimers())
      expect(getByText('Groups')).toBeInTheDocument()
    })

    it.skip('renders the groups within the drilldown', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel />, {
        mocks: accountMocks({childGroupsCount: 2})
      })
      await act(async () => jest.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      expect(getByText('Account folder 0')).toBeInTheDocument()
      expect(getByText('Account folder 1')).toBeInTheDocument()
    })

    it.skip('renders the action link for the root group', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel />, {
        mocks: accountMocks({childGroupsCount: 2})
      })
      await act(async () => jest.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      expect(getByText('View 0 Outcomes')).toBeInTheDocument()
    })
  })
})
