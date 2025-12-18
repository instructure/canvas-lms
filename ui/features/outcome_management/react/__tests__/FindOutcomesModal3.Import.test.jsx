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
import {MockedProvider} from '@apollo/client/testing'
import {render as rtlRender, waitFor, act} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import OutcomesContext, {
  ACCOUNT_GROUP_ID,
  ROOT_GROUP_ID,
} from '@canvas/outcomes/react/contexts/OutcomesContext'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {
  findOutcomesMocks,
  groupMocks,
  importOutcomeMocks,
  treeGroupMocks,
} from '@canvas/outcomes/mocks/Management'
import {clickEl} from '@canvas/outcomes/react/helpers/testHelpers'
import resolveProgress from '@canvas/progress/resolve_progress'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.mock('@canvas/progress/resolve_progress')

const delayImportOutcomesProgress = () => {
  let realResolve
  resolveProgress.mockReturnValueOnce(
    new Promise(resolve => {
      realResolve = resolve
    }),
  )
  return realResolve
}

const defaultTreeGroupMocks = () =>
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

describe('FindOutcomesModal - Individual Outcome Import Tests', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  const withFindGroupRefetch = true

  const defaultProps = (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  const courseImportMocks = [
    ...findModalMocks(),
    ...groupMocks({groupId: '100'}),
    ...findOutcomesMocks({
      groupId: '300',
      isImported: false,
      contextType: 'Course',
      outcomesCount: 51,
      withFindGroupRefetch,
    }),
  ]

  beforeAll(() => {
    window.ENV = {}
  })

  beforeEach(() => {
    vi.useFakeTimers()
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    cache = createCache()
  })

  afterEach(() => {
    vi.clearAllMocks()
    resolveProgress.mockReset()
    delete localStorage.activeImports
    vi.useRealTimers()
  })

  const render = (
    children,
    {
      contextType = 'Account',
      contextId = '1',
      mocks = findModalMocks(),
      renderer = rtlRender,
    } = {},
  ) => {
    return renderer(
      <OutcomesContext.Provider
        value={{
          env: {
            contextType,
            contextId,
            isMobileView: false,
            rootIds: [ACCOUNT_GROUP_ID, ROOT_GROUP_ID],
            rootOutcomeGroup: {id: '0'},
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

  const navigateToGroup = async getByText => {
    await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())
    await clickEl(getByText('Account Standards'))
    await waitFor(() => expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument())
    await clickEl(getByText('Root Account Outcome Group 0'))
    await waitFor(() => expect(getByText('Group 100 folder 0')).toBeInTheDocument())
    await clickEl(getByText('Group 100 folder 0'))
  }

  it('loads localstorage.activeImports if present', async () => {
    const doResolveProgress = delayImportOutcomesProgress()

    localStorage.activeImports = JSON.stringify([
      {
        outcomeOrGroupId: '1',
        isGroup: false,
        progress: {_id: '111', state: 'queued', __typename: 'Progress'},
      },
    ])

    const {getByText, queryByText, queryAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [...findModalMocks({parentAccountChildren: 1}), ...defaultTreeGroupMocks()],
    })

    await waitFor(() => expect(getByText('Account Standards')).toBeInTheDocument())
    await clickEl(getByText('Account Standards'))
    await waitFor(() => expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument())
    await clickEl(getByText('Root Account Outcome Group 0'))
    await waitFor(() => expect(getByText('Group 200')).toBeInTheDocument())
    await clickEl(getByText('Group 200'))
    await clickEl(getByText('Group 300'))
    await clickEl(getByText('Group 400'))

    expect(queryAllByText('Loading')).toHaveLength(1)

    await act(async () => {
      doResolveProgress()
      await vi.runAllTimersAsync()
    })
    await waitFor(() => expect(queryByText('Loading')).not.toBeInTheDocument())
    expect(queryAllByText('Added')).toHaveLength(1)
    expect(localStorage.activeImports).toEqual('[]')
  })

  it('handles outcome import button states correctly', async () => {
    const doResolveProgress = delayImportOutcomesProgress()

    const {getByText, getAllByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [
        ...courseImportMocks,
        ...importOutcomeMocks({
          outcomeId: '5',
          targetContextType: 'Course',
          sourceContextId: '1',
          sourceContextType: 'Account',
        }),
      ],
    })

    await navigateToGroup(getByText)

    const addButton = getAllByText('Add')[0].closest('button')
    await clickEl(addButton)

    // Verify loading state
    expect(getByText('Loading')).toBeInTheDocument()

    await act(async () => {
      doResolveProgress()
      await vi.runAllTimersAsync()
    })
    await waitFor(() => expect(queryByText('Loading')).not.toBeInTheDocument())

    // Verify completed state
    await waitFor(() => expect(getByText('Added')).toBeInTheDocument())
  })

  it('enables Add button if outcome import fails', async () => {
    const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
      contextType: 'Course',
      mocks: [
        ...courseImportMocks,
        ...importOutcomeMocks({
          outcomeId: '5',
          targetContextType: 'Course',
          sourceContextId: '1',
          sourceContextType: 'Account',
          failResponse: true,
        }),
      ],
    })

    await navigateToGroup(getByText)

    const addButton = getAllByText('Add')[0].closest('button')
    await clickEl(addButton)

    await waitFor(() => expect(addButton).toBeEnabled())
  })

  describe('imports to different contexts', () => {
    it('imports Account outcome to Course', async () => {
      const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
        mocks: [
          ...courseImportMocks,
          ...importOutcomeMocks({
            outcomeId: '5',
            targetContextType: 'Course',
            sourceContextId: '1',
            sourceContextType: 'Account',
          }),
        ],
      })

      await navigateToGroup(getByText)

      const addButton = getAllByText('Add')[0].closest('button')
      expect(addButton).toBeEnabled()
      await clickEl(addButton)

      await waitFor(() => {
        expect(getByText('Added')).toBeInTheDocument()
        expect(getByText('Added').closest('button')).toBeDisabled()
      })
    })

    it('imports Account outcome to Sub-account', async () => {
      const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Account',
        mocks: [
          ...findModalMocks(),
          ...groupMocks({groupId: '100'}),
          ...findOutcomesMocks({
            groupId: '300',
            isImported: false,
            contextType: 'Account',
            outcomesGroupContextId: '2',
            outcomesCount: 51,
            withFindGroupRefetch,
          }),
          ...importOutcomeMocks({
            outcomeId: '5',
            sourceContextId: '2',
            sourceContextType: 'Account',
          }),
        ],
      })

      await navigateToGroup(getByText)

      const addButton = getAllByText('Add')[0].closest('button')
      await clickEl(addButton)

      await waitFor(() => expect(getByText('Added').closest('button')).toBeDisabled())
    })

    it('imports Global outcome to Account', async () => {
      const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Account',
        mocks: [
          ...findModalMocks(),
          ...groupMocks({groupId: '100'}),
          ...findOutcomesMocks({
            groupId: '300',
            isImported: false,
            contextType: 'Account',
            outcomesGroupContextId: null,
            outcomesGroupContextType: null,
            outcomesCount: 51,
            withFindGroupRefetch,
          }),
          ...importOutcomeMocks({
            outcomeId: '5',
            sourceContextId: null,
            sourceContextType: null,
          }),
        ],
      })

      await navigateToGroup(getByText)

      const addButton = getAllByText('Add')[0].closest('button')
      await clickEl(addButton)

      await waitFor(() => expect(getByText('Added').closest('button')).toBeDisabled())
    })
  })

  describe('error handling', () => {
    it('displays custom error message when provided', async () => {
      const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
        mocks: [
          ...courseImportMocks,
          ...importOutcomeMocks({
            outcomeId: '5',
            targetContextType: 'Course',
            sourceContextId: '1',
            sourceContextType: 'Account',
            failResponse: true,
          }),
        ],
      })

      await navigateToGroup(getByText)
      await clickEl(getAllByText('Add')[0].closest('button'))

      await waitFor(() =>
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while importing this outcome: Network error.',
          type: 'error',
        }),
      )
    })

    it('displays generic error message when no error message provided', async () => {
      const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
        mocks: [
          ...courseImportMocks,
          ...importOutcomeMocks({
            outcomeId: '5',
            targetContextType: 'Course',
            sourceContextId: '1',
            sourceContextType: 'Account',
            failMutationNoErrMsg: true,
          }),
        ],
      })

      await navigateToGroup(getByText)
      await clickEl(getAllByText('Add')[0].closest('button'))

      await waitFor(() =>
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while importing this outcome.',
          type: 'error',
        }),
      )
    })
  })
})
