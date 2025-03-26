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
import {render, screen} from '@testing-library/react'
import NoPeopleFound from '../NoPeopleFound'
import useCoursePeopleContext from '../../../hooks/useCoursePeopleContext'

jest.mock('../../../hooks/useCoursePeopleContext')

const useCoursePeopleContextMocks = {
  canViewLoginIdColumn: true,
  canViewSisIdColumn: true,
}

describe('NoPeopleFound', () => {
  const renderComponent = () => render(<NoPeopleFound />)

  describe('all users', () => {
    beforeEach(() => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue(useCoursePeopleContextMocks)
      renderComponent()
    })

    it('renders the component with image, heading and search tips', () => {
      expect(screen.getByTestId('no-people-found-img')).toBeInTheDocument()
      expect(screen.getByText('No people found')).toBeInTheDocument()
      expect(screen.getByText('You can search by:')).toBeInTheDocument()
    })

    it('renders name search option', () => {
      expect(screen.getByText('Name')).toBeInTheDocument()
    })

    it('renders Canvas User ID option', () => {
      expect(screen.getByText('Canvas User ID')).toBeInTheDocument()
    })
  })

  describe('users with permissions', () => {
    beforeEach(() => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue(useCoursePeopleContextMocks)
      renderComponent()
    })

    it('renders Login ID option when canViewLoginIdColumn is true', () => {
      expect(screen.getByText('Login ID')).toBeInTheDocument()
    })

    it('renders SIS ID option when canViewSisIdColumn is true', () => {
      expect(screen.getByText('SIS ID')).toBeInTheDocument()
    })
  })

  describe('users with partial permissions', () => {
    it('does not render Login ID option when canViewLoginIdColumn is false', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...useCoursePeopleContextMocks,
        canViewLoginIdColumn: false,
      })
      renderComponent()
      expect(screen.queryByText('Login ID')).not.toBeInTheDocument()
    })

    it('does not render SIS ID option when canViewSisIdColumn is false', () => {
      (useCoursePeopleContext as jest.Mock).mockReturnValue({
        ...useCoursePeopleContextMocks,
        canViewSisIdColumn: false,
      })
      renderComponent()
      expect(screen.queryByText('SIS ID')).not.toBeInTheDocument()
    })
  })
})
