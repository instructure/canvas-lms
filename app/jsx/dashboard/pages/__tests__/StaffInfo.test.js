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
import StaffInfo from 'jsx/dashboard/pages/StaffInfo'

describe('StaffInfo', () => {
  const getProps = (overrides = {}) => ({
    id: '1',
    name: 'Mrs. Thompson',
    bio: 'Office Hours: 9-10am MWF',
    email: 'thompson@abc.edu',
    avatarUrl: '/avatar1.png',
    role: 'TeacherEnrollment',
    ...overrides
  })

  it('renders the name, role, and bio of staff member', () => {
    const {getByText} = render(<StaffInfo {...getProps()} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
    expect(getByText('Office Hours: 9-10am MWF')).toBeInTheDocument()
    expect(getByText('Teacher')).toBeInTheDocument()
  })

  it('renders avatar with alt text', () => {
    const {getByAltText} = render(<StaffInfo {...getProps()} />)
    const image = getByAltText('Avatar for Mrs. Thompson')
    expect(image).toBeInTheDocument()
    expect(image.src).toContain('/avatar1.png')
  })

  it('renders an email button with correct email', () => {
    const {getByText} = render(<StaffInfo {...getProps()} />)
    const button = getByText('Email Mrs. Thompson')
    expect(button).toBeInTheDocument()
    expect(button.closest('a').href).toBe('mailto:thompson@abc.edu')
  })

  it('renders custom role names', () => {
    const {getByText} = render(<StaffInfo {...getProps({role: 'Head TA'})} />)
    expect(getByText('Head TA')).toBeInTheDocument()
  })

  it('renders default avatar if avatarUrl is null', () => {
    const {getByAltText} = render(<StaffInfo {...getProps({avatarUrl: undefined})} />)
    const image = getByAltText('Avatar for Mrs. Thompson')
    expect(image).toBeInTheDocument()
    expect(image.src).toContain('/images/messages/avatar-50.png')
  })

  it('still renders name and role if bio is missing', () => {
    const {getByText} = render(<StaffInfo {...getProps({bio: null})} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
    expect(getByText('Teacher')).toBeInTheDocument()
  })

  it('still renders name and bio if email is missing', () => {
    const {getByText} = render(<StaffInfo {...getProps({email: null})} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
    expect(getByText('Office Hours: 9-10am MWF')).toBeInTheDocument()
  })

  it('still renders name if email and bio are missing', () => {
    const {getByText} = render(<StaffInfo {...getProps({email: null, bio: null})} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
  })
})
