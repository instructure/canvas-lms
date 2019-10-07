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
import {render, cleanup} from '@testing-library/react'
import ProfileTray from '../ProfileTray'

const imageUrl = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='

describe('ProfileTray', () => {
  let props

  beforeEach(() => {
    props = {
      userDisplayName: 'Sample Student',
      userAvatarURL: imageUrl,
      tabs: [
        {
          id: 'foo',
          label: 'Foo',
          html_url: '/foo'
        },
        {
          id: 'bar',
          label: 'Bar',
          html_url: '/bar'
        }
      ],
      loaded: true
    }
  })

  afterEach(cleanup)

  it('renders the component', () => {
    const {getByText} = render(<ProfileTray {...props} />)
    getByText('Sample Student')
  })

  it('renders the avatar', () => {
    const {getByAltText} = render(<ProfileTray {...props} />)
    const avatar = getByAltText('User profile picture')
    expect(avatar.src).toBe(imageUrl)
  })

  it('renders loading spinner', () => {
    const {getByTitle, queryByText} = render(<ProfileTray {...props} loaded={false} />)
    getByTitle('Loading')
    expect(queryByText('Foo')).toBeFalsy()
  })

  it('renders the tabs', () => {
    const {getByText} = render(<ProfileTray {...props} />)
    getByText('Foo')
    getByText('Bar')
  })
})
