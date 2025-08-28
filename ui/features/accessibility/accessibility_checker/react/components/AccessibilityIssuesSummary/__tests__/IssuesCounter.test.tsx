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

import {render, screen} from '@testing-library/react'
import {IssuesCounter} from '../IssuesCounter'

describe('IssuesCounter', () => {
  it('shows correct text with multiple issues', () => {
    render(<IssuesCounter count={10} />)
    expect(screen.getByTestId('counter-number')).toHaveTextContent('10')
    expect(screen.getByTestId('counter-description')).toHaveTextContent('Total Issues')
  })

  it('shows correct text with one issue', () => {
    render(<IssuesCounter count={1} />)
    expect(screen.getByTestId('counter-number')).toHaveTextContent('1')
    expect(screen.getByTestId('counter-description')).toHaveTextContent('Total Issue')
  })

  it('shows correct text with no issues', () => {
    render(<IssuesCounter count={0} />)
    expect(screen.getByTestId('counter-number')).toHaveTextContent('0')
    expect(screen.getByTestId('counter-description')).toHaveTextContent('Total Issues')
  })

  it('shows correct number if there are issues', () => {
    render(<IssuesCounter count={10} />)
    // Warning yellow
    expect(getComputedStyle(screen.getByTestId('counter-number')).color).toBe('rgb(179, 64, 0)')
  })

  it('shows correct number if there are not issues', () => {
    render(<IssuesCounter count={0} />)
    // Success green
    expect(getComputedStyle(screen.getByTestId('counter-number')).color).toBe('rgb(2, 118, 52)')
  })
})
