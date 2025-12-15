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
import {groupMocks} from '@canvas/outcomes/mocks/Management'
import resolveProgress from '@canvas/progress/resolve_progress'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.mock('@canvas/progress/resolve_progress')
vi.useFakeTimers()

// Local helper to replace clickEl from testHelpers (which uses vi)
const clickEl = async el => {
  fireEvent.click(el)
  await act(async () => vi.runOnlyPendingTimers())
}

// passes locally, flaky on Jenkins
describe('FindOutcomesModal', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  let isMobileView
  const defaultProps = (props = {}) => ({
    open: true,
    importsTargetGroup: {},
    onCloseHandler: onCloseHandlerMock,
    setTargetGroupIdsToRefetch: setTargetGroupIdsToRefetchMock,
    setImportsTargetGroup: setImportsTargetGroupMock,
    ...props,
  })

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    cache = createCache()
    window.ENV = {}
  })

  afterEach(() => {
    vi.clearAllMocks()
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
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
    })

    it('renders component with "Add Outcomes to Course" title when contextType is Course', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      await act(async () => vi.runOnlyPendingTimers())
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
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Add Outcomes to "The Group Title"')).toBeInTheDocument()
    })

    it('shows modal if open prop true', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Close')).toBeInTheDocument()
    })

    it('does not show modal if open prop false', async () => {
      const {queryByText} = render(<FindOutcomesModal {...defaultProps({open: false})} />)
      await act(async () => vi.runOnlyPendingTimers())
      expect(queryByText('Close')).not.toBeInTheDocument()
    })

    describe('error handling', () => {
      describe('within an account', () => {
        it('displays a screen reader error and text error on failed request', async () => {
          const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {mocks: []})
          await act(async () => vi.runOnlyPendingTimers())
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
          await act(async () => vi.runOnlyPendingTimers())
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
        await act(async () => vi.runOnlyPendingTimers())
      }
    }

    it('clears selected outcome group for the outcomes view after closing and reopening', async () => {
      const {getByText, queryByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('Groups'))
      fireEvent.click(getByText('Account Standards'))
      fireEvent.click(getByText('Root Account Outcome Group 0'))
      await act(async () => vi.runOnlyPendingTimers())
      await clickWithinMobileSelect(queryByText('View 0 Outcomes'))
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('All Root Account Outcome Group 0 Outcomes')).toBeInTheDocument()
      fireEvent.click(getByText('Done'))
      render(<FindOutcomesModal {...defaultProps({open: false})} />, {renderer: rerender})
      await act(async () => vi.runOnlyPendingTimers())
      render(<FindOutcomesModal {...defaultProps()} />, {renderer: rerender})
      await act(async () => vi.runOnlyPendingTimers())
      expect(queryByText('All Root Account Outcome Group 0 Outcomes')).not.toBeInTheDocument()
    })

    describe('within an account context', () => {
      it('renders Account Standards groups for non root accounts', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />)
        await act(async () => vi.runOnlyPendingTimers())
        await clickWithinMobileSelect(queryByText('Groups'))
        fireEvent.click(getByText('Account Standards'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument()
      })

      it('Does not render Account Standards groups for root accounts', async () => {
        const {queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({parentAccountChildren: 0}),
        })
        await act(async () => vi.runOnlyPendingTimers())
        expect(queryByText('Account Standards')).not.toBeInTheDocument()
      })
    })

    it('displays a flash alert when a child group fails to load', async () => {
      const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      await act(async () => vi.runOnlyPendingTimers())
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
        await act(async () => vi.runOnlyPendingTimers())
        await clickWithinMobileSelect(queryByText('Groups'))
        fireEvent.click(getByText('State Standards'))
        await act(async () => vi.runOnlyPendingTimers())
      })

      it('does not render the State Standard group if no globalRootId is set', async () => {
        const {queryByText, getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({includeGlobalRootGroup: true}),
        })
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
        expect(queryByText('State Standards')).not.toBeInTheDocument()
      })

      it('does not list outcomes within the State Standard group', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: [...findModalMocks({includeGlobalRootGroup: true}), ...groupMocks({groupId: '1'})],
          globalRootId: '1',
        })
        await act(async () => vi.runOnlyPendingTimers())
        await clickWithinMobileSelect(queryByText('Groups'))
        fireEvent.click(getByText('State Standards'))
        await act(async () => vi.runOnlyPendingTimers())
        expect(getByText('Select a group to reveal outcomes here.')).toBeInTheDocument()
      })
    })
  }

  describe('mobileView', () => {
    beforeEach(() => {
      isMobileView = true
    })
    itBehavesLikeAModal()
    itBehavesLikeATreeBrowser()

    it('renders the action drilldown', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      expect(getByText('Groups')).toBeInTheDocument()
    })

    it('does not render the TreeBrowser', async () => {
      const {queryByTestId} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      const treeBrowser = queryByTestId('groupsColumnRef')
      expect(treeBrowser).not.toBeInTheDocument()
    })

    it('does not render the list of outcomes until the action link is clicked', async () => {
      const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      await clickEl(queryByText('Groups'))
      fireEvent.click(getByText('Account Standards'))
      await clickEl(getByText('Root Account Outcome Group 0'))
      expect(queryByText('All Root Account Outcome Group 0 Outcomes')).not.toBeInTheDocument()
      await clickEl(getByText('View 0 Outcomes'))
      expect(getByText('All Root Account Outcome Group 0 Outcomes')).toBeInTheDocument()
    })

    it('renders the billboard until an action link is clicked', async () => {
      const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      await clickEl(queryByText('Groups'))
      fireEvent.click(getByText('Account Standards'))
      expect(getByText('Select a group to reveal outcomes here.')).toBeInTheDocument()
      await act(async () => vi.runOnlyPendingTimers())
      await clickEl(getByText('Root Account Outcome Group 0'))
      fireEvent.click(getByText('View 0 Outcomes'))
      expect(queryByText('Select a group to reveal outcomes here.')).not.toBeInTheDocument()
    })

    it('unselects the selected group when the modal is closed', async () => {
      const {getByText, queryByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runOnlyPendingTimers())
      await clickEl(queryByText('Groups'))
      fireEvent.click(getByText('Account Standards'))
      await clickEl(getByText('Root Account Outcome Group 0'))
      fireEvent.click(getByText('View 0 Outcomes'))
      render(<FindOutcomesModal {...defaultProps({open: false})} />, {renderer: rerender})
      render(<FindOutcomesModal {...defaultProps({open: true})} />, {renderer: rerender})
      expect(getByText('Select a group to reveal outcomes here.')).toBeInTheDocument()
    })
  })
})
