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
import {fireEvent, render, screen} from '@testing-library/react'
import SideNav, {InformationIconEnum} from '../SideNav'
import {QueryClient} from '@tanstack/react-query'
import {MockedQueryClientProvider} from '@canvas/test-utils/query'
import type {ExternalTool} from '../utils'

const queryClient = new QueryClient()

describe('SideNav', () => {
  beforeEach(() => {
    // @ts-expect-error
    window.ENV.current_user = {
      id: '',
      avatar_image_url: 'testSrc',
      anonymous_id: '',
      display_name: 'Test DisplayName',
      html_url: '',
      pronouns: '',
    }
    // @ts-expect-error
    window.ENV.SETTINGS = {
      collapse_global_nav: false,
    }
    window.ENV.K5_USER = false
    window.ENV.help_link_icon = 'help'
  })

  it('renders', () => {
    expect(() =>
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      ),
    ).not.toThrow()
  })

  it('should render the sidenav div with full height', () => {
    render(
      <MockedQueryClientProvider client={queryClient}>
        <SideNav />
      </MockedQueryClientProvider>,
    )
    const sideNavContainer = screen.getByTestId('sidenav-container')
    expect(sideNavContainer).toHaveStyle('height: 100%;')
  })

  it('should render the logo component with canvas logo as default', () => {
    render(
      <MockedQueryClientProvider client={queryClient}>
        <SideNav />
      </MockedQueryClientProvider>,
    )
    const sideNavHeaderLogo = screen.getByTestId('sidenav-header-logo')
    expect(sideNavHeaderLogo).toBeInTheDocument()
    const iconCanvasLogo = screen.getByTestId('sidenav-canvas-logo')
    expect(iconCanvasLogo).toBeInTheDocument()
  })

  it('should render the avatar component with the corresponding src from ENV', () => {
    render(
      <MockedQueryClientProvider client={queryClient}>
        <SideNav />
      </MockedQueryClientProvider>,
    )
    const avatarComponent = screen.getByTestId('sidenav-user-avatar')
    expect(avatarComponent).toHaveAttribute('src', 'testSrc')
  })

  it('should set primary-nav-expanded class in body when sidenav is expanded', () => {
    render(
      <MockedQueryClientProvider client={queryClient}>
        <SideNav />
      </MockedQueryClientProvider>,
    )
    const sideNavContainer = screen.getByTestId('sidenav-container')
    fireEvent.click(sideNavContainer)
    expect(document.body).toHaveClass('primary-nav-expanded')
  })

  describe('Tests Custom Logo', () => {
    beforeEach(() => {
      window.ENV.active_brand_config = {variables: {'ic-brand-header-image': 'some-url'}}
    })

    afterEach(() => {
      // @ts-expect-error
      window.ENV.active_brand_config = null
    })

    it('should render custom logo when theme has custom image', () => {
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      const sideNavHeaderImage = screen.getByTestId('sidenav-brand-logomark')
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
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByText('Subjects')).toBeInTheDocument()
      expect(screen.getAllByText('Home')).toHaveLength(2)
      expect(screen.getByTestId('K5HomeIcon')).toBeInTheDocument()
    })
  })

  describe('Test Help Icon variations', () => {
    it('should render HelpInfo icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.INFORMATION
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByTestId('HelpInfo')).toBeInTheDocument()
    })
    it('should render HelpFolder icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.FOLDER
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByTestId('HelpFolder')).toBeInTheDocument()
    })

    it('should render HelpCog icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.COG
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByTestId('HelpCog')).toBeInTheDocument()
    })
    it('should render HelpLifePreserver icon', () => {
      window.ENV.help_link_icon = InformationIconEnum.LIFE_SAVER
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByTestId('HelpLifePreserver')).toBeInTheDocument()
    })
    it('should render default icon', () => {
      window.ENV.help_link_icon = 'help'
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByTestId('HelpQuestion')).toBeInTheDocument()
    })
  })

  describe('External Tools', () => {
    it('should render external tools when provided', () => {
      const externalTools: ExternalTool[] = [
        {
          label: 'Tool 1',
          imgSrc: 'img/tool1.png',
          href: 'http://tool1.com',
          svgPath: null,
        },
        {
          label: 'Tool 2',
          imgSrc: null,
          href: 'http://tool2.com',
          svgPath: 'path-to-svg',
        },
      ]
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav externalTools={externalTools} />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByText('Tool 1')).toBeInTheDocument()
      expect(screen.getByText('Tool 2')).toBeInTheDocument()
      expect(screen.getByText('Tool 1').closest('a')).toHaveAttribute(
        'href',
        'http://tool1.com&toolId=tool-1',
      )
      expect(screen.getByText('Tool 2').closest('a')).toHaveAttribute(
        'href',
        'http://tool2.com&toolId=tool-2',
      )
    })

    it('should not render invalid tools', () => {
      const valid_tool_id_derived_from_label = 'Valid Tool'
      const invalid_tool_id_derived_from_label = ''
      const externalTools: ExternalTool[] = [
        {
          label: valid_tool_id_derived_from_label,
          imgSrc: 'img/tool1.png',
          href: 'http://tool1.com',
          svgPath: null,
        },
        {
          label: invalid_tool_id_derived_from_label,
          imgSrc: 'img2.png',
          href: 'http://tool2.com',
          svgPath: 'path2',
        },
      ]
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav externalTools={externalTools} />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByText(valid_tool_id_derived_from_label)).toBeInTheDocument()
      expect(screen.queryByAltText('img2.png')).not.toBeInTheDocument()
      expect(screen.queryByText('http://tool2.com')).not.toBeInTheDocument()
      expect(screen.queryByAltText('path2')).not.toBeInTheDocument()
    })

    it('uses customFields.url when present', () => {
      const externalTools: ExternalTool[] = [
        {
          label: 'Tool 1',
          imgSrc: 'img/tool1.png',
          href: 'https://custom.example.com',
          svgPath: null,
        },
      ]
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav externalTools={externalTools} />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByText('Tool 1')).toBeInTheDocument()
      expect(screen.getByText('Tool 1').closest('a')).toHaveAttribute(
        'href',
        'https://custom.example.com&toolId=tool-1',
      )
    })

    it('uses globalNavigation.url when customFields.url is not present', () => {
      const externalTools: ExternalTool[] = [
        {
          label: 'Tool 2',
          imgSrc: null,
          href: 'https://global.example.com',
          svgPath: 'path-to-svg',
        },
      ]
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav externalTools={externalTools} />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByText('Tool 2')).toBeInTheDocument()
      expect(screen.getByText('Tool 2').closest('a')).toHaveAttribute(
        'href',
        'https://global.example.com&toolId=tool-2',
      )
    })

    it('sets href to null if both customFields.url and globalNavigation.url are not present', () => {
      const externalTools: ExternalTool[] = [
        {
          label: 'Tool 3',
          imgSrc: 'img/tool3.png',
          href: null,
          svgPath: null,
        },
      ]
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav externalTools={externalTools} />
        </MockedQueryClientProvider>,
      )
      expect(screen.getByText('Tool 3')).toBeInTheDocument()
      expect(screen.getByText('Tool 3').closest('a')).toHaveAttribute('href', '#&toolId=tool-3')
    })

    it('should handle tools with null image correctly and use fallback icon', async () => {
      const externalTools: ExternalTool[] = [
        {
          label: 'Tool with Null Image',
          imgSrc: null,
          href: 'http://tool-null-image.com',
          svgPath: null,
        },
      ]
      render(
        <MockedQueryClientProvider client={queryClient}>
          <SideNav externalTools={externalTools} />
        </MockedQueryClientProvider>,
      )
      expect(await screen.findByText('Tool with Null Image')).toBeInTheDocument()
      expect(screen.getByText('Tool with Null Image').closest('a')).toHaveAttribute(
        'href',
        'http://tool-null-image.com&toolId=tool-with-null-image',
      )
      const fallbackIcon = screen.getByTestId('IconExternalLinkLine')
      expect(fallbackIcon).toBeInTheDocument()
    })
  })
})
