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
import {fireEvent, render} from '@testing-library/react'
import SideNav, {InformationIconEnum} from '../SideNav'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'

const queryClient = new QueryClient()

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
    window.ENV.help_link_icon = 'help'
  })

  it('renders', () => {
    const unreadComponent = jest.fn(() => <></>)

    expect(() =>
      render(
        <QueryClientProvider client={queryClient}>
          <SideNav unreadComponent={unreadComponent} />
        </QueryClientProvider>
      )
    ).not.toThrow()
  })

  // test that SideNav renders a full height container
  it('should render the sidenav div with full height', () => {
    const {getByTestId} = render(
      <QueryClientProvider client={queryClient}>
        <SideNav />
      </QueryClientProvider>
    )

    const sideNavContainer = getByTestId('sidenav-container')
    expect(sideNavContainer).toHaveStyle('height: 100vh;')
  })

  // test that SideNav renders a header logo with Canvas icon logo as default
  it('should render the logo component with canvas logo as default', () => {
    const {getByTestId} = render(
      <QueryClientProvider client={queryClient}>
        <SideNav />
      </QueryClientProvider>
    )

    const sideNavHeaderLogo = getByTestId('sidenav-header-logo')
    expect(sideNavHeaderLogo).toBeInTheDocument()

    const iconCanvasLogo = getByTestId('sidenav-canvas-logo')
    expect(iconCanvasLogo).toBeInTheDocument()
  })

  it('should render the avatar component with the corresponding src from ENV', () => {
    const {getByTestId} = render(
      <QueryClientProvider client={queryClient}>
        <SideNav />
      </QueryClientProvider>
    )

    const avatarComponent = getByTestId('sidenav-user-avatar')
    expect(avatarComponent).toHaveAttribute('src', 'testSrc')
  })

  it('should sets primary-nav-expanded class in body when sidenav is expanded', () => {
    const {getByTestId} = render(
      <QueryClientProvider client={queryClient}>
        <SideNav />
      </QueryClientProvider>
    )

    const sideNavContainer = getByTestId('sidenav-container')

    fireEvent.click(sideNavContainer)

    expect(document.body).toHaveClass('primary-nav-expanded')
  })

  describe('Tests Custom Logo', () => {
    beforeEach(() => {
      window.ENV.active_brand_config = {variables: {'ic-brand-header-image': 'some-url'}}
    })

    afterEach(() => {
      window.ENV.active_brand_config = null
    })

    it('should render custom logo when theme has custom image', () => {
      const {getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      const sideNavHeaderImage = getByTestId('sidenav-brand-logomark')

      expect(sideNavHeaderImage).toBeInTheDocument()
    })
  })

  describe('Tests K5 User Features', () => {
    beforeEach(() => {
      window.ENV.K5_USER = true
    })

    afterAll(() => {
      window.ENV.K5_USER = false
    })

    it('should render text and icons for a K5 User', () => {
      const {getByText, getAllByText, getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      expect(getByText('Subjects')).toBeInTheDocument()
      expect(getAllByText('Home')).toHaveLength(2)
      expect(getByTestId('K5HomeIcon')).toBeInTheDocument()
    })
  })

  describe('Test Help Icon variations', () => {
    it('should render HelpInfo icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.INFORMATION
      const {getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      expect(getByTestId('HelpInfo')).toBeInTheDocument()
    })
    it('should render HelpFolder icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.FOLDER
      const {getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      expect(getByTestId('HelpFolder')).toBeInTheDocument()
    })

    it('should render HelpCog icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.COG

      const {getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      expect(getByTestId('HelpCog')).toBeInTheDocument()
    })
    it('should render HelpLifePreserver icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.LIFE_SAVER
      const {getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      expect(getByTestId('HelpLifePreserver')).toBeInTheDocument()
    })
    it('should render default icon', () => {
      window.ENV.help_link_icon = 'help'
      const {getByTestId} = render(
        <QueryClientProvider client={queryClient}>
          <SideNav />
        </QueryClientProvider>
      )

      expect(getByTestId('HelpQuestion')).toBeInTheDocument()
    })
  })
})
