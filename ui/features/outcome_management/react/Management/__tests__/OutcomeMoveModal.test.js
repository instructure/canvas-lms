/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {MockedProvider} from '@apollo/react-testing'
import {render as realRender, act, fireEvent} from '@testing-library/react'
import {
  accountMocks,
  smallOutcomeTree,
  moveOutcomeMock,
  groupMocks,
} from '@canvas/outcomes/mocks/Management'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo'
import OutcomeMoveModal from '../OutcomeMoveModal'
import * as FlashAlert from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert')
jest.useFakeTimers()

describe('OutcomeMoveModal', () => {
  let cache
  let onCloseHandlerMock
  let onCleanupHandlerMock
  let showFlashAlertSpy
  let defaultMocks
  const generateOutcomes = (num, parentGroupId = '100') =>
    new Array(num).fill(0).reduce(
      (acc, _val, ind) => ({
        ...acc,
        [`${ind + 1}`]: {
          _id: `${101 + ind}`,
          linkId: `${ind + 1}`,
          title: `Outcome ${101 + ind}`,
          canUnlink: true,
          parentGroupId,
        },
      }),
      {}
    )

  const defaultProps = (props = {}) => ({
    isOpen: true,
    onCloseHandler: onCloseHandlerMock,
    onCleanupHandler: onCleanupHandlerMock,
    outcomes: generateOutcomes(1),
    initialTargetGroup: {
      id: '1',
      name: 'Root account folder',
    },
    ...props,
  })

  beforeEach(() => {
    cache = createCache()
    onCloseHandlerMock = jest.fn()
    onCleanupHandlerMock = jest.fn()
    showFlashAlertSpy = jest.spyOn(FlashAlert, 'showFlashAlert')
    defaultMocks = [
      ...accountMocks({childGroupsCount: 0}),
      ...groupMocks({
        childGroupsCount: 2,
        title: 'Root account folder',
        groupId: '1',
        childGroupTitlePrefix: 'Account folder',
        childGroupOffset: 100,
      }),
    ]
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      rootOutcomeGroup = {id: '100'},
      mocks = defaultMocks,
      treeBrowserRootGroupId = '1',
    } = {}
  ) => {
    return realRender(
      <OutcomesContext.Provider
        value={{env: {contextType, contextId, rootOutcomeGroup, treeBrowserRootGroupId}}}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('renders component with customized outcome title if single outcome provided', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Move "Outcome 101"?')).toBeInTheDocument()
  })

  it('renders component with generic outcome title if multiple outcomes provided', async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(2)})} />
    )
    await act(async () => jest.runAllTimers())
    expect(getByText('Move 2 Outcomes?')).toBeInTheDocument()
  })

  it('shows modal if open prop true', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    expect(getByText('Cancel')).toBeInTheDocument()
  })

  it('does not show modal if open prop false', async () => {
    const {queryByText} = render(<OutcomeMoveModal {...defaultProps({isOpen: false})} />)
    await act(async () => jest.runAllTimers())
    expect(queryByText('Cancel')).not.toBeInTheDocument()
  })

  it('calls onCloseHandlerMock on Close button click', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Close')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('calls onCloseHandlerMock on Cancel button click', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />)
    await act(async () => jest.runAllTimers())
    const closeBtn = getByText('Cancel')
    fireEvent.click(closeBtn)
    expect(onCloseHandlerMock).toHaveBeenCalledTimes(1)
  })

  it('enables the move button by default', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />, {
      mocks: [...smallOutcomeTree()],
    })
    await act(async () => jest.runAllTimers())
    expect(getByText('Move').closest('button')).toBeEnabled()
  })

  it('enables the move button when a child group is selected', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />, {
      mocks: [...defaultMocks, ...smallOutcomeTree()],
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runAllTimers())
    expect(getByText('Move').closest('button')).toBeEnabled()
  })

  it('single move: displays flash confirmation and calls onSuccess if move outcomes request succeeds for', async () => {
    const onSuccess = jest.fn()
    const {getByText} = render(<OutcomeMoveModal {...defaultProps({onSuccess})} />, {
      mocks: [
        ...defaultMocks,
        ...smallOutcomeTree('Account'),
        moveOutcomeMock({outcomeLinkIds: ['1']}),
      ],
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: '"Outcome 101" has been moved to "Account folder 1".',
      type: 'success',
    })
    expect(onSuccess).toHaveBeenCalledWith({
      movedOutcomeLinkIds: ['1'],
      groupId: '101',
      targetAncestorsIds: ['101', '1'],
    })
  })

  it('single move: displays flash error if move outcomes request fails', async () => {
    const {getByText} = render(<OutcomeMoveModal {...defaultProps()} />, {
      mocks: [
        ...defaultMocks,
        ...smallOutcomeTree('Account'),
        moveOutcomeMock({
          failResponse: true,
          outcomeLinkIds: ['1'],
        }),
      ],
    })
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving this outcome. Please try again.',
      type: 'error',
    })
  })

  it("single move: disables Move button if the outcome's parent is selected", async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(1, '101')})} />,
      {
        mocks: [
          ...defaultMocks,
          ...smallOutcomeTree('Account'),
          moveOutcomeMock({outcomeLinkIds: ['1']}),
        ],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    expect(getByText('Move').closest('button')).toBeDisabled()
  })

  it("bulk move: enables Move button even if an outcome's parent is selected", async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(2, '101')})} />,
      {
        mocks: [
          ...defaultMocks,
          ...smallOutcomeTree('Account'),
          moveOutcomeMock({outcomeLinkIds: ['1']}),
        ],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    expect(getByText('Move').closest('button')).toBeEnabled()
  })

  it('bulk move: displays flash confirmation and calls onSuccess if move outcomes request succeeds', async () => {
    const onSuccess = jest.fn()
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({onSuccess, outcomes: generateOutcomes(2)})} />,
      {
        mocks: [...defaultMocks, ...smallOutcomeTree(), moveOutcomeMock()],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: '2 outcomes have been moved to "Account folder 1".',
      type: 'success',
    })
    expect(onSuccess).toHaveBeenCalledWith({
      movedOutcomeLinkIds: ['1', '2'],
      groupId: '101',
      targetAncestorsIds: ['101', '1'],
    })
  })

  it('bulk move: displays flash error if move outcomes request fails', async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(2)})} />,
      {
        mocks: [
          ...defaultMocks,
          ...smallOutcomeTree(),
          moveOutcomeMock({
            failResponse: true,
          }),
        ],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving these outcomes. Please try again.',
      type: 'error',
    })
  })

  it('bulk move: displays flash error if move outcomes mutation fails', async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(2)})} />,
      {
        mocks: [
          ...defaultMocks,
          ...smallOutcomeTree(),
          moveOutcomeMock({
            failMutation: true,
          }),
        ],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving these outcomes. Please try again.',
      type: 'error',
    })
  })

  it('bulk move: displays flash default error if move outcomes mutation fails and error message is empty', async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(2)})} />,
      {
        mocks: [
          ...defaultMocks,
          ...smallOutcomeTree(),
          moveOutcomeMock({
            failMutationNoErrMsg: true,
          }),
        ],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving these outcomes. Please try again.',
      type: 'error',
    })
  })

  it('bulk move: displays flash generic error if move outcomes mutation partially succeeds', async () => {
    const {getByText} = render(
      <OutcomeMoveModal {...defaultProps({outcomes: generateOutcomes(2)})} />,
      {
        mocks: [
          ...defaultMocks,
          ...smallOutcomeTree(),
          moveOutcomeMock({
            partialSuccess: true,
          }),
        ],
      }
    )
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Account folder 1'))
    await act(async () => jest.runOnlyPendingTimers())
    fireEvent.click(getByText('Move'))
    await act(async () => jest.runOnlyPendingTimers())
    expect(showFlashAlertSpy).toHaveBeenCalledWith({
      message: 'An error occurred while moving these outcomes. Please try again.',
      type: 'error',
    })
  })
})
