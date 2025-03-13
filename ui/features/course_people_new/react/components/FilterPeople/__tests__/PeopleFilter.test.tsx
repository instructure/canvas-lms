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
import userEvent from '@testing-library/user-event'
import PeopleFilter from '../PeopleFilter'
import {DEFAULT_OPTION} from '../../../../util/constants'
import {EnvRole} from '../../../../types'

jest.mock('../../../hooks/useCoursePeopleContext')

const allRoles = [
  {...DEFAULT_OPTION, id: '1', label: 'Teacher', count: 1},
  {...DEFAULT_OPTION, id: '2', label: 'Student', count: 2},
]

const useCoursePeopleContextMocks = {
  allRoles
}

describe('PeopleFilter', () => {
  const filterOptions = [DEFAULT_OPTION, ...allRoles]
  const defaultRole = filterOptions[0]
  const otherRole = filterOptions[1]
  const user = userEvent.setup()
  const defaultProps = {
    onOptionSelect: jest.fn(),
  }

  const renderComponent = () => render(<PeopleFilter {...defaultProps} />)

  const labelWithCount = (role: EnvRole) =>
    role.id === defaultRole.id
      ? role.label
      : `${role.label} (${role.count})`

  const otherLabel = labelWithCount(otherRole)

  beforeEach(() => {
    require('../../../hooks/useCoursePeopleContext').default.mockReturnValue(useCoursePeopleContextMocks)
    renderComponent()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders the filter dropdown', () => {
    expect(screen.getByLabelText('Filter by role')).toBeInTheDocument()
  })

  it('shows default option initially', () => {
    expect(screen.getByDisplayValue(labelWithCount(defaultRole))).toBeInTheDocument()
  })

  it('shows options when clicked', async () => {
    await user.click(screen.getByLabelText('Filter by role'))
    await waitFor(() => {
      const options = filterOptions.map(role =>
        screen.getByText(labelWithCount(role))
      )
      expect(options).toHaveLength(filterOptions.length)
    })
  })

  it('shows option label with count', async () => {
    await user.click(screen.getByLabelText('Filter by role'))
    await waitFor(() => {
      expect(screen.getByText(/Teacher \(1\)/)).toBeInTheDocument()
    })
  })

  it('calls onOptionSelect when an option is selected', async () => {
    await user.click(screen.getByLabelText('Filter by role'))
    await waitFor(() => {
      expect(screen.getByText(otherLabel)).toBeInTheDocument()
    })
    await user.click(screen.getByText(otherLabel))
    expect(defaultProps.onOptionSelect).toHaveBeenCalledWith(otherRole.id)
  })
})
