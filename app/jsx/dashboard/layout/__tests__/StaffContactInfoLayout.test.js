/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import StaffContactInfoLayout from 'jsx/dashboard/layout/StaffContactInfoLayout'

describe('StaffContactInfoLayout', () => {
  const getProps = (overrides = {}) => ({
    staff: [
      {
        id: '1',
        name: 'Mrs. Thompson',
        bio: 'Office Hours: 1-3pm W',
        email: 't@abc.edu',
        avatarUrl: '/images/avatar1.png',
        role: 'TeacherEnrollment'
      },
      {
        id: '2',
        name: 'Tommy the TA',
        bio: null,
        email: 'tommy@abc.edu',
        avatarUrl: '/images/avatar2.png',
        role: 'TaEnrollment'
      },
      {
        id: '3',
        name: 'Tammy the TA',
        bio: 'Office Hours: 1-3pm F',
        email: 'tammy@abc.edu',
        avatarUrl: null,
        role: 'Super Cool TA'
      }
    ],
    ...overrides
  })

  it('renders a row for each of the staff members passed', () => {
    const {getByText} = render(<StaffContactInfoLayout {...getProps()} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
    expect(getByText('Tommy the TA')).toBeInTheDocument()
    expect(getByText('Tammy the TA')).toBeInTheDocument()
  })

  it('renders a title if this section exists', () => {
    const {getByText} = render(<StaffContactInfoLayout {...getProps()} />)
    expect(getByText('Staff Contact Info')).toBeInTheDocument()
  })

  it('renders nothing at all if staff is empty', () => {
    const {container} = render(<StaffContactInfoLayout {...getProps({staff: []})} />)
    expect(container.firstChild).toBeEmpty()
  })
})
