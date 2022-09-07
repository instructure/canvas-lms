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
import {render} from '@testing-library/react'
import {DirectionRegion, Direction} from '../DirectionRegion'

describe('DirectionRegion', () => {
  describe('renders the correct message when', () => {
    it('direction corresponds to "left"', () => {
      const {container} = render(<DirectionRegion direction={Direction.LEFT} />)
      const directionText = container.querySelector('span')?.innerHTML
      expect(directionText).toEqual('Moving image to crop Left')
    })

    it('direction corresponds to "up"', () => {
      const {container} = render(<DirectionRegion direction={Direction.UP} />)
      const directionText = container.querySelector('span')?.innerHTML
      expect(directionText).toEqual('Moving image to crop Up')
    })

    it('direction corresponds to "right"', () => {
      const {container} = render(<DirectionRegion direction={Direction.RIGHT} />)
      const directionText = container.querySelector('span')?.innerHTML
      expect(directionText).toEqual('Moving image to crop Right')
    })

    it('direction corresponds to "down"', () => {
      const {container} = render(<DirectionRegion direction={Direction.DOWN} />)
      const directionText = container.querySelector('span')?.innerHTML
      expect(directionText).toEqual('Moving image to crop Down')
    })

    it('direction corresponds to "none"', () => {
      const {container} = render(<DirectionRegion direction={Direction.NONE} />)
      const directionText = container.querySelector('span')?.innerHTML
      expect(directionText).toEqual('')
    })
  })
})
