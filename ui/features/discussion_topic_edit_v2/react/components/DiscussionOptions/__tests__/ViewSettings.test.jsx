/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {fireEvent, render, screen} from '@testing-library/react'
import React from 'react'

import {
  DEFAULT_SORT_ORDER,
  DEFAULT_SORT_ORDER_LOCKED,
  DEFAULT_EXPANDED_STATE,
  DEFAULT_EXPANDED_LOCKED,
} from '../../../util/constants'
import {ViewSettings} from '../ViewSettings'

const defaultProps = {
  expanded: DEFAULT_EXPANDED_STATE,
  expandedLocked: DEFAULT_EXPANDED_LOCKED,
  sortOrder: DEFAULT_SORT_ORDER,
  sortOrderLocked: DEFAULT_SORT_ORDER_LOCKED,
  setExpanded: () => {},
  setExpandedLocked: () => {},
}

const setup = (props = {}, env = {}) => {
  window.ENV = {
    DISCUSSION_DEFAULT_EXPAND_ENABLED: true,
    DISCUSSION_DEFAULT_SORT_ENABLED: true,
    ...env,
  }

  return render(<ViewSettings {...props} />)
}

describe('ViewSettings', () => {
  it('renders', () => {
    const {getByText} = setup(defaultProps)
    expect(getByText('View')).toBeInTheDocument()
  })

  it('renders thread folding settings, if enabled in ENV', () => {
    const {queryByTestId} = setup(defaultProps)
    expect(queryByTestId('view-default-thread-state')).toBeInTheDocument()
  })

  it('does not render thread folding settings, if disabled in ENV', () => {
    const {queryByTestId} = setup(defaultProps, {
      DISCUSSION_DEFAULT_EXPAND_ENABLED: false,
    })
    expect(queryByTestId('view-default-thread-state')).not.toBeInTheDocument()
  })

  it('disables thread folding lock setting, if the thread folding is set to collapsed', () => {
    // If default setting would change, this test should still work
    const {queryByTestId} = setup({
      ...defaultProps,
      expanded: false,
      expandedLocked: false,
    })
    const locked = queryByTestId('view-expanded-locked')
    expect(locked).toHaveAttribute('data-action-state', 'lockExpandedState')
    expect(locked).toBeDisabled()
    fireEvent.click(screen.queryByTestId('view-default-thread-state-expanded'))
    fireEvent.click(locked)
    fireEvent.click(screen.queryByTestId('view-default-thread-state-collapsed'))
    expect(locked).toBeDisabled()
  })

  it('when expanded lock is set, then it sets the trackable attribute accordingly', () => {
    const {queryByTestId} = setup({
      ...defaultProps,
      expanded: true,
      expandedLocked: true,
    })
    const locked = queryByTestId('view-expanded-locked')
    expect(locked).toHaveAttribute('data-action-state', 'unlockExpandedState')
  })

  it('renders sort order settings, if enabled in ENV', () => {
    const {queryByTestId} = setup(defaultProps)
    expect(queryByTestId('view-default-sort-order')).toBeInTheDocument()
    expect(queryByTestId('view-sort-order-locked')).toHaveAttribute(
      'data-action-state',
      'lockSortOrder',
    )
  })

  it('when sort order is locked it sets the trackable attribute accordingly', () => {
    const {queryByTestId} = setup({
      ...defaultProps,
      sortOrderLocked: true,
    })
    expect(queryByTestId('view-sort-order-locked')).toHaveAttribute(
      'data-action-state',
      'unlockSortOrder',
    )
  })

  it('does not render sort order settings, if disabled in ENV', () => {
    const {queryByTestId} = setup(defaultProps, {
      DISCUSSION_DEFAULT_SORT_ENABLED: false,
    })
    expect(queryByTestId('view-default-sort-order')).not.toBeInTheDocument()
  })
})
