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

import {fireEvent, render} from '@testing-library/react'
import React from 'react'
import {AllThreadsState, SearchContext} from '../../../utils/constants'
import {ExpandCollapseThreadsButton} from '../ExpandCollapseThreadsButton'

const setup = (props = {}, contextOverrides = {}) => {
  const searchContextValues = {
    setAllThreadsStatus: vi.fn(),
    setExpandedThreads: vi.fn(),
    ...contextOverrides,
  }

  const defaultProps = {
    isExpanded: false,
    onCollapseRepliesToggle: vi.fn(),
    showText: false,
    tooltipEnabled: false,
    disabled: false,
    expandedLocked: false,
    ...props,
  }

  const result = render(
    <SearchContext.Provider value={searchContextValues}>
      <ExpandCollapseThreadsButton {...defaultProps} />
    </SearchContext.Provider>,
  )

  return {...result, searchContextValues}
}

describe('ExpandCollapseThreadsButton', () => {
  describe('Rendering', () => {
    it('should render the button', () => {
      const {getByTestId} = setup()
      expect(getByTestId('ExpandCollapseThreads-button')).toBeInTheDocument()
    })

    it('should render expand icon when threads are collapsed', () => {
      const {getByTestId} = setup({isExpanded: false})
      expect(getByTestId('expand-icon')).toBeInTheDocument()
    })

    it('should render collapse icon when threads are expanded', () => {
      const {getByTestId} = setup({isExpanded: true})
      expect(getByTestId('collapse-icon')).toBeInTheDocument()
    })

    it('should render collapse icon when expandedLocked is true', () => {
      const {getByTestId} = setup({isExpanded: false, expandedLocked: true})
      expect(getByTestId('collapse-icon')).toBeInTheDocument()
    })

    it('should render button text when showText is true and collapsed', () => {
      const {getByText} = setup({showText: true, isExpanded: false})
      expect(getByText('Expand Threads')).toBeInTheDocument()
    })

    it('should render button text when showText is true and expanded', () => {
      const {getByText} = setup({showText: true, isExpanded: true})
      expect(getByText('Collapse Threads')).toBeInTheDocument()
    })

    it('should not render button text when showText is false', () => {
      const {queryByText} = setup({showText: false, isExpanded: false})
      expect(queryByText('Expand Threads')).not.toBeInTheDocument()
    })
  })

  describe('Button state', () => {
    it('should be enabled by default', () => {
      const {getByTestId} = setup()
      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).not.toBeDisabled()
    })

    it('should be disabled when disabled prop is true', () => {
      const {getByTestId} = setup({disabled: true})
      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).toBeDisabled()
    })

    it('should have data-action-state="expandButton" when collapsed', () => {
      const {getByTestId} = setup({isExpanded: false})
      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).toHaveAttribute('data-action-state', 'expandButton')
    })

    it('should have data-action-state="collapseButton" when expanded', () => {
      const {getByTestId} = setup({isExpanded: true})
      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).toHaveAttribute('data-action-state', 'collapseButton')
    })
  })

  describe('aria-expanded attribute', () => {
    it('should have aria-expanded="false" when threads are collapsed', () => {
      const {getByTestId} = setup({isExpanded: false})
      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).toHaveAttribute('aria-expanded', 'false')
    })

    it('should have aria-expanded="true" when threads are expanded', () => {
      const {getByTestId} = setup({isExpanded: true})
      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).toHaveAttribute('aria-expanded', 'true')
    })

    it('should toggle aria-expanded when button is clicked', () => {
      const onCollapseRepliesToggleMock = vi.fn()
      const {getByTestId, rerender, searchContextValues} = setup({
        isExpanded: false,
        onCollapseRepliesToggle: onCollapseRepliesToggleMock,
      })

      const button = getByTestId('ExpandCollapseThreads-button')
      expect(button).toHaveAttribute('aria-expanded', 'false')

      fireEvent.click(button)
      expect(onCollapseRepliesToggleMock).toHaveBeenCalledWith(true)

      // Simulate re-render with updated isExpanded prop
      rerender(
        <SearchContext.Provider value={searchContextValues}>
          <ExpandCollapseThreadsButton
            isExpanded={true}
            onCollapseRepliesToggle={onCollapseRepliesToggleMock}
            showText={false}
            tooltipEnabled={false}
            disabled={false}
            expandedLocked={false}
          />
        </SearchContext.Provider>,
      )

      expect(button).toHaveAttribute('aria-expanded', 'true')
    })
  })

  describe('Click behavior', () => {
    it('should call correct functions when expanding', () => {
      const onCollapseRepliesToggleMock = vi.fn()
      const setAllThreadsStatusMock = vi.fn()
      const setExpandedThreadsMock = vi.fn()
      const {getByTestId} = setup(
        {isExpanded: false, onCollapseRepliesToggle: onCollapseRepliesToggleMock},
        {
          setAllThreadsStatus: setAllThreadsStatusMock,
          setExpandedThreads: setExpandedThreadsMock,
        },
      )

      fireEvent.click(getByTestId('ExpandCollapseThreads-button'))

      expect(onCollapseRepliesToggleMock).toHaveBeenCalledWith(true)
      expect(setExpandedThreadsMock).toHaveBeenCalledWith([])
      expect(setAllThreadsStatusMock).toHaveBeenCalledWith(AllThreadsState.Expanded)
    })

    it('should call correct functions when collapsing', () => {
      const onCollapseRepliesToggleMock = vi.fn()
      const setAllThreadsStatusMock = vi.fn()
      const setExpandedThreadsMock = vi.fn()
      const {getByTestId} = setup(
        {isExpanded: true, onCollapseRepliesToggle: onCollapseRepliesToggleMock},
        {
          setAllThreadsStatus: setAllThreadsStatusMock,
          setExpandedThreads: setExpandedThreadsMock,
        },
      )

      fireEvent.click(getByTestId('ExpandCollapseThreads-button'))

      expect(onCollapseRepliesToggleMock).toHaveBeenCalledWith(false)
      expect(setExpandedThreadsMock).toHaveBeenCalledWith([])
      expect(setAllThreadsStatusMock).toHaveBeenCalledWith(AllThreadsState.Collapsed)
    })
  })

  describe('Initial mount behavior', () => {
    beforeEach(() => {
      vi.useFakeTimers()
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    it('should call setAllThreadsStatus with Expanded on mount when isExpanded is true', () => {
      const setAllThreadsStatusMock = vi.fn()
      setup({isExpanded: true}, {setAllThreadsStatus: setAllThreadsStatusMock})

      expect(setAllThreadsStatusMock).toHaveBeenCalledWith(AllThreadsState.Expanded)
    })

    it('should not call setAllThreadsStatus with Expanded on mount when isExpanded is false', () => {
      const setAllThreadsStatusMock = vi.fn()
      setup({isExpanded: false}, {setAllThreadsStatus: setAllThreadsStatusMock})

      const expandedCalls = setAllThreadsStatusMock.mock.calls.filter(
        call => call[0] === AllThreadsState.Expanded,
      )
      expect(expandedCalls).toHaveLength(0)
    })

    it('should call setAllThreadsStatus with None after timeout on mount', () => {
      const setAllThreadsStatusMock = vi.fn()
      setup({isExpanded: true}, {setAllThreadsStatus: setAllThreadsStatusMock})

      vi.runAllTimers()
      expect(setAllThreadsStatusMock).toHaveBeenCalledWith(AllThreadsState.None)
    })
  })

  describe('expandedLocked prop', () => {
    it('should show collapse text when expandedLocked is true', () => {
      const {getByText} = setup({showText: true, expandedLocked: true, isExpanded: false})
      expect(getByText('Collapse Threads')).toBeInTheDocument()
    })

    it('should show collapse icon when expandedLocked is true', () => {
      const {getByTestId} = setup({expandedLocked: true, isExpanded: false})
      expect(getByTestId('collapse-icon')).toBeInTheDocument()
    })
  })
})
