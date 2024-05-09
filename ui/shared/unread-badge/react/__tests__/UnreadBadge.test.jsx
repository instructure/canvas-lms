/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import UnreadBadge from '@canvas/unread-badge'
import {render, screen} from '@testing-library/react'

const defaultProps = (props = {}) => ({
  unreadCount: 2,
  totalCount: 5,
  unreadLabel: 'unreadLabel',
  totalLabel: 'totalLabel',
  ...props,
})

const renderUnreadBadge = (props = {}) => render(<UnreadBadge {...defaultProps(props)} />)

describe('UnreadBadge', () => {
  it('renders the UnreadBadge component', () => {
    renderUnreadBadge()

    expect(screen.getByText('unreadLabel')).toBeInTheDocument()
    expect(screen.getByText('totalLabel')).toBeInTheDocument()
  })

  it('renders the correct unread count', () => {
    renderUnreadBadge()

    expect(screen.getByText('2 unread replies')).toBeInTheDocument()
  })

  it('renders the correct total count', () => {
    renderUnreadBadge()

    expect(screen.getByText('5 total replies')).toBeInTheDocument()
  })
})
