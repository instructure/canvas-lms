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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import {AnonymousPostSelector} from '../AnonymousPostSelector'

const setup = () => {
  return <AnonymousPostSelector />
}

describe('AnonymousPostSelector', () => {
  beforeAll(() => {
    window.ENV.current_user = {display_name: 'Ronald Weasley'}
  })

  it('should render', () => {
    const container = render(setup())
    expect(container).toBeTruthy()
  })

  it('should render current user by default', () => {
    const container = render(setup())

    expect(container.getByTestId('current_user_avatar')).toBeTruthy()
    expect(container.getByText('Ronald Weasley')).toBeTruthy()
    expect(container.getByText('Show name and profile picture')).toBeTruthy()
  })

  it('should allow to change to Hide from everyone', () => {
    const container = render(setup())

    fireEvent.click(container.getByTestId('anonymous_post_selector'))
    fireEvent.click(container.getByText('Hide from everyone'))

    expect(container.getByTestId('anonymous_avatar')).toBeTruthy()
    expect(container.getByText('Anonymous')).toBeTruthy()
    expect(container.getByText('Hide name and profile picture')).toBeTruthy()
  })
})
