/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import PolicyCell from '../PolicyCell'
import {render} from '@testing-library/react'
import React from 'react'

function createMockProps(opts) {
  return {
    category: 'announcement',
    channelId: '42',
    selection: 'immediately',
    buttonData: [
      {code: 'immediately', icon: 'icon-check', text: 'ASAP', title: 'Notify me right away'},
      {code: 'daily', icon: 'icon-clock', text: 'Daily', title: 'Send daily summary'},
      {code: 'weekly', icon: 'icon-calendar-month', text: 'Weekly', title: 'Send weekly summary'},
      {code: 'never', icon: 'icon-x', text: 'Never', title: 'Do not send me anything'}
    ],
    disabled: false,
    disabledTooltipText: '',
    onValueChanged: jest.fn(),
    ...opts
  }
}

describe('ContentTabs', () => {
  it('renders the disabled icon and tooltip if the disabled prop is pass in', async () => {
    const tooltipText = 'Tooltip Text'
    const props = createMockProps({disabled: true, disabledTooltipText: tooltipText})
    const {findByTestId, findByText} = render(<PolicyCell {...props} />)

    expect(await findByTestId('notification-type-disabled')).toBeInTheDocument()
    expect(await findByText(tooltipText)).toBeInTheDocument()
  })

  it('renders the RadioInputGroup when not disabled', async () => {
    const props = createMockProps()
    const {findByText} = render(<PolicyCell {...props} />)

    expect(await findByText('Notify me right away')).toBeInTheDocument()
  })
})
