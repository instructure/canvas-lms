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
import DirectShareUserPanel from '../DirectShareUserPanel'
import userEvent from '@testing-library/user-event'

const defaultProps = {
  courseId: '1',
  selectedUsers: [],
  onUserSelected: jest.fn(),
  onUserRemoved: jest.fn(),
}

const renderComponent = (props?: any) =>
  render(<DirectShareUserPanel {...defaultProps} {...props} />)

describe('DirectShareUserPanel', () => {
  it('renders icon', () => {
    renderComponent()
    expect(screen.getByTestId('direct-share-user-icon')).toBeInTheDocument()
  })

  it('renders labels', () => {
    renderComponent({
      selectedUsers: [
        {
          id: '1',
          name: 'shrek',
          short_name: 'shrek',
          sortable_name: 'shrek',
          created_at: '',
        },
        {
          id: '2',
          name: 'donkey',
          short_name: 'donkey',
          sortable_name: 'donkey',
          created_at: '',
        },
      ],
    })
    expect(screen.getByText(/shrek/i)).toBeInTheDocument()
    expect(screen.getByText(/donkey/i)).toBeInTheDocument()
  })

  it('calls onUserRemoved when label is clicked', async () => {
    renderComponent({
      selectedUsers: [
        {
          id: '1',
          name: 'shrek',
          short_name: 'shrek',
          sortable_name: 'shrek',
          created_at: '',
        },
      ],
    })
    await userEvent.click(screen.getByText(/shrek/i))
    expect(defaultProps.onUserRemoved).toHaveBeenCalledWith({
      id: '1',
      name: 'shrek',
      short_name: 'shrek',
      sortable_name: 'shrek',
      created_at: '',
    })
  })
})
