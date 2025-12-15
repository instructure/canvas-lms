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
import {act, fireEvent} from '@testing-library/react'
import FindOutcomesModal from '../FindOutcomesModal'
import {createCache} from '@canvas/apollo-v3'
import {findModalMocks} from '@canvas/outcomes/mocks/Outcomes'
import {groupMocks} from '@canvas/outcomes/mocks/Management'
import {clickEl} from '@canvas/outcomes/react/helpers/testHelpers'
import resolveProgress from '@canvas/progress/resolve_progress'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {createDefaultProps, renderWithContext} from './FindOutcomesModalTestUtils'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(),
}))

vi.mock('@canvas/progress/resolve_progress')
vi.useFakeTimers()

describe('FindOutcomesModal - Basic Tests', () => {
  let cache
  let onCloseHandlerMock
  let setTargetGroupIdsToRefetchMock
  let setImportsTargetGroupMock
  let defaultProps

  beforeEach(() => {
    onCloseHandlerMock = vi.fn()
    setTargetGroupIdsToRefetchMock = vi.fn()
    setImportsTargetGroupMock = vi.fn()
    defaultProps = createDefaultProps(
      onCloseHandlerMock,
      setTargetGroupIdsToRefetchMock,
      setImportsTargetGroupMock,
    )
    cache = createCache()
    window.ENV = {}
  })

  afterEach(() => {
    vi.clearAllMocks()
    resolveProgress.mockReset()
  })

  const render = (children, options = {}) => {
    return renderWithContext(children, {...options, cache})
  }

  describe('Modal behavior', () => {
    it('renders component with "Add Outcomes to Account" title when contextType is Account', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runAllTimers())
      expect(getByText('Add Outcomes to Account')).toBeInTheDocument()
    })

    it('renders component with "Add Outcomes to Course" title when contextType is Course', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      await act(async () => vi.runAllTimers())
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
      await act(async () => vi.runAllTimers())
      expect(getByText('Add Outcomes to "The Group Title"')).toBeInTheDocument()
    })

    it('shows modal if open prop true', async () => {
      const {getByText} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runAllTimers())
      expect(getByText('Close')).toBeInTheDocument()
    })

    it('does not show modal if open prop false', async () => {
      const {queryByText} = render(<FindOutcomesModal {...defaultProps({open: false})} />)
      await act(async () => vi.runAllTimers())
      expect(queryByText('Close')).not.toBeInTheDocument()
    })

    describe('error handling', () => {
      describe('within an account', () => {
        it('displays a screen reader error and text error on failed request', async () => {
          const {getByText} = render(<FindOutcomesModal {...defaultProps()} />, {mocks: []})
          await act(async () => vi.runAllTimers())
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
          await act(async () => vi.runAllTimers())
          expect(showFlashAlert).toHaveBeenCalledWith({
            message: 'An error occurred while loading course learning outcome groups.',
            srOnly: true,
            type: 'error',
          })
          expect(getByText(/An error occurred while loading course outcomes/)).toBeInTheDocument()
        })
      })
    })
  })

  describe('Tree browser behavior', () => {
    it('clears selected outcome group for the outcomes view after closing and reopening', async () => {
      const {getByText, queryByText, rerender} = render(<FindOutcomesModal {...defaultProps()} />)
      await act(async () => vi.runAllTimers())
      fireEvent.click(getByText('Account Standards'))
      fireEvent.click(getByText('Root Account Outcome Group 0'))
      await act(async () => vi.runAllTimers())
      await act(async () => vi.runAllTimers())
      expect(getByText('All Root Account Outcome Group 0 Outcomes')).toBeInTheDocument()
      fireEvent.click(getByText('Done'))
      render(<FindOutcomesModal {...defaultProps({open: false})} />, {renderer: rerender})
      await act(async () => vi.runAllTimers())
      render(<FindOutcomesModal {...defaultProps()} />, {renderer: rerender})
      await act(async () => vi.runAllTimers())
      expect(queryByText('All Root Account Outcome Group 0 Outcomes')).not.toBeInTheDocument()
    })

    describe('within an account context', () => {
      it('renders Account Standards groups for non root accounts', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />)
        await act(async () => vi.runAllTimers())
        fireEvent.click(getByText('Account Standards'))
        await act(async () => vi.runAllTimers())
        expect(getByText('Root Account Outcome Group 0')).toBeInTheDocument()
      })

      it('Does not render Account Standards groups for root accounts', async () => {
        const {queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({parentAccountChildren: 0}),
        })
        await act(async () => vi.runAllTimers())
        expect(queryByText('Account Standards')).not.toBeInTheDocument()
      })
    })

    it('displays a flash alert when a child group fails to load', async () => {
      const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
        contextType: 'Course',
      })
      await act(async () => vi.runAllTimers())
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
        await act(async () => vi.runAllTimers())
        fireEvent.click(getByText('State Standards'))
        await act(async () => vi.runAllTimers())
      })

      it('does not render the State Standard group if no globalRootId is set', async () => {
        const {queryByText, getByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: findModalMocks({includeGlobalRootGroup: true}),
        })
        await act(async () => vi.runAllTimers())
        expect(getByText(/An error occurred while loading account outcomes/)).toBeInTheDocument()
        expect(queryByText('State Standards')).not.toBeInTheDocument()
      })

      it('does not list outcomes within the State Standard group', async () => {
        const {getByText, queryByText} = render(<FindOutcomesModal {...defaultProps()} />, {
          mocks: [...findModalMocks({includeGlobalRootGroup: true}), ...groupMocks({groupId: '1'})],
          globalRootId: '1',
        })
        await act(async () => vi.runAllTimers())
        fireEvent.click(getByText('State Standards'))
        await act(async () => vi.runAllTimers())
        expect(getByText('Select a group to reveal outcomes here.')).toBeInTheDocument()
      })
    })
  })
})
