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
import {QueryProvider, queryClient} from '@canvas/query'
import type {TabCountsObj} from '../../../../../api.d'

const render = (children: unknown) =>
  testingLibraryRender(<QueryProvider>{children}</QueryProvider>)

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
]

describe('ProfileTray', () => {
  let props: {counts: TabCountsObj}

  beforeEach(() => {
    window.ENV = {
      // @ts-expect-error
      current_user: {
        display_name: 'Sample Student',
        avatar_is_fallback: true,
      },
      current_user_roles: [],
    }

    props = {
      counts: {unreadShares: 12},
    }
  })

  afterEach(() => {
    queryClient.removeQueries()
  })

  it('renders the component', () => {
    const {getByText} = render(<ProfileTray {...props} />)
    getByText('Sample Student')
  })

  it('renders the avatar', () => {
    window.ENV.current_user.avatar_is_fallback = false
    window.ENV.current_user.avatar_image_url = imageUrl
    const {getByAltText} = render(<ProfileTray {...props} />)
    const avatar = getByAltText('User profile picture')
    // @ts-expect-error
    expect(avatar.src).toBe(imageUrl)
  })

  it('renders the tabs', () => {
    queryClient.setQueryData(['profile'], profileTabs)
    const {getByText} = render(<ProfileTray {...props} />)
    getByText('Foo')
    getByText('Bar')
  })

  it('renders the unread count badge on Shared Content', () => {
    queryClient.setQueryData(['profile'], profileTabs)
    const {container} = render(<ProfileTray {...props} />)
    // @ts-expect-error
    const elt = container.firstChild.querySelector('a[href="/shared"]')
    domGetByText(elt, '12 unread.')
  })
})
