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
import userEvent from '@testing-library/user-event'
import {
  DisabledActionsInfoButton,
  DisabledActionsInfoButtonProps,
} from '../DisabledActionsInfoButton'

const defaultProps: DisabledActionsInfoButtonProps = {
  size: 'large',
}

const renderComponent = (props = {}) => {
  return render(<DisabledActionsInfoButton {...defaultProps} {...props} />)
}

describe('DisabledActionsInfoButton', () => {
  it('renders button with info icon', async () => {
    renderComponent()

    expect(screen.getByTestId('disabled-actions-info-button')).toBeInTheDocument()
    expect(screen.queryByText('Disabled actions')).toBeInTheDocument()
  })

  it('only renders icon for small sizes', async () => {
    renderComponent({size: 'small'})

    expect(screen.getByTestId('disabled-actions-info-button')).toBeInTheDocument()
    expect(screen.queryByText('Disabled actions')).not.toBeInTheDocument()
  })

  it('only renders icon for medium sizes', async () => {
    renderComponent({size: 'medium'})

    expect(screen.getByTestId('disabled-actions-info-button')).toBeInTheDocument()
    expect(screen.queryByText('Disabled actions')).not.toBeInTheDocument()
  })

  it('renders component with all disabled actions for a blue print child course', async () => {
    renderComponent()

    const infoButton = screen.getByTestId('disabled-actions-info-button')
    await userEvent.click(infoButton)

    expect(screen.getByText('Folders containing locked content')).toBeInTheDocument()
    expect(screen.getByText('Locked files')).toBeInTheDocument()
  })
})
