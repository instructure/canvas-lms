/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import UsersListRow from '../components/UsersListRow'
import React from 'react'
import {render} from '@testing-library/react'
import fetchMock from 'fetch-mock'

function makeProps() {
  return {
    accountId: '1',
    user: {
      id: '1',
      name: 'foo',
      short_name: 'foo',
      sortable_name: 'foo',
      avatar_url: 'http://someurl',
    },
    roles: [{id: '19', label: 'Teacher', base_role_name: 'TeacherEnrollment'}],
    handleOpenEditUserDialog: jest.fn(),
    handleSubmitEditUserForm: jest.fn(),
    handleCloseEditUserDialog: jest.fn(),
    permissions: {
      can_masquerade: true,
      can_message_users: true,
      can_edit_users: true,
      can_add_temporary_enrollments: true,
      can_manage_admin_users: true,
    },
  }
}

describe('UsersListRow', () => {
  const defaultProps = makeProps()

  beforeEach(() => {
    // enrollment providers
    fetchMock.get(
      '/api/v1/users/1/enrollments?state%5B%5D=active&state%5B%5D=invited&temporary_enrollment_providers=true',
      [
        {
          id: '47',
          course_id: '5',
          user: {
            id: '7',
            name: 'Provider Person',
          },
          start_at: '2019-09-26T00:00:00Z',
          end_at: '2019-09-27T23:59:59Z',
          type: 'TeacherEnrollment',
        },
      ]
    )

    // enrollment recipients
    fetchMock.get(
      '/api/v1/users/1/enrollments?state%5B%5D=active&state%5B%5D=invited&temporary_enrollment_recipients=true',
      [
        {
          id: '48',
          course_id: '5',
          user: {
            id: '2',
            name: 'Recipient Person',
          },
          start_at: '2019-09-26T00:00:00Z',
          end_at: '2019-09-27T23:59:59Z',
          type: 'TeacherEnrollment',
        },
      ]
    )
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders an avatar', () => {
    const {getByText} = render(
      <table>
        <tbody>
          <UsersListRow {...defaultProps} />
        </tbody>
      </table>
    )
    const avatar = getByText('foo').querySelector('span')
    expect(avatar.getAttribute('src')).toBe(defaultProps.user.avatar_url)
  })

  it('renders all tooltips when permissions true', () => {
    const {getAllByRole} = render(
      <table>
        <tbody>
          <UsersListRow {...defaultProps} />
        </tbody>
      </table>
    )
    expect(getAllByRole('tooltip').length).toBe(4)
  })

  it('renders no tooltips when permissions are false', () => {
    const noPermission = {
      ...makeProps(),
      permissions: {
        can_masquerade: false,
        can_message_users: false,
        can_edit_users: false,
        can_add_temporary_enrollments: false,
      },
    }

    const {queryByRole} = render(
      <table>
        <tbody>
          <UsersListRow {...noPermission} />
        </tbody>
      </table>
    )
    const noElements = queryByRole('tooltip')
    expect(noElements).toBeNull()
  })
})
