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
import {render} from '@testing-library/react'
import React from 'react'
import MentionDropdownMenu from '../MentionDropdownMenu'

const MentionMockUsers = [
  {
    id: 1,
    name: 'Jeffrey Johnson'
  },
  {
    id: 2,
    name: 'Matthew Lemon'
  }
]

const setup = props => {
  return render(<MentionDropdownMenu mentionOptions={MentionMockUsers} {...props} />)
}

describe('MentionDropdownMenu tests', () => {
  it('should render', () => {
    const component = setup()
    expect(component).toBeTruthy()
  })

  it('should render correct number of menu items', () => {
    const component = setup({
      show: true
    })
    const items = component.container.querySelectorAll('li')
    expect(items.length).toBe(2)
  })

  it('should not show when prop is false', () => {
    const {container} = setup({
      show: false
    })
    const menuComponent = container.querySelector('.mention-dropdown-menu')
    expect(menuComponent).toBeFalsy()
  })

  it('should show when prop is true', () => {
    const {container} = setup({
      show: true
    })
    const menuComponent = container.querySelector('.mention-dropdown-menu')
    expect(menuComponent).toBeTruthy()
  })

  it('should load x and y props respectively', () => {
    const {container} = setup({
      show: true,
      x: '42',
      y: '24'
    })
    const menuContainer = container.querySelector('.mention-dropdown-menu')
    expect(menuContainer.style.left).toBe('42px')
    expect(menuContainer.style.top).toBe('24px')
  })
})
