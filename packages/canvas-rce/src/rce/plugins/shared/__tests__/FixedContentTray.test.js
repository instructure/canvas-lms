/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {FixedContentTray} from '../FixedContentTray'

describe('RCE Plugins > FixedContentTray', () => {
  const defaults = {
    renderHeader: jest.fn(),
    renderBody: jest.fn(),
    renderFooter: jest.fn(),
    title: 'Banana',
    isOpen: true,
    onDismiss: jest.fn(),
    onUnmount: jest.fn(),
    bodyAs: 'form',
    shouldJoinBodyAndFooter: false,
  }

  it('renders header', async () => {
    render(<FixedContentTray {...defaults} renderHeader={() => 'Han Solo'} />)
    expect(screen.getByText('Han Solo', {selector: 'header > div'})).toBeInTheDocument()
  })

  it('renders body', async () => {
    render(<FixedContentTray {...defaults} renderBody={() => 'Luke Skywalker'} />)
    expect(screen.getByText('Luke Skywalker', {selector: 'form'})).toBeInTheDocument()
  })

  it('renders footer', async () => {
    render(<FixedContentTray {...defaults} renderFooter={() => 'Princess Leia'} />)
    expect(screen.getByText('Princess Leia', {selector: 'footer > div'})).toBeInTheDocument()
  })

  it('renders body & footer in same item', async () => {
    render(
      <FixedContentTray
        {...defaults}
        renderBody={() => 'R2D2'}
        renderFooter={() => 'C3PO'}
        shouldJoinBodyAndFooter={true}
      />
    )
    expect(screen.getByText('R2D2', {selector: 'form > div'})).toBeInTheDocument()
    expect(screen.getByText('C3PO', {selector: 'form > footer > div'})).toBeInTheDocument()
  })
})
