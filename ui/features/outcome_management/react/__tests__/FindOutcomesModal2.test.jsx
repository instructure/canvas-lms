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
import {act, render as rtlRender, fireEvent} from '@testing-library/react'
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
  importGroupMocks,
  treeGroupMocks,
} from '@canvas/outcomes/mocks/Management'
import {clickEl} from '@canvas/outcomes/react/helpers/testHelpers'
import resolveProgress from '@canvas/progress/resolve_progress'
import {ROOT_GROUP} from '@canvas/outcomes/react/hooks/useOutcomesImport'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(),
}))

jest.mock('@canvas/progress/resolve_progress')
jest.useFakeTimers()

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

// passes locally, flaky on Jenkins
describe('FindOutcomesModal', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  let isMobileView
  const withFindGroupRefetch = true
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
            isMobileView,
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

  const itBehavesLikeAModal = () => {
    it('renders component with "Add Outcomes to Account" title when contextType is Account', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
    })

    it('renders component with "Add Outcomes to Course" title when contextType is Course', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      await act(async () => jest.runAllTimers())
      expect(getByText('Add Outcomes to Course')).toBeInTheDocument()
    })

    it('renders component with "Add Outcomes to groupName" targetGroup is passed', async () => {
      const {getByText} = render(
        <FindOutcomesModal
          {...defaultProps({
            targetGroup: {
              _id: '1',
              title: 'The Group Title',
            },
          })}
        />,
        {
          contextType: 'Course',
        },
      )
      await act(async () => jest.runAllTimers())
      expect(getByText('Add Outcomes to "The Group Title"')).toBeInTheDocument()
    })

    it('shows modal if open prop true', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      expect(getByText('Close')).toBeInTheDocument()
    })

    it('does not show modal if open prop false', async () => {
      const {queryByText} = render(<FindOutcomesModal {...defaultProps({open: false})} />)
      await act(async () => jest.runAllTimers())
      expect(queryByText('Close')).not.toBeInTheDocument()
    })

    describe('error handling', () => {
      describe('within an account', () => {
        it('displays a screen reader error and text error on failed request', async () => {
          const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {mocks: []})
          await act(async () => jest.runAllTimers())
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: 'An error occurred while loading account learning outcome groups.',
            srOnly: true,
            type: 'error',
          })
          expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
        })
      })

      describe('within a course', () => {
        it('displays a screen reader error and text error on failed request', async () => {
          const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
            contextType: 'Course',
            mocks: [],
          })
          await act(async () => jest.runAllTimers())
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: 'An error occurred while loading course learning outcome groups.',
            srOnly: true,
            type: 'error',
          })
          expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
        })
      })
    })
  }

  const itBehavesLikeATreeBrowser = () => {
    const clickWithinMobileSelect = async selectNode => {
      if (isMobileView) {
        fireEvent.click(selectNode)
        await act(async () => jest.runAllTimers())
      }
    }

    it('clears selected outcome group for the outcomes view after closing and reopening', async () => {
      const {getByText, queryByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => jest.runAllTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      fireEvent.click(getByText('Account Standards'))
      fireEvent.click(getByText('Root Account Outcome Group 0'))
      await act(async () => jest.runAllTimers())
      await clickWithinMobileSelect(queryByText('View 0 Outcomes'))
      await act(async () => jest.runAllTimers())
      expect(getByText('All Root Account Outcome Group 0 Outcomes')).toBeInTheDocument()
      fireEvent.click(getByText('Done'))
      render(<FindOutcomesModal {...defaultProps({open: false})} />, {renderer: rerender})
      await act(async () => jest.runAllTimers())
      render(<FindOutcomesModal {...defaultProps()} />, {renderer: rerender})
      await act(async () => jest.runAllTimers())
      expect(queryByText('All Root Account Outcome Group 0 Outcomes')).not.toBeInTheDocument()
    })

    describe('within an account context', () => {
      it('renders Account Standards groups for non root accounts', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />)
        await act(async () => jest.runAllTimers())
        await clickWithinMobileSelect(queryByText('Groups'))
        fireEvent.click(getByText('Account Standards'))
        await act(async () => jest.runAllTimers())
        expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument()
      })

      it('Does not render Account Standards groups for root accounts', async () => {
        const {queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({parentAccountChildren: 0}),
        })
        await act(async () => jest.runAllTimers())
        expect(queryByText('Account Standards')).not.toBeInTheDocument()
      })
    })

    it('displays a flash alert when a child group fails to load', async () => {
      const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      await act(async () => jest.runAllTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      await clickEl(getByText('Account Standards'))
      await clickEl(getByText('Course Account Outcome Group'))
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'An error occurred while loading course learning outcome groups.',
        type: 'error',
        srOnly: false,
      })
    })

    describe('global standards', () => {
      it('renders the State Standards group and subgroups', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({includeGlobalRootGroup: true}),
          globalRootId: '1',
        })
        await act(async () => jest.runAllTimers())
        await clickWithinMobileSelect(queryByText('Groups'))
        fireEvent.click(getByText('State Standards'))
        await act(async () => jest.runAllTimers())
      })

      it('does not render the State Standard group if no globalRootId is set', async () => {
        const {queryByText, getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({includeGlobalRootGroup: true}),
        })
        await act(async () => jest.runAllTimers())
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
        expect(queryByText('State Standards')).not.toBeInTheDocument()
      })

      it('does not list outcomes within the State Standard group', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: [...findModalMocks({includeGlobalRootGroup: true}), ...groupMocks({groupId: '1'})],
          globalRootId: '1',
        })
        await act(async () => jest.runAllTimers())
        await clickWithinMobileSelect(queryByText('Groups'))
        fireEvent.click(getByText('State Standards'))
        await act(async () => jest.runAllTimers())
        expect(getByText('Select a group to reveal outcomes here.')).toBeInTheDocument()
      })
    })
  }

  describe('Desktop', () => {
    beforeEach(() => {
      isMobileView = false
    })
    itBehavesLikeAModal()
    itBehavesLikeATreeBrowser()

    describe('group import', () => {
      it('imports group without ConfirmationBox if Add All Outcomes button is clicked in Account context', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Account',
          mocks: [
            ...findModalMocks(),
            ...groupMocks({groupId: '100'}),
            ...findOutcomesMocks({groupId: '300', withFindGroupRefetch}),
            ...importGroupMocks({groupId: '300'}),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(setImportsTargetGroupMock).toHaveBeenCalledTimes(1)
        expect(setImportsTargetGroupMock).toHaveBeenCalledWith({300: ROOT_GROUP})
        expect(setTargetGroupIdsToRefetchMock).toHaveBeenCalledTimes(1)
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'All outcomes from Group 300 have been successfully added to this account.',
          type: 'success',
        })
      })

      it('imports group without ConfirmationBox if Add All Outcomes button is clicked in Course context and outcomes <= 50', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...findModalMocks(),
            ...groupMocks({groupId: '100'}),
            ...findOutcomesMocks({
              groupId: '300',
              isImported: false,
              contextType: 'Course',
              outcomesCount: 50,
              withFindGroupRefetch,
            }),
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'All outcomes from Group 300 have been successfully added to this course.',
          type: 'success',
        })
      })

      it('disables Add All Outcomes button during/after group import', async () => {
        const {getByText, getAllByText, getByRole} = render(
          <FindOutcomesModal {...defaultProps()} />,
          {
            contextType: 'Course',
            mocks: [
              ...courseImportMocks,
              ...importGroupMocks({
                groupId: '300',
                targetContextType: 'Course',
              }),
            ],
          },
        )

        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))

        // Get the Add All Outcomes button and verify it's enabled
        const addAllButton = getByRole('button', {name: 'Add All Outcomes'})
        expect(addAllButton).toBeEnabled()

        // Click the button to start the import
        await clickEl(addAllButton)

        // Click Import Anyway on the confirmation dialog
        const importButtons = getAllByText('Import Anyway')
        fireEvent.click(importButtons[0])

        // Simulate the progress completion
        resolveProgress.mockImplementation(() => Promise.resolve())

        // Wait for the import status to update
        await act(async () => {
          jest.runAllTimers()
          await Promise.resolve()
        })

        // Get the button again after the import and verify it's disabled
        const updatedButton = getByRole('button', {name: 'Add All Outcomes'})
        expect(updatedButton).toBeDisabled()
      })

      it('imports outcomes with ConfirmationBox if Add All Outcomes button is clicked in Course context and outcomes > 50', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...courseImportMocks,
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(getByText('You are about to add 51 outcomes to this course.')).toBeInTheDocument()
        await clickEl(getByText('Cancel'))
      })

      it('returns focus on Add All Outcomes button if Cancel button of ConfirmationBox is clicked', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: courseImportMocks,
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        const AddAllButton = getByText('Add All Outcomes').closest('button')
        await clickEl(AddAllButton)
        expect(getByText('You are about to add 51 outcomes to this course.')).toBeInTheDocument()
        expect(AddAllButton).not.toHaveFocus()
        await clickEl(getByText('Cancel'))
        expect(AddAllButton).toHaveFocus()
      })

      it('returns focus on Done button if Import Anyway button of ConfirmationBox is clicked', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: courseImportMocks,
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        const DoneButton = getByText('Done').closest('button')
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(getByText('You are about to add 51 outcomes to this course.')).toBeInTheDocument()
        expect(DoneButton).not.toHaveFocus()
        await clickEl(getByText('Import Anyway'))
        expect(DoneButton).toHaveFocus()
      })

      it('enables Add All Outcomes button if group import fails', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...courseImportMocks,
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
              failResponse: true,
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        const AddAllButton = getByText('Add All Outcomes').closest('button')
        await clickEl(AddAllButton)
        await clickEl(getByText('Import Anyway'))
        expect(AddAllButton).toBeEnabled()
      })

      it('replaces Add buttons of individual outcomes with loading spinner during group import', async () => {
        const doResolveProgress = delayImportOutcomesProgress()
        const {getByText, getAllByText, queryByText} = render(
          <FindOutcomesModal {...defaultProps()} />,
          {
            contextType: 'Course',
            mocks: [
              ...courseImportMocks,
              ...importGroupMocks({
                groupId: '300',
                targetContextType: 'Course',
              }),
            ],
          },
        )
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        expect(getAllByText('Add')).toHaveLength(2)
        await clickEl(getByText('Add All Outcomes').closest('button'))
        await clickEl(getByText('Import Anyway'))
        expect(getAllByText('Loading')).toHaveLength(2)
        await act(async () => doResolveProgress())
        expect(queryByText('Loading')).not.toBeInTheDocument()
        expect(getAllByText('Added')).toHaveLength(2)
      })

      it('replaces Add buttons of individual outcomes with loading spinner during group import or a parent group', async () => {
        const doResolveProgress = delayImportOutcomesProgress()

        const {getByText, getAllByText, queryByText} = render(
          <FindOutcomesModal {...defaultProps()} />,
          {
            contextType: 'Course',
            mocks: [
              ...findModalMocks({parentAccountChildren: 1}),
              ...defaultTreeGroupMocks(),
              ...importGroupMocks({
                groupId: '200',
                targetContextType: 'Course',
              }),
            ],
          },
        )
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 200'))
        await clickEl(getByText('Add All Outcomes').closest('button'))

        // loading for outcome 1, 2, 3
        expect(getAllByText('Loading')).toHaveLength(3)
        await clickEl(getByText('Group 300'))
        await clickEl(getByText('Group 400'))

        // loading for outcome 1
        expect(getAllByText('Loading')).toHaveLength(1)
        await act(async () => doResolveProgress())
        expect(queryByText('Loading')).not.toBeInTheDocument()
        expect(getAllByText('Added')).toHaveLength(1)

        // disables Add All Outcomes button for child groups
        expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
        await clickEl(getByText('Group 200'))

        // disables Add All Outcomes button for the group
        expect(getByText('Add All Outcomes').closest('button')).toBeDisabled()
      })

      it('refetches outcomes if parent/ancestor group is selected after group import', async () => {
        const doResolveProgress = delayImportOutcomesProgress()

        const {getByText, getAllByText, queryByText} = render(
          <FindOutcomesModal {...defaultProps()} />,
          {
            contextType: 'Course',
            mocks: [
              ...findModalMocks({parentAccountChildren: 1}),
              ...defaultTreeGroupMocks(),
              ...importGroupMocks({
                groupId: '300',
                targetContextType: 'Course',
              }),
            ],
          },
        )
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))

        // select group with outcomes 1, 2, 3 and add it to course
        await clickEl(getByText('Group 200'))
        await clickEl(getByText('Group 300'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(getAllByText('Loading')).toHaveLength(3)

        // finish import
        await act(async () => doResolveProgress())
        expect(queryByText('Loading')).not.toBeInTheDocument()
        expect(getAllByText('Added')).toHaveLength(3)

        // select parent/ancestor group
        await clickEl(getByText('Group 200'))
        expect(getByText('All Refetched Group 200 Outcomes')).toBeInTheDocument()
      })

      it('does not refetch outcomes if no group is selected after group import', async () => {
        const doResolveProgress = delayImportOutcomesProgress()

        const {getByText, getAllByText, queryByText} = render(
          <FindOutcomesModal {...defaultProps()} />,
          {
            contextType: 'Course',
            mocks: [
              ...findModalMocks({parentAccountChildren: 1}),
              ...defaultTreeGroupMocks(),
              ...importGroupMocks({
                groupId: '300',
                targetContextType: 'Course',
              }),
            ],
          },
        )
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))

        // select group with outcomes 1, 2, 3 and add it to course
        await clickEl(getByText('Group 200'))
        await clickEl(getByText('Group 300'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(getAllByText('Loading')).toHaveLength(3)

        // finish import
        await act(async () => doResolveProgress())
        expect(queryByText('Loading')).not.toBeInTheDocument()
        expect(getAllByText('Added')).toHaveLength(3)
        expect(queryByText('All Refetched Group 200 Outcomes')).not.toBeInTheDocument()
      })

      it('loads localstorage.activeImports if present', async () => {
        const doResolveProgress = delayImportOutcomesProgress()

        localStorage.activeImports = JSON.stringify([
          {
            outcomeOrGroupId: '300',
            isGroup: true,
            groupTitle: 'Group 300',
            progress: {_id: '111', state: 'queued', __typename: 'Progress'},
          },
        ])

        const {getByText, getAllByText, queryByText} = render(
          <FindOutcomesModal {...defaultProps()} />,
          {
            contextType: 'Course',
            mocks: [...findModalMocks({parentAccountChildren: 1}), ...defaultTreeGroupMocks()],
          },
        )
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 200'))

        // No loading since we've imported group 300
        expect(queryByText('Loading')).not.toBeInTheDocument()

        await clickEl(getByText('Group 300'))
        // group 300 is loading. length 3 means outcome 1, 2, 3
        expect(getAllByText('Loading')).toHaveLength(3)
        await act(async () => doResolveProgress())
        expect(queryByText('Loading')).not.toBeInTheDocument()
        expect(getAllByText('Added')).toHaveLength(3)
        // resets latestImport after progress is resolved
        expect(localStorage.latestImport).toBeUndefined()
      })

      it('changes button text of individual outcomes from Add to Added after group import completes', async () => {
        const {getByText, getAllByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...courseImportMocks,
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        expect(getAllByText('Add')).toHaveLength(2)
        await clickEl(getByText('Add All Outcomes').closest('button'))
        await clickEl(getByText('Import Anyway'))
        expect(getAllByText('Added')).toHaveLength(2)
      })

      it('displays flash confirmation with proper message if group import to Course succeeds', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...courseImportMocks,
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        await clickEl(getByText('Import Anyway'))
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'All outcomes from Group 300 have been successfully added to this course.',
          type: 'success',
        })
      })

      it('displays flash confirmation with proper message if group import to Account succeeds', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Account',
          mocks: [
            ...findModalMocks(),
            ...groupMocks({groupId: '100'}),
            ...findOutcomesMocks({groupId: '300', withFindGroupRefetch}),
            ...importGroupMocks({groupId: '300'}),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'All outcomes from Group 300 have been successfully added to this account.',
          type: 'success',
        })
      })

      it('displays flash confirmation with proper message if group import to targetGroup succeeds', async () => {
        const {getByText} = render(
          <FindOutcomesModal
            {...defaultProps({
              targetGroup: {
                _id: '1',
                title: 'The Group Title',
              },
            })}
          />,
          {
            contextType: 'Account',
            mocks: [
              ...findModalMocks(),
              ...groupMocks({groupId: '100'}),
              ...findOutcomesMocks({groupId: '300', withFindGroupRefetch}),
              ...importGroupMocks({groupId: '300', targetGroupId: '1'}),
            ],
          },
        )
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'All outcomes from Group 300 have been successfully added to The Group Title.',
          type: 'success',
        })
      })

      it('displays flash alert with custom error message if group import fails', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...courseImportMocks,
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
              failResponse: true,
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        await clickEl(getByText('Import Anyway'))
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while importing these outcomes: Network error.',
          type: 'error',
        })
      })

      it('displays flash alert with generic error message if group import fails and no error message', async () => {
        const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          contextType: 'Course',
          mocks: [
            ...courseImportMocks,
            ...importGroupMocks({
              groupId: '300',
              targetContextType: 'Course',
              failMutationNoErrMsg: true,
            }),
          ],
        })
        await act(async () => jest.runAllTimers())
        await clickEl(getByText('Account Standards'))
        await clickEl(getByText('Root Account Outcome Group 0'))
        await clickEl(getByText('Group 100 folder 0'))
        await clickEl(getByText('Add All Outcomes').closest('button'))
        await clickEl(getByText('Import Anyway'))
        expect(showFlashAlert).toHaveBeenCalledWith({
          message: 'An error occurred while importing these outcomes.',
          type: 'error',
        })
      })
    })
  })
})
