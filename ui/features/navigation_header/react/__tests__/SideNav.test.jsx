// Copyright (C) 2023 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.
import React from 'react'
import {render} from '@testing-library/react'
import SideNav from '../SideNav'

describe('SideNav', () => {
  // test that SideNav renders without errors
  beforeEach(() => {
    window.ENV.current_user = {
      id: '',
      avatar_image_url: 'testSrc',
      anonymous_id: '',
      display_name: 'Test DisplayName',
      html_url: '',
      pronouns: '',
    }
    window.ENV.K5_USER = false
  })

  it('renders', () => {
    const unreadComponent = jest.fn(() => <></>)

    expect(() => render(<SideNav unreadComponent={unreadComponent} />)).not.toThrow()
  })

  // test that SideNav renders a full height container
  it('should render the sidenav div with full height', () => {
    const {getByTestId} = render(<SideNav />)

    const sideNavContainer = getByTestId('sidenav-container')
    expect(sideNavContainer).toHaveStyle('height: 100vh;')
  })

  // test that SideNav renders a header logo with Canvas icon logo as default
  it('should render the logo component with canvas logo as default', () => {
    const {getByTestId} = render(<SideNav />)

    const sideNavHeaderLogo = getByTestId('sidenav-header-logo')
    expect(sideNavHeaderLogo).toBeInTheDocument()

    const iconCanvasLogo = getByTestId('icon-canvas-logo')
    expect(iconCanvasLogo).toBeInTheDocument()
  })

  it('should render the avatar component with the corresponding src from ENV', () => {
    const {getByTestId} = render(<SideNav />)

    const avatarComponent = getByTestId('avatar')
    expect(avatarComponent).toHaveAttribute('src', 'testSrc')
  })

  describe( 'Tests K5 user features', () => {
    beforeEach(() => {
      window.ENV.K5_USER = true
    })
    afterAll(() => {
      window.ENV.K5_USER = false
    })
    it('should render text and icons for a K5 User', () => {
      const {getByText, getAllByText, getByTestId} = render(<SideNav />)

      expect(getByText('Subjects')).toBeInTheDocument()
      expect(getAllByText('Home')).toHaveLength(2)
      expect(getByTestId('K5HomeIcon')).toBeInTheDocument()
    })
  })
})
