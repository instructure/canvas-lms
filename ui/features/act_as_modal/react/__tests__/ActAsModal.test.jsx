/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import ActAsModal from '../ActAsModal'
import ActAsMask from '../svg/ActAsMask'
import ActAsPanda from '../svg/ActAsPanda'
import {Button} from '@instructure/ui-buttons'

const props = {
  user: {
    name: 'test user',
    short_name: 'foo',
    id: '5',
    avatar_image_url: 'testImageUrl',
    sortable_name: 'bar, baz',
    email: 'testUser@test.com',
    pseudonyms: [
      {
        login_id: 'qux',
        sis_id: 555,
        integration_id: 222,
      },
      {
        login_id: 'tic',
        sis_id: 777,
        integration_id: 888,
      },
    ],
  },
}
describe('ActAsModal', () => {
  it('renders with user avatar, table, and proceed button present', () => {
    const {getByRole, getByText, getAllByRole} = render(<ActAsModal {...props} />)

    // Check for proceed button
    const proceedButton = getByText('Proceed')
    expect(proceedButton).toBeInTheDocument()
    expect(proceedButton.closest('a')).toHaveAttribute('href', '/users/5/masquerade')

    // Verify modal is properly configured
    const modal = getByRole('dialog')
    expect(modal).toHaveAttribute('aria-label', 'Act as User')

    // Check that Tables are present for displaying user info
    const tables = getAllByRole('table')
    expect(tables.length).toBeGreaterThan(0)
  })

  it('renders avatar with user image url', async () => {
    const {getByLabelText} = render(<ActAsModal {...props} />)
    const modal = getByLabelText('Act as User')
    const avatarImg = modal.querySelector("span[data-fs-exclude='true'] img")
    expect(avatarImg.src).toContain('testImageUrl')
  })

  test('it renders the table with correct user information', () => {
    const {getByLabelText, getByText} = render(<ActAsModal {...props} />)
    const modal = getByLabelText('Act as User')
    const tables = modal.querySelectorAll('table')

    expect(tables).toHaveLength(3)

    const {user} = props
    expect(getByText(user.name)).toBeInTheDocument()
    expect(getByText(user.short_name)).toBeInTheDocument()
    expect(getByText(user.sortable_name)).toBeInTheDocument()
    expect(getByText(user.email)).toBeInTheDocument()
    user.pseudonyms.forEach(pseudonym => {
      expect(getByText(pseudonym.login_id)).toBeInTheDocument()
      expect(getByText('' + pseudonym.sis_id)).toBeInTheDocument()
      expect(getByText('' + pseudonym.integration_id)).toBeInTheDocument()
    })
  })

  test('it should only display loading spinner if state is loading', async () => {
    const ref = React.createRef()
    const {queryByText, getByText, rerender} = render(<ActAsModal {...props} ref={ref} />)
    expect(queryByText('Loading')).not.toBeInTheDocument()

    expect(queryByText('Loading')).not.toBeInTheDocument()
  })
})
