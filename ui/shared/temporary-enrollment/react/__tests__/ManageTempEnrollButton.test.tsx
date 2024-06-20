/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import ManageTempEnrollButton from '../ManageTempEnrollButton'

const defaultProps = {
  user: {
    id: '1',
    name: 'User',
  },
  tempEnrollPermissions: {
    canEdit: true,
    canAdd: true,
    canDelete: true,
  },
  can_read_sis: true,
  roles: [],
  enrollPerm: {
    teacher: true,
    ta: true,
    student: true,
    observer: true,
    designer: true,
  },
}

describe('ManageTempEnrollButton', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('renders the button when user is a provider', async () => {
    fetchMock.get(`/api/v1/users/${defaultProps.user.id}/temporary_enrollment_status`, {
      is_provider: true,
      is_recipient: true,
    })
    const {findByText} = render(<ManageTempEnrollButton {...defaultProps} />)
    const button = await findByText('Temporary Enrollments')
    expect(button).toBeInTheDocument()
  })

  it('does not render the button when user is not a provider', async () => {
    fetchMock.get(`/api/v1/users/${defaultProps.user.id}/temporary_enrollment_status`, {
      is_provider: false,
      is_recipient: true,
    })
    const {queryByText} = render(<ManageTempEnrollButton {...defaultProps} />)
    const button = await waitFor(() => queryByText('Temporary Enrollments'))
    expect(button).not.toBeInTheDocument()
  })
})
