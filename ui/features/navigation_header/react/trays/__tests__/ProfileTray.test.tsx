/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import {render as testingLibraryRender} from '@testing-library/react'
import {getByText as domGetByText} from '@testing-library/dom'
import ProfileTray from '../ProfileTray'
import {queryClient} from '@canvas/query'
import {MockedQueryProvider} from '@canvas/test-utils/query'

const render = (children: unknown) =>
  testingLibraryRender(<MockedQueryProvider>{children}</MockedQueryProvider>)

const imageUrl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

const profileTabs = [
  {
    id: 'foo',
    label: 'Foo',
    html_url: '/foo',
  },
  {
    id: 'bar',
    label: 'Bar',
    html_url: '/bar',
  },
  {
    id: 'content_shares',
    label: 'Shared Content',
    html_url: '/shared',
  },
  {
    id: 'external_tool',
    label: 'External Tool',
    html_url: '/accounts/1/external_tools/1?display=borderless',
    type: 'external',
  },
]

describe('ProfileTray', () => {
  beforeEach(() => {
    window.ENV = {
      // @ts-expect-error
      current_user: {
        display_name: 'Sample Student',
        avatar_is_fallback: true,
      },
      current_user_roles: [],
    }
  })

  afterEach(() => {
    queryClient.removeQueries()
  })

  it('renders the component', () => {
    const {getByText} = render(<ProfileTray />)
    getByText('Sample Student')
  })

  describe('when "open_tools_in_new_tab" FF is enabled', () => {
    beforeEach(() => {
      window.ENV.FEATURES ||= {}
      window.ENV.FEATURES.open_tools_in_new_tab = true
    })

    it('renders external tool tabs with correct target attributes', () => {
      queryClient.setQueryData(['profile'], profileTabs)
      const {getByText} = render(<ProfileTray />)
      const toolLink = getByText('External Tool').closest('a')
      expect(toolLink).toHaveAttribute('target', '_blank')
    })
  })

  it('renders the avatar', () => {
    window.ENV.current_user.avatar_is_fallback = false
    window.ENV.current_user.avatar_image_url = imageUrl
    const {getByAltText} = render(<ProfileTray />)
    const avatar = getByAltText('User profile picture') as HTMLImageElement
    expect(avatar.src).toBe(imageUrl)
  })

  it('renders the tabs', () => {
    queryClient.setQueryData(['profile'], profileTabs)
    const {getByText} = render(<ProfileTray />)
    getByText('Foo')
    getByText('Bar')
  })

  it('renders the unread count badge on Shared Content', () => {
    queryClient.setQueryData(['profile'], profileTabs)
    queryClient.setQueryData(['unread_count', 'content_shares'], 12)
    const {container} = render(<ProfileTray />)
    // @ts-expect-error
    const elt = container.firstChild.querySelector('a[href="/shared"]')
    domGetByText(elt, '12 unread.')
  })

  it('renders the high contrast toggle', () => {
    const {getByTestId} = render(<ProfileTray />)
    const toggle = getByTestId('high-contrast-toggle')
    expect(toggle).toBeInTheDocument()
  })

  describe('use dyslexic friendly font toggle', () => {
    describe('when the use_dyslexic_font feature is shadowed', () => {
      beforeEach(() => {
        delete window.ENV.use_dyslexic_font
      })

      it('does not render the dyslexic font toggle', () => {
        const {queryByTestId} = render(<ProfileTray />)
        const toggle = queryByTestId('dyslexic-font-toggle')
        expect(toggle).not.toBeInTheDocument()
      })
    })

    describe('when the use_dyslexic_font feature is not shadowed', () => {
      beforeEach(() => {
        window.ENV.use_dyslexic_font = false
      })

      it('renders the dyslexic font toggle', () => {
        const {getByTestId} = render(<ProfileTray />)
        const toggle = getByTestId('dyslexic-font-toggle')
        expect(toggle).toBeInTheDocument()
      })
    })
  })
})
