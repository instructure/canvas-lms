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
import {render, screen, waitFor} from '@testing-library/react'
import {userEvent} from '@testing-library/user-event'
import PeopleFilter from '../PeopleFilter'
import {useDifferentiationTagCategoriesIndex} from '../../hooks/useDifferentiationTagCategoriesIndex'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('../../hooks/useDifferentiationTagCategoriesIndex')
vi.mock('@canvas/util/MessageBus', () => ({
  default: {trigger: vi.fn()},
  trigger: vi.fn(),
}))

const mockUseDifferentiationTagCategoriesIndex = useDifferentiationTagCategoriesIndex as ReturnType<typeof vi.fn>

describe('PeopleFilter', () => {
  const defaultProps = {
    courseId: 1,
  }
  let user: ReturnType<typeof userEvent.setup>
  const renderComponent = (mockReturn = {}, props = {}) => {
    const defaultMock = {
      data: [],
      isLoading: false,
      error: null,
    }
    mockUseDifferentiationTagCategoriesIndex.mockReturnValue({...defaultMock, ...mockReturn})
    return render(<PeopleFilter {...defaultProps} {...props} />)
  }

  beforeEach(() => {
    fakeENV.setup({
      ALL_ROLES: [
        {id: '1', name: 'TeacherRole', count: 2},
        {id: '2', name: 'StudentRole', count: 5},
      ],
    })
    user = userEvent.setup()
  })
  afterEach(() => {
    fakeENV.teardown()
    vi.resetAllMocks()
  })
  it('renders without crashing', async () => {
    renderComponent()
    const input = screen.getByRole('combobox')
    await user.click(input)
    expect(screen.getByText('All Roles')).toBeInTheDocument()
  })

  it('shows all roles in the select', async () => {
    renderComponent()
    const input = screen.getByRole('combobox')
    await user.click(input)
    expect(screen.getByText('TeacherRole (2)')).toBeInTheDocument()
    expect(screen.getByText('StudentRole (5)')).toBeInTheDocument()
  })

  it('shows tag filters', async () => {
    const mockCategories = [
      {
        id: 1,
        name: 'Category 1',
        groups: [
          {id: 1, name: 'Tag 1', members_count: 10},
          {id: 2, name: 'Tag 2', members_count: 5},
        ],
      },
      {id: 2, name: 'Category 2', groups: [{id: 3, name: 'Tag 3', members_count: 8}]},
    ]
    renderComponent({data: mockCategories})
    const input = screen.getByRole('combobox')
    await user.click(input)

    expect(screen.getByText('Tag 1 (10)')).toBeInTheDocument()
    expect(screen.getByText('Tag 2 (5)')).toBeInTheDocument()
    expect(screen.getByText('Tag 3 (8)')).toBeInTheDocument()
  })

  it.skip('calls MessageBus.trigger on select', async () => {
    const MessageBus = require('@canvas/util/MessageBus')
    renderComponent()
    const input = screen.getByRole('combobox')
    await user.click(input)

    const roleOption = await screen.getByText('TeacherRole (2)')
    user.click(roleOption)

    await waitFor(() => {
      expect(MessageBus.trigger).toHaveBeenCalledWith(
        'peopleFilterChange',
        expect.objectContaining({enrollment_role_id: [1]}),
      )
    })
  })
})
