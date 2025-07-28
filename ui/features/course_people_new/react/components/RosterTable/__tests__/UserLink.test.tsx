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
import {render, within} from '@testing-library/react'
import UserLink from '../UserLink'
import {mockEnrollment} from '../../../../graphql/Mocks'
import {
  PENDING_ENROLLMENT,
  INACTIVE_ENROLLMENT
} from '../../../../util/constants'

describe('UserLink', () => {
  const defaultProps = {
    uid: '1',
    name: 'John Doe',
    pronouns: null,
    htmlUrl: 'https://example.com/user',
    avatarUrl: 'https://example.com/avatar.jpg',
    enrollments: [mockEnrollment()],
  }

  describe('user details', () => {
    it('renders the link with the correct href', () => {
      const {getByTestId} = render(<UserLink {...defaultProps} />)
      expect(getByTestId(`link-user-${defaultProps.uid}`)).toHaveAttribute('href', defaultProps.htmlUrl)
    })

    it('renders the avatar with the correct src and name initials', () => {
      const nameInitials = defaultProps.name
        .split(' ')
        .map(s => s.charAt(0))
        .reduce((acc, n) => acc + n, '')
      const {getByTestId} = render(<UserLink {...defaultProps} />)
      const avatar = getByTestId(`avatar-user-${defaultProps.uid}`)
      expect(avatar).toHaveAttribute('src', defaultProps.avatarUrl)
      expect(within(avatar).getByText(nameInitials)).toBeInTheDocument()
    })

    it('renders the name with pronouns if provided', () => {
      const {getByText, getByTestId} = render(<UserLink {...defaultProps} pronouns='he/him' />)
      expect(getByTestId(`name-user-${defaultProps.uid}`)).toHaveTextContent(defaultProps.name)
      expect(getByTestId(`pronouns-user-${defaultProps.uid}`)).toBeInTheDocument()
      expect(getByText('(he/him)')).toBeInTheDocument()
    })

    it('renders the name without pronouns if not provided', () => {
      const {getByTestId, queryByTestId} = render(<UserLink {...defaultProps} />)
      expect(getByTestId(`name-user-${defaultProps.uid}`)).toHaveTextContent(defaultProps.name)
      expect(queryByTestId(`pronouns-user-${defaultProps.uid}`)).not.toBeInTheDocument()
    })
  })

  describe('status indicators', () => {
    it('renders pending status', () => {
      const pendingEnrollment = [mockEnrollment({enrollmentState: PENDING_ENROLLMENT})]
      const {getByText} = render(<UserLink {...defaultProps} enrollments={pendingEnrollment} />)
      expect(getByText('Pending')).toBeInTheDocument()
    })

    it('renders inactive status', () => {
      const inactiveEnrollment = [mockEnrollment({enrollmentState: INACTIVE_ENROLLMENT})]
      const {getByText} = render(<UserLink {...defaultProps} enrollments={inactiveEnrollment} />)
      expect(getByText('Inactive')).toBeInTheDocument()
    })

    it('prioritizes pending over inactive state', () => {
      const pendingAndInactiveEnrollment = [
        mockEnrollment({enrollmentState: PENDING_ENROLLMENT}),
        mockEnrollment({enrollmentState: INACTIVE_ENROLLMENT})
      ]
      const {getByText, queryByText} = render(<UserLink {...defaultProps} enrollments={pendingAndInactiveEnrollment} />)
      expect(getByText('Pending')).toBeInTheDocument()
      expect(queryByText('Inactive')).not.toBeInTheDocument()
    })

    it('does not render any status indicators by default', () => {
      const {queryByText} = render(<UserLink {...defaultProps} />)
      expect(queryByText('Pending')).not.toBeInTheDocument()
      expect(queryByText('Inactive')).not.toBeInTheDocument()
    })
  })
})
