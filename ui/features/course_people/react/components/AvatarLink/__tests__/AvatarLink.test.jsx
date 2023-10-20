/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import React from 'react'
import AvatarLink from '../AvatarLink'

const DEFAULT_PROPS = {
  name: 'Test User',
  avatarUrl: 'https://gravatar.com/avatar/52c160622b09015c70fa0f4c25de6cca?s=200&d=identicon&r=pg',
  href: 'http://test.host/courses/1/users/2',
}

describe('AvatarLink', () => {
  const setup = props => {
    return render(<AvatarLink {...props} />)
  }

  describe('Test with all props provided', () => {
    it('should render', () => {
      const container = setup(DEFAULT_PROPS)
      expect(container).toBeTruthy()
    })

    it('should have a link element with an href attribute', async () => {
      const container = setup(DEFAULT_PROPS)
      const link = await container.findByRole('link')
      expect(link).toHaveAttribute('href', DEFAULT_PROPS.href)
    })

    it('should have an image element with an src attribute', async () => {
      const container = setup(DEFAULT_PROPS)
      const img = await container.findByRole('img')
      expect(img).toHaveAttribute('src', DEFAULT_PROPS.avatarUrl)
    })

    it('should have an image element with an alt attribute', async () => {
      const container = setup(DEFAULT_PROPS)
      const img = await container.findByRole('img')
      expect(img).toHaveAttribute('alt', expect.stringMatching(/avatar/i))
    })
  })

  describe('Test with avatarUrl prop as null', () => {
    it('should render', () => {
      const container = setup({...DEFAULT_PROPS, avatarUrl: null})
      expect(container).toBeTruthy()
    })

    it('should have a link element with an href attribute', async () => {
      const container = setup({...DEFAULT_PROPS, avatarUrl: null})
      const link = await container.findByRole('link')
      expect(link).toHaveAttribute('href', DEFAULT_PROPS.href)
    })

    it('should display user intials if no avatarUrl is provided', async () => {
      const container = setup({...DEFAULT_PROPS, avatarUrl: null})
      const userInitials = DEFAULT_PROPS.name
        .split(' ')
        .reduce((prev, curr) => `${prev}${curr[0]}`, '')
      const elementWithInitials = await container.findByText(userInitials)
      expect(elementWithInitials).toBeInTheDocument()
    })
  })
})
