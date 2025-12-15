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

import React from 'react'
import {MockedProvider} from '@apollo/client/testing'
import {act, render as rtlRender, fireEvent, waitFor} from '@testing-library/react'
import {within} from '@testing-library/dom'
import {createCache} from '@canvas/apollo-v3'
import OutcomeManagementPanel from '../index'
import OutcomesContext, {ACCOUNT_GROUP_ID} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {clickWithPending} from '@canvas/outcomes/react/helpers/testHelpers'
import {
  accountMocks,
  courseMocks,
  deleteOutcomeMock,
  groupDetailMocks,
  groupMocks,
  moveOutcomeMock,
  updateOutcomeGroupMock,
  createOutcomeGroupMocks,
} from '@canvas/outcomes/mocks/Management'
import axios from 'axios'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import * as useGroupDetail from '@canvas/outcomes/react/hooks/useGroupDetail'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))
vi.mock('@canvas/rce/RichContentEditor')
vi.mock('axios')
vi.useFakeTimers()
vi.mock('@canvas/outcomes/react/hooks/useGroupDetail', async () => {
  return {
    __esModule: true, //    <----- this __esModule: true is important
    ...(await vi.importActual('@canvas/outcomes/react/hooks/useGroupDetail')),
  }
})

// FOO-3827
describe('OutcomeManagementPanel', () => {
  let cache
  let defaultMocks
  let groupDetailDefaultProps
  let isMobileView = false
  let onLhsSelectedGroupIdChangedMock
  let handleFileDropMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  const defaultProps = (props = {}) => ({
    importNumber: 0,
    createdOutcomeGroupIds: [],
    onLhsSelectedGroupIdChanged: onLhsSelectedGroupIdChangedMock,
    handleFileDrop: handleFileDropMock,
    targetGroupIdsToRefetch: [],
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    importsTargetGroup: {},
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  beforeEach(() => {
    cache = createCache()
    onLhsSelectedGroupIdChangedMock = vi.fn()
    handleFileDropMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    window.ENV = {
      PERMISSIONS: {
        manage_outcomes: true,
      },
    }

    defaultMocks = [
      ...courseMocks({childGroupsCount: 2}),
      ...groupMocks({
        title: 'Course folder 0',
        groupId: '200',
        parentOutcomeGroupTitle: 'Root course folder',
        parentOutcomeGroupId: '2',
      }),
      ...groupDetailMocks({
        title: 'Course folder 0',
        groupDescription: 'Course folder 0 group description',
        groupId: '200',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
      ...groupDetailMocks({
        title: 'Course folder 1',
        groupDescription: 'Course folder 1 group description',
        groupId: '2',
        contextType: 'Course',
        contextId: '2',
        withMorePage: false,
      }),
    ]

    groupDetailDefaultProps = {
      contextType: 'Course',
      contextId: '2',
      mocks: defaultMocks,
    }
  })

  afterEach(() => {
    vi.clearAllMocks()
  })

  afterAll(() => {
    window.ENV = null
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      canManage = true,
      mocks = accountMocks({childGroupsCount: 0}),
      renderer = rtlRender,
      treeBrowserRootGroupId = '1',
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            canManage,
            isMobileView,
            rootIds: [ACCOUNT_GROUP_ID],
            treeBrowserRootGroupId,
          },
        }}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>,
    )
  }

  it('renders the tree browser for empty root groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 0}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Root account folder')).toBeInTheDocument()
  })

  it('loads outcome group data for Account', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: accountMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root account folder')).toBeInTheDocument()
    expect(getByText('Account folder 0')).toBeInTheDocument()
    expect(getByText('Account folder 1')).toBeInTheDocument()
  })

  it('loads outcome group data for Course', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      contextType: 'Course',
      contextId: '2',
      mocks: courseMocks({childGroupsCount: 2}),
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText(/Outcome Groups/)).toBeInTheDocument()
    expect(getByText('Root course folder')).toBeInTheDocument()
    expect(getByText('Course folder 0')).toBeInTheDocument()
    expect(getByText('Course folder 1')).toBeInTheDocument()
  })

  it('loads nested groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: [
        ...accountMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '100'}),
        ...groupDetailMocks({groupId: '100', contextType: 'Account', contextId: '1'}),
      ],
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Group 100 folder 0')).toBeInTheDocument()
  })

  it('displays a screen reader error and text error on failed request for course outcome groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      contextType: 'Course',
      contextId: '2',
      mocks: [],
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading course learning outcome groups.',
      srOnly: true,
      type: 'error',
    })
    expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
  })

  it('displays a screen reader error and text error on failed request for account outcome groups', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: [],
    })
    await act(async () => vi.runOnlyPendingTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      srOnly: true,
      type: 'error',
    })
    expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
  })

  it('displays a flash alert if a child group fails to load', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      mocks: [...accountMocks({childGroupsCount: 2})],
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'An error occurred while loading account learning outcome groups.',
      type: 'error',
      srOnly: false,
    })
  })

  it('loads group detail data correctly', async () => {
    const {getByText, getAllByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    expect(getAllByText('Outcome 2 - Course folder 0')).toHaveLength(2)
  })

  it('shows and closes Find Outcomes modal if Add Outcomes option from group menu is selected', async () => {
    const {getByText, queryByText, getByTestId, getByRole} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(within(getByRole('menu')).getByText('Add Outcomes'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Add Outcomes to "Course folder 0"')).toBeInTheDocument()
    fireEvent.click(within(getByTestId('find-outcomes-modal')).getByText('Done'))
    // Run all timers to remove the modal from the DOM
    await act(async () => vi.runAllTimers())
    expect(queryByText('Add Outcomes to "Course folder 0"')).not.toBeInTheDocument()
  })

  it('shows remove group modal if remove option from group menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Remove Group?')).toBeInTheDocument()
  })

  it('hides the "Outcome Group Menu" for the root group', async () => {
    const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Root course folder'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Menu for group Course folder 0')).not.toBeInTheDocument()
  })

  describe('Removing a group', () => {
    let mocks

    beforeEach(() => {
      mocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        ...groupDetailMocks({
          title: 'Course folder 1',
          groupDescription: 'Course folder 1 group description',
          groupId: '2',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        ...groupMocks({
          groupId: '300',
          childGroupOffset: 400,
          parentOutcomeGroupTitle: 'Course folder 0',
          parentOutcomeGroupId: '200',
        }),
        ...groupDetailMocks({
          groupId: '300',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
      ]
      axios.delete.mockResolvedValue({status: 200})
    })

    it(
      'clears selected outcomes',
      async () => {
        const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
          ...groupDetailDefaultProps,
          mocks,
        })
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(getByText('Course folder 0'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(getByText('Group 200 folder 0'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(getByText('Select outcome Outcome 1 - Group 300'))
        expect(getByText('1 Outcome Selected')).toBeInTheDocument()
        fireEvent.click(getByText('Menu for group Group 200 folder 0'))
        fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(getByText('Remove Group'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
      },
      10000,
    )

    it(
      'Show parent group in the RHS',
      async () => {
        const {getByText, queryByText, getByTestId} = render(
          <OutcomeManagementPanel {...defaultProps()} />,
          {
            ...groupDetailDefaultProps,
            mocks,
          },
        )
        await act(async () => vi.runOnlyPendingTimers())
        // OutcomeManagementPanel Group Tree Browser
        fireEvent.click(getByText('Course folder 0'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
        fireEvent.click(getByText('Group 200 folder 0'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(queryByText('Course folder 0 Outcomes')).not.toBeInTheDocument()
        // OutcomeManagementPanel Outcome Group Kebab Menu
        fireEvent.click(getByText('Menu for group Group 200 folder 0'))
        fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
        await act(async () => vi.runOnlyPendingTimers())
        // Remove Modal
        fireEvent.click(getByText('Remove Group'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByText('Course folder 0 Outcomes')).toBeInTheDocument()
      },
      10000,
    )
  })

  it('selects/unselects outcome via checkbox', async () => {
    const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    const outcome = getByText('Select outcome Outcome 1 - Course folder 0')
    fireEvent.click(outcome)
    expect(getByText('1 Outcome Selected')).toBeInTheDocument()
    fireEvent.click(outcome)
    expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
  })

  it('shows remove outcome modal if remove option from individual outcome menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Remove Outcome?')).toBeInTheDocument()
  })

  it('shows edit outcome modal if edit option from individual outcome menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    expect(getByText('Edit Outcome')).toBeInTheDocument()
  })

  it('shows move outcome modal if move option from individual outcome menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-move'))
    expect(getByText('Where would you like to move this outcome?')).toBeInTheDocument()
  })

  it('clears selected outcome when remove outcome modal is closed', async () => {
    const {getByText, queryByText, getByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Remove Outcome?')).not.toBeInTheDocument()
  })

  it('Removes outcome from the list', async () => {
    const {queryByText, getByText, getByTestId, getAllByText} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
        mocks: [...defaultMocks, deleteOutcomeMock({ids: ['1']})],
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    expect(queryByText('2 Outcomes')).toBeInTheDocument()
    fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('bulk-remove-outcomes'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Outcome 1 - Course folder 0')).not.toBeInTheDocument()
    expect(queryByText('1 Outcome')).toBeInTheDocument()
  })

  it('Removes selected outcome from the selected outcomes popover', async () => {
    const {queryByText, getByText, getByTestId, getAllByText} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
        mocks: [...defaultMocks, deleteOutcomeMock({ids: ['1']})],
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
    fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
    expect(queryByText('1 Outcome Selected')).toBeInTheDocument()
    fireEvent.click(getByTestId('bulk-remove-outcomes'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(queryByText('Outcome 1 - Course folder 0')).not.toBeInTheDocument()
    expect(queryByText('0 Outcomes Selected')).toBeInTheDocument()
  })

  it('Displays spinner in document when a single outcome is removed', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-remove'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Remove Outcome'))
    expect(getByTestId('outcome-spinner')).toBeInTheDocument()
  })

  it('clears selected outcome when move outcome modal is closed', async () => {
    const {getByText, queryByText, getByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-move'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Cancel'))
    expect(queryByText('Move "Outcome 1 - Course folder 0"')).not.toBeInTheDocument()
  })

  it('should not disable search input and clear search button (X) if there are no results', async () => {
    const {getByText, getByLabelText, queryByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
        mocks: [
          ...defaultMocks,
          groupDetailMocks({
            title: 'Course folder 0',
            groupId: '200',
            contextType: 'Course',
            contextId: '2',
            searchQuery: 'no matched results',
            withMorePage: false,
          })[6],
        ],
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    await waitFor(() => expect(getByText('2 Outcomes')).toBeInTheDocument())
    fireEvent.change(getByLabelText('Search field'), {target: {value: 'no matched results'}})
    await act(async () => vi.advanceTimersByTime(500))
    await waitFor(() => expect(getByLabelText('Search field')).toBeEnabled())
    await waitFor(() => expect(queryByTestId('clear-search-icon')).toBeInTheDocument())
  })

  it('debounces search string typed by user', async () => {
    const {getByText, getByLabelText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
      mocks: [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[3],
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[5],
      ],
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('All Course folder 0 Outcomes')).toBeInTheDocument()

    const searchInput = getByLabelText('Search field')
    fireEvent.change(searchInput, {target: {value: 'Outcom'}})
    await act(async () => vi.advanceTimersByTime(200))
    expect(getByText('2 Outcomes')).toBeInTheDocument()

    fireEvent.change(searchInput, {target: {value: 'Outcome '}})
    await act(async () => vi.advanceTimersByTime(200))
    expect(getByText('2 Outcomes')).toBeInTheDocument()

    fireEvent.change(searchInput, {target: {value: 'Outcome 1'}})
    await act(async () => vi.advanceTimersByTime(500))
    await waitFor(() => expect(getByText('1 Outcome')).toBeInTheDocument())
  })

  describe('With manage_outcomes permission / canManage true', () => {
    it('displays outcome kebab menues', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(getByText('Menu for outcome Outcome 1 - Course folder 0')).toBeInTheDocument()
      expect(getByText('Menu for outcome Outcome 2 - Course folder 0')).toBeInTheDocument()
    })

    it('displays outcome checkboxes', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(getByText('Select outcome Outcome 1 - Course folder 0')).toBeInTheDocument()
      expect(getByText('Select outcome Outcome 2 - Course folder 0')).toBeInTheDocument()
    })

    it('enables users to bulk select and move outcomes', async () => {
      defaultMocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupDescription: 'Course folder 0 group description',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
          removeOnRefetch: true,
        }),
      ]
      const {getByText, getByRole, getAllByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks: [
            ...defaultMocks,
            moveOutcomeMock({
              groupId: '201',
            }),
          ],
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      expect(getByText('2 Outcomes Selected')).toBeInTheDocument()
      await clickWithPending(getAllByText('Move')[getAllByText('Move').length - 1])
      // Move Outcomes Modal
      await clickWithPending(within(getByRole('dialog')).getByText('Back'))
      await clickWithPending(within(getByRole('dialog')).getByText('Course folder 1'))
      await clickWithPending(within(getByRole('dialog')).getByText('Move'))
      await clickWithPending(getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    })
  })

  describe('Without manage_outcomes permission / canManage false', () => {
    it('hides outcome kebab menues', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        canManage: false,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(queryByText('Menu for outcome Outcome 1 - Course folder 0')).not.toBeInTheDocument()
      expect(queryByText('Menu for outcome Outcome 2 - Course folder 0')).not.toBeInTheDocument()
    })

    it('hides outcome checkboxes', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        canManage: false,
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithPending(getByText('Course folder 0'))
      expect(queryByText('Select outcome Outcome 1 - Course folder 0')).not.toBeInTheDocument()
      expect(queryByText('Select outcome Outcome 2 - Course folder 0')).not.toBeInTheDocument()
    })

    it('hides ManageOutcomesFooter', async () => {
      const {queryByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        canManage: false,
      })
      expect(queryByTestId('manage-outcomes-footer')).not.toBeInTheDocument()
    })
  })

  describe('Bulk remove outcomes', () => {
    it('shows bulk remove outcomes modal if outcomes are selected and remove button is clicked', async () => {
      const {findByText, getByText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(await findByText('Remove Outcomes?')).toBeInTheDocument()
    })

    it('outcome names are passed to the remove modal when using bulk remove', async () => {
      const {getByText, getByTestId, getAllByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      const itemOneTitle = getAllByTestId('outcome-management-item-title')[0].textContent
      const itemTwoTitle = getAllByTestId('outcome-management-item-title')[1].textContent
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      const removeModal = getByTestId('outcome-management-remove-modal')
      expect(await within(removeModal).findByText('Remove Outcomes?')).toBeInTheDocument()
      expect(await within(removeModal).findByText(itemOneTitle)).toBeInTheDocument()
      expect(await within(removeModal).findByText(itemTwoTitle)).toBeInTheDocument()
    })

    it('spinners show in the document when a bulk remove is pending', async () => {
      const {getByText, getByTestId, getAllByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getByTestId('bulk-remove-outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Remove Outcomes'))
      const spinners = getAllByTestId('outcome-spinner')
      expect(spinners).toHaveLength(2)
    })

    it(
      'updated group names are passed to the remove modal if a selected outcome is moved',
      async () => {
        const {findByText, getByTestId, findByTestId} = render(
          <OutcomeManagementPanel {...defaultProps()} />,
          {
            ...groupDetailDefaultProps,
            mocks: [
              ...defaultMocks,
              ...groupMocks({
                title: 'Course 101',
                groupId: '101',
                parentOutcomeGroupTitle: 'Root course folder',
                parentOutcomeGroupId: '2',
              }),
              moveOutcomeMock({
                groupId: '2',
                parentGroupTitle: 'Root course folder',
                outcomeLinkIds: ['1'],
              }),
            ],
          },
        )
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(await findByText('Course folder 0'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(await findByText('Select outcome Outcome 1 - Course folder 0'))
        fireEvent.click(await findByText('Select outcome Outcome 2 - Course folder 0'))
        fireEvent.click(await findByText('Menu for outcome Outcome 1 - Course folder 0'))
        fireEvent.click(getByTestId('outcome-kebab-menu-move'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(await findByText('Back'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(getByTestId('outcome-management-move-modal-move-button'))
        await act(async () => vi.runOnlyPendingTimers())
        fireEvent.click(await findByTestId('bulk-remove-outcomes'))
        await act(async () => vi.runOnlyPendingTimers())
        const removeModal = await findByTestId('outcome-management-remove-modal')
        expect(within(removeModal).getByText('From Root course folder')).toBeInTheDocument()
      },
      10000,
    )
  })

  describe('Bulk move outcomes', () => {
    it('shows bulk move outcomes modal if outcomes are selected and move button is clicked', async () => {
      const {getByText, getAllByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Move 2 Outcomes?')).toBeInTheDocument()
    })

    it('closes modal and clears selected outcomes when destination group for move is selected and "Move" button is clicked', async () => {
      const {getByText, getByRole, getAllByText, queryByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => vi.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
      expect(queryByText('Move 2 Outcomes?')).not.toBeInTheDocument()
    })

    it('refetch rhs when moving outcomes', async () => {
      const detailSpy = vi.spyOn(useGroupDetail, 'default')
      const {getByText, getByRole, getAllByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks: [
            ...defaultMocks,
            moveOutcomeMock({
              groupId: '201',
            }),
          ],
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      fireEvent.click(getAllByText('Move')[getAllByText('Move').length - 1])
      await act(async () => vi.runOnlyPendingTimers())
      // Move Outcomes Multi Modal
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Course folder 1'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(detailSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          rhsGroupIdsToRefetch: ['2', '200', '201', '300'],
        }),
      )
    })
  })

  describe('Moving a group', () => {
    let mocks

    beforeEach(() => {
      mocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({
          title: 'Course folder 0',
          groupId: '200',
          parentOutcomeGroupTitle: 'Root course folder',
          parentOutcomeGroupId: '2',
        }),
        ...groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        ...groupMocks({
          groupId: '300',
          childGroupOffset: 400,
          parentOutcomeGroupTitle: 'Course folder 0',
          parentOutcomeGroupId: '200',
        }),
        ...groupDetailMocks({
          groupId: '300',
          contextType: 'Course',
          contextId: '2',
          withMorePage: false,
        }),
        updateOutcomeGroupMock({
          id: '300',
          parentOutcomeGroupId: '2',
          title: null,
          returnTitle: 'Group 300',
          description: null,
          vendorGuid: null,
        }),
        ...createOutcomeGroupMocks({parentOutcomeGroupId: '2', title: 'new group name'}),
      ]
    })

    const moveSelectedGroup = async getByRole => {
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Move'))
      await act(async () => vi.runOnlyPendingTimers())
    }

    it('show old parent group in the RHS when moving a group succeeds', async () => {
      const {getByRole, getByText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Menu for group Group 200 folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      // Move Modal
      await act(async () => vi.runAllTimers())
      await moveSelectedGroup(getByRole)
      expect(getByText('2 Outcomes')).toBeInTheDocument()
    })

    it('shows groups created in the modal immediately on the LHS', async () => {
      const {getByText, getByRole, getByLabelText, getByTestId} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
          mocks,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Group Tree Browser
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Group 200 folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      // OutcomeManagementPanel Outcome Group Kebab Menu
      fireEvent.click(getByText('Menu for group Group 200 folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Back'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Create New Group'))
      fireEvent.change(getByLabelText('Enter new group name'), {
        target: {value: 'new group name'},
      })
      fireEvent.click(within(getByRole('dialog')).getByText('Create new group'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(within(getByRole('dialog')).getByText('Cancel'))
      await act(async () => vi.runAllTimers())
      expect(getByText('new group name')).toBeInTheDocument()
    })

    it('shows move group modal if move option from group menu is selected', async () => {
      const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Menu for group Course folder 0'))
      fireEvent.click(getByTestId('outcome-kebab-menu-move'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Where would you like to move this group?')).toBeInTheDocument()
    })
  })

  describe('Selected outcomes popover', () => {
    it('shows selected outcomes popover if outcomes are selected and Outcomes Selected link is clicked', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      const selectedOutcomesLink = getByText('2 Outcomes Selected').closest('button')
      fireEvent.click(selectedOutcomesLink)
      expect(selectedOutcomesLink).toBeEnabled()
      expect(selectedOutcomesLink).toHaveAttribute('aria-expanded')
    })

    it('closes popover and clears selected outcomes when Clear all link in popover is clicked', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Select outcome Outcome 1 - Course folder 0'))
      fireEvent.click(getByText('Select outcome Outcome 2 - Course folder 0'))
      const selectedOutcomesLink = getByText('2 Outcomes Selected').closest('button')
      fireEvent.click(selectedOutcomesLink)
      fireEvent.click(getByText('Clear all'))
      expect(selectedOutcomesLink.getAttribute('aria-disabled')).toBe('true')
      expect(selectedOutcomesLink.getAttribute('aria-expanded')).toBe('false')
      expect(getByText('0 Outcomes Selected')).toBeInTheDocument()
    })
  })

  // Need to move this bellow since somehow this spec is triggering an infinite loop
  // in runAllTimers above if we put this spec before it
  it('clears selected outcome when edit outcome modal is closed', async () => {
    const {getByText, queryByText, getByTestId} = render(
      <OutcomeManagementPanel {...defaultProps()} />,
      {
        ...groupDetailDefaultProps,
      },
    )
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for outcome Outcome 1 - Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    fireEvent.click(getByText('Cancel'))
    await act(async () => vi.advanceTimersByTime(500))
    expect(queryByText('Edit Outcome')).not.toBeInTheDocument()
  })

  it('shows edit group modal if edit option from group menu is selected', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    await act(async () => vi.runOnlyPendingTimers())
    expect(getByText('Edit Group')).toBeInTheDocument()
  })

  it('shows selected group title within edit group modal', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    await act(async () => vi.runOnlyPendingTimers())
    const editModal = getByTestId('outcome-management-edit-modal')
    expect(within(editModal).getByDisplayValue('Course folder 0')).toBeInTheDocument()
  })

  it('shows selected group description within edit group modal', async () => {
    const {getByText, getByTestId} = render(<OutcomeManagementPanel {...defaultProps()} />, {
      ...groupDetailDefaultProps,
    })
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Course folder 0'))
    await act(async () => vi.runOnlyPendingTimers())
    fireEvent.click(getByText('Menu for group Course folder 0'))
    fireEvent.click(getByTestId('outcome-kebab-menu-edit'))
    await act(async () => vi.runOnlyPendingTimers())
    const editModal = getByTestId('outcome-management-edit-modal')
    expect(within(editModal).getByTestId('group-description-input')).toBeInTheDocument()
  })

  describe('Search input', () => {
    let searchInputMocks

    beforeEach(() => {
      searchInputMocks = [
        ...courseMocks({childGroupsCount: 2}),
        ...groupMocks({groupId: '200'}),
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[3],
        groupDetailMocks({
          title: 'Course folder 0',
          groupId: '200',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 1',
          withMorePage: false,
        })[5],
        ...groupMocks({groupId: '201', childGroupOffset: 400}),
        groupDetailMocks({
          title: 'Course folder 1',
          groupId: '201',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 2',
          withMorePage: false,
        })[3],
        groupDetailMocks({
          title: 'Course folder 1',
          groupId: '201',
          contextType: 'Course',
          contextId: '2',
          searchQuery: 'Outcome 2',
          withMorePage: false,
        })[5],
      ]
    })

    it('should not clear search input if same group is selected/toggled', async () => {
      const {getByText, getByLabelText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        mocks: searchInputMocks,
      })
      await act(async () => vi.runOnlyPendingTimers())
      const courseFolder = getByText('Course folder 0')
      fireEvent.click(courseFolder)
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('2 Outcomes')).toBeInTheDocument()
      fireEvent.change(getByLabelText('Search field'), {target: {value: 'Outcome 1'}})
      await act(async () => vi.runOnlyPendingTimers())
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('1 Outcome')).toBeInTheDocument()
      fireEvent.click(courseFolder)
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('1 Outcome')).toBeInTheDocument()
      expect(getByLabelText('Search field')).toHaveValue('Outcome 1')
    })

    it('should clear search input if different group is selected', async () => {
      const {getByText, getByLabelText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        ...groupDetailDefaultProps,
        mocks: searchInputMocks,
      })
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('2 Outcomes')).toBeInTheDocument()
      fireEvent.change(getByLabelText('Search field'), {target: {value: 'Outcome 1'}})
      await act(async () => vi.runOnlyPendingTimers())
      await act(async () => vi.advanceTimersByTime(500))
      expect(getByText('1 Outcome')).toBeInTheDocument()
      fireEvent.click(getByText('Course folder 1'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('2 Outcomes')).toBeInTheDocument()
      expect(getByLabelText('Search field')).toHaveValue('')
    })
  })

  describe('After an outcome is added', () => {
    it('it does not trigger a refetch if an outcome is created but not in the currently selected group', async () => {
      const {getByText, queryByText, rerender} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      render(<OutcomeManagementPanel {...defaultProps({createdOutcomeGroupIds: ['2']})} />, {
        ...groupDetailDefaultProps,
        renderer: rerender,
      })
      await act(async () => vi.runOnlyPendingTimers())
      expect(queryByText(/Newly Created Outcome/)).not.toBeInTheDocument()
    })

    it('it does trigger a refetch if an outcome is created is in currently selected group in RHS', async () => {
      const {getByText, getAllByText, rerender} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())

      render(<OutcomeManagementPanel {...defaultProps({createdOutcomeGroupIds: ['200']})} />, {
        ...groupDetailDefaultProps,
        renderer: rerender,
      })
      await act(async () => vi.runOnlyPendingTimers())
      expect(getAllByText('Newly Created Outcome - Course folder 0')).toHaveLength(2)
    })
  })

  describe('After outcomes import', () => {
    it('resets targetGroupIdsToRefetch', () => {
      render(<OutcomeManagementPanel {...defaultProps({targetGroupIdsToRefetch: ['200']})} />)
      expect(setTargetGroupIdsToRefetchMock).toHaveBeenCalledTimes(1)
      expect(setTargetGroupIdsToRefetchMock).toHaveBeenCalledWith([])
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      isMobileView = true
    })

    afterEach(() => {
      isMobileView = false
    })

    const clickWithinMobileSelect = async selectNode => {
      fireEvent.click(selectNode)
      await act(async () => vi.runOnlyPendingTimers())
    }

    it('renders the action drilldown', async () => {
      const {getByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        mocks: accountMocks({childGroupsCount: 2}),
      })
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Groups')).toBeInTheDocument()
    })

    it('renders the groups within the drilldown', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        mocks: accountMocks({childGroupsCount: 2}),
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      expect(getByText('Account folder 0')).toBeInTheDocument()
      expect(getByText('Account folder 1')).toBeInTheDocument()
    })

    it('renders the action link for the root group', async () => {
      const {getByText, queryByText} = render(<OutcomeManagementPanel {...defaultProps()} />, {
        mocks: accountMocks({childGroupsCount: 2}),
      })
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      expect(getByText('View 0 Outcomes')).toBeInTheDocument()
    })

    it('loads group detail data correctly', async () => {
      const {getByText, queryByText, getAllByText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('View 2 Outcomes'))
      expect(getByText('All Course folder 0 Outcomes')).toBeInTheDocument()
      expect(getAllByText('Outcome 1 - Course folder 0')).toHaveLength(2)
      expect(getAllByText('Outcome 2 - Course folder 0')).toHaveLength(2)
    })

    it('focuses on the Select input after the group header is clicked', async () => {
      const {getByText, queryByText, getByPlaceholderText} = render(
        <OutcomeManagementPanel {...defaultProps()} />,
        {
          ...groupDetailDefaultProps,
        },
      )
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      fireEvent.click(getByText('Course folder 0'))
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('View 2 Outcomes'))
      fireEvent.click(getByText('Select another group'))
      expect(getByPlaceholderText('Select an outcome group')).toHaveFocus()
    })
  })
})
