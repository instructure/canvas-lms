/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import DashboardCardAction from '../DashboardCardAction'

describe('DashboardCardAction', () => {
  let props

  beforeEach(() => {
    props = {
      iconClass: 'icon-assignment',
      path: '/courses/1/assignments/',
    }
  })

  it('renders link with icon', () => {
    const {getByRole, container} = render(<DashboardCardAction {...props} />)
    const link = getByRole('link')
    expect(link).toBeInTheDocument()
    expect(container.querySelector('svg[name="IconAssignment"]')).toBeInTheDocument()
    expect(container.querySelector('.screenreader-only')).not.toBeInTheDocument()
  })

  it('renders fallback icon for unrecognized iconClass', () => {
    props.iconClass = 'icon-something-else'
    const {getByRole, container} = render(<DashboardCardAction {...props} />)
    const link = getByRole('link')
    expect(link).toBeInTheDocument()
    const icon = container.querySelector('i')
    expect(icon).toBeInTheDocument()
    expect(icon).toHaveClass(props.iconClass)
    expect(container.querySelector('.screenreader-only')).not.toBeInTheDocument()
  })

  it('renders screenreader text when provided', () => {
    const screenReaderLabel = 'Dashboard Action'
    const {getByText} = render(
      <DashboardCardAction {...props} screenReaderLabel={screenReaderLabel} />,
    )
    expect(getByText(screenReaderLabel)).toHaveClass('screenreader-only')
  })

  it('displays unread count when greater than zero', () => {
    const unreadCount = 2
    const {getByText} = render(<DashboardCardAction {...props} unreadCount={unreadCount} />)
    expect(getByText(String(unreadCount))).toHaveClass('unread_count')
    expect(getByText('Unread')).toHaveClass('screenreader-only')
  })
})
