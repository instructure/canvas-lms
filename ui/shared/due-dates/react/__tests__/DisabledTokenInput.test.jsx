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
import {render, unmountComponentAtNode} from 'react-dom'
import {screen} from '@testing-library/react'
import DisabledTokenInput from '../DisabledTokenInput'

describe('DisabledTokenInput', () => {
  let wrapper = null
  const tokens = ['John Smith', 'Section 2', 'Group 1']

  beforeEach(() => {
    // Setup a DOM element as a render target
    wrapper = document.createElement('div')
    document.body.appendChild(wrapper)
    render(<DisabledTokenInput tokens={tokens} />, wrapper)
  })

  afterEach(() => {
    // Cleanup on exiting
    unmountComponentAtNode(wrapper)
    wrapper.remove()
    wrapper = null
  })

  it('renders a list item for each token passed in', () => {
    const listItems = screen.getAllByRole('listitem')
    expect(listItems.map(item => item.textContent)).toEqual(tokens)
  })
})
