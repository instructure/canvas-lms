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

import React from 'react'
import {fireEvent, render} from '@testing-library/react'

import {ZoomControls} from '../ZoomControls'

describe('ZoomControls', () => {
  it('renders buttons with min scale ratio', () => {
    const {container} = render(<ZoomControls scaleRatio={1} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    const zoomInButton = container.querySelectorAll('button')[1]
    expect(zoomOutButton.hasAttribute('disabled')).toBeTruthy()
    expect(zoomInButton.hasAttribute('disabled')).toBeFalsy()
  })

  it('renders buttons with max scale ratio', () => {
    const {container} = render(<ZoomControls scaleRatio={2} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    const zoomInButton = container.querySelectorAll('button')[1]
    expect(zoomOutButton.hasAttribute('disabled')).toBeFalsy()
    expect(zoomInButton.hasAttribute('disabled')).toBeTruthy()
  })

  it('renders buttons with average scale ratio', () => {
    const ratio = 1.5
    const {container} = render(<ZoomControls scaleRatio={ratio} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    const zoomInButton = container.querySelectorAll('button')[1]
    expect(zoomOutButton.hasAttribute('disabled')).toBeFalsy()
    expect(zoomInButton.hasAttribute('disabled')).toBeFalsy()
  })

  it('calls function when zoom out is clicked', () => {
    const callback = jest.fn()
    const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    fireEvent.click(zoomOutButton)
    expect(callback).toHaveBeenCalledWith(1.4)
  })

  it('calls function when zoom in is clicked', () => {
    const callback = jest.fn()
    const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
    const zoomInButton = container.querySelectorAll('button')[1]
    fireEvent.click(zoomInButton)
    expect(callback).toHaveBeenCalledWith(1.6)
  })
})
