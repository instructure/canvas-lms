/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import OutcomesContext, {
  ACCOUNT_GROUP_ID,
  ROOT_GROUP_ID,
} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {findOutcomesMocks, treeGroupMocks} from '@canvas/outcomes/mocks/Management'
import resolveProgress from '@canvas/progress/resolve_progress'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

jest.mock('@canvas/progress/resolve_progress')
jest.useFakeTimers()

treeGroupMocks({
  groupsStruct: {
    100: [200],
    200: [300],
    300: [400, 401, 402],
  },
  detailsStructure: {
    100: [1, 2, 3],
    200: [1, 2, 3],
    300: [1, 2, 3],
    400: [1],
    401: [2],
    402: [3],
  },
  contextId: '1',
  contextType: 'Course',
  findOutcomesTargetGroupId: '0',
  groupOutcomesNotImportedCount: {
    200: 3,
    300: 3,
  },
  withGroupDetailsRefetch: true,
})

describe('FindOutcomesModal', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock

  const defaultProps = (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  beforeEach(() => {
    onCloseHandlerMock = jest.fn()
    setTargetGroupIdsToRefetchMock = jest.fn()
    setImportsTargetGroupMock = jest.fn()
    cache = createCache()
    window.ENV = {}
  })

  afterEach(() => {
    jest.clearAllMocks()
    resolveProgress.mockReset()
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      mocks = findModalMocks(),
      renderer = rtlRender,
      globalRootId = '',
      rootOutcomeGroup = {id: '0'},
      rootIds = [ACCOUNT_GROUP_ID, ROOT_GROUP_ID, globalRootId],
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            globalRootId,
            rootIds,
            rootOutcomeGroup,
            treeBrowserRootGroupId: ROOT_GROUP_ID,
            treeBrowserAccountGroupId: ACCOUNT_GROUP_ID,
          },
        }}
      >
        <MockedProvider cache={cache} mocks={mocks}>
          {children}
        </MockedProvider>
      </OutcomesContext.Provider>,
    )
  }

  it('debounces the search string entered by the user', async () => {
    const {getByText, getByLabelText} = render(<FindOutcomesModal {...defaultProps()} />, {
      mocks: [...findModalMocks(), ...findOutcomesMocks()],
    })
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account Standards'))
    fireEvent.click(getByText('Root Account Outcome Group 0'))
    await act(async () => jest.runAllTimers())
    expect(getByText('25 Outcomes')).toBeInTheDocument()

    const input = getByLabelText('Search field')
    fireEvent.change(input, {target: {value: 'mathemati'}})
    await act(async () => jest.advanceTimersByTime(300))
    expect(getByText('25 Outcomes')).toBeInTheDocument()

    fireEvent.change(input, {target: {value: 'mathematic'}})
    await act(async () => jest.advanceTimersByTime(300))
    expect(getByText('25 Outcomes')).toBeInTheDocument()

    fireEvent.change(input, {target: {value: 'mathematics'}})
    await act(async () => jest.runAllTimers())
    await act(async () => jest.advanceTimersByTime(200))
    expect(getByText('15 Outcomes')).toBeInTheDocument()
  })

  it('should not disable search input and clear search button if there are no results', async () => {
    const {getByText, getByLabelText, queryByTestId} = render(
      <FindOutcomesModal {...defaultProps()} />,
      {
        mocks: [...findModalMocks(), ...findOutcomesMocks()],
      },
    )
    await act(async () => jest.runAllTimers())
    fireEvent.click(getByText('Account Standards'))
    fireEvent.click(getByText('Root Account Outcome Group 0'))
    await act(async () => jest.runAllTimers())
    await act(async () => jest.runAllTimers())
    expect(getByText('25 Outcomes')).toBeInTheDocument()

    const input = getByLabelText('Search field')
    fireEvent.change(input, {target: {value: 'no results'}})
    await act(async () => jest.runAllTimers())
    await act(async () => jest.advanceTimersByTime(200))
    expect(getByLabelText('Search field')).toBeEnabled()
    expect(queryByTestId('clear-search-icon')).toBeInTheDocument()
  })
})
