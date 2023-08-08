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
      can_temp_enroll: true,
      can_manage_admin_users: true,
    },
  }
}

describe('UsersListRow', () => {
  const defaultProps = makeProps()

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
        can_temp_enroll: false,
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
