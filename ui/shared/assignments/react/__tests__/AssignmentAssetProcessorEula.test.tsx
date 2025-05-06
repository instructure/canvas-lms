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

import React from 'react'
import {render} from '@testing-library/react'
import AssignmentAssetProcessorEula from '../AssignmentAssetProcessorEula'
import userEvent from '@testing-library/user-event'

describe('AssignmentAssetProcessorEula', () => {
  const mockLaunches = [
    {
      url: 'https://example.com/eula/1',
      name: 'Tool 1',
    },
    {
      url: 'https://example.com/eula/2',
      name: 'Tool 2',
    },
  ]

  it('renders the ExternalToolModalLauncher for first launch then when closed the second one, then it renders null', async () => {
    const {queryByText, getByText, container} = render(
      <AssignmentAssetProcessorEula launches={mockLaunches} />,
    )

    expect(queryByText('EULA of Tool 1')).toBeInTheDocument()
    let closeButton = getByText('Close').closest('button')
    if (!closeButton) throw new Error('No close button found')
    await userEvent.click(closeButton)

    // Next EULA launch should be shown
    expect(queryByText('EULA of Tool 2')).toBeInTheDocument()

    closeButton = getByText('Close').closest('button')
    if (!closeButton) throw new Error('No close button found')
    await userEvent.click(closeButton)

    // No more launches should be shown
    expect(container).toBeEmptyDOMElement()
  })
})
