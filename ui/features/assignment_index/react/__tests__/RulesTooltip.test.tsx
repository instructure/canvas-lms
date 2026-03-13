/*
 * Copyright (C) 2026 - present Instructure, Inc.
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
import userEvent from '@testing-library/user-event'
import RulesTooltip from '../RulesTooltip'

describe('RulesTooltip', () => {
  const defaultProps = {
    rulesText: '2 Rules',
    displayableRules: ['Drop the lowest score', 'Drop the highest score'],
  }

  it('renders the rules text link', () => {
    render(<RulesTooltip {...defaultProps} />)

    expect(screen.getByText('2 Rules')).toBeInTheDocument()
  })

  it('shows tooltip content on hover', async () => {
    const user = userEvent.setup()
    render(<RulesTooltip {...defaultProps} />)

    const trigger = screen.getByText('2 Rules')
    await user.hover(trigger)

    expect(await screen.findByText('Drop the lowest score')).toBeInTheDocument()
    expect(screen.getByText('Drop the highest score')).toBeInTheDocument()
  })

  it('renders with a single rule', async () => {
    const user = userEvent.setup()
    render(<RulesTooltip rulesText="1 Rule" displayableRules={['Drop the lowest score']} />)

    const trigger = screen.getByText('1 Rule')
    await user.hover(trigger)

    expect(await screen.findByText('Drop the lowest score')).toBeInTheDocument()
  })

  it('does not render when displayableRules is empty', () => {
    const {container} = render(<RulesTooltip rulesText="0 Rules" displayableRules={[]} />)

    expect(container).toBeEmptyDOMElement()
  })
})
