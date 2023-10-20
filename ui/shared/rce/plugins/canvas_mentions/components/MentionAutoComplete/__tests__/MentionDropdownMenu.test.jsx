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
import {ARIA_ID_TEMPLATES} from '../../../constants'

const MentionMockUsers = [
  {
    id: 1,
    name: 'Jeffrey Johnson',
  },
  {
    id: 2,
    name: 'Matthew Lemon',
  },
]

const mockCoordinates = {
  height: 258,
  left: 312,
  right: 530,
  top: 250,
  width: 218,
  x: 312,
  y: 25,
}

const tinyMCE = {
  activeEditor: {
    getParam: () => 'LTR',
  },
}

const setup = props => {
  return render(
    <MentionDropdownMenu
      mentionOptions={MentionMockUsers}
      coordiantes={mockCoordinates}
      {...props}
    />
  )
}

describe('MentionDropdownMenu tests', () => {
  beforeEach(() => {
    global.tinyMCE = tinyMCE
  })

  afterEach(() => {
    global.tinyMCE = null
  })

  it('should render', () => {
    const component = setup()
    expect(component).toBeTruthy()
  })

  it('should render correct number of menu items', () => {
    const component = setup()
    const items = component.container.querySelectorAll('li')
    expect(items.length).toBe(2)
  })

  it('should call ARIA template for the Popup menu', () => {
    const spy = jest.spyOn(ARIA_ID_TEMPLATES, 'ariaControlTemplate')
    setup()
    expect(spy).toHaveBeenCalled()
    expect(spy.mock.calls.length).toBe(2)
  })
})
