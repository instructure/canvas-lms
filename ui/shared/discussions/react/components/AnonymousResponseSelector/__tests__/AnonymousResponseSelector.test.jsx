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

import {AnonymousResponseSelector} from '../AnonymousResponseSelector'
import React from 'react'
import {render} from '@testing-library/react'

const setup = ({username = 'Rubius Hagrid', discussionAnonymousState = null} = {}) => {
  return (
    <AnonymousResponseSelector
      discussionAnonymousState={discussionAnonymousState}
      username={username}
    />
  )
}

describe('Anonymous Response Selector', () => {
  describe('Full Anonymity', () => {
    it('should render anonymous avatar', async () => {
      const container = render(setup({discussionAnonymousState: 'full_anonymity'}))
      expect(container.queryByTestId('anonymous_avatar')).toBeTruthy()
      expect(await container.findByText('Anonymous')).toBeTruthy()
    })
  })

  describe('Partial Anonymity', () => {
    it('should render select', () => {
      const container = render(setup({discussionAnonymousState: 'partial_anonymity'}))
      expect(container.queryByTestId('anonymous_avatar')).toBeTruthy()
    })
  })

  describe('No Anonymity', () => {
    it('should not render anonymous avatar', async () => {
      const container = render(setup())
      expect(container.queryByTestId('anonymous_avatar')).toBeNull()
      expect(await container.findByText('Rubius Hagrid')).toBeTruthy()
    })
  })
})
