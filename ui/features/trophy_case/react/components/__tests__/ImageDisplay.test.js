/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import ImageDisplay from '../ImageDisplay'
import React from 'react'

describe('TrophyCase::current::ImageDisplay', () => {
  describe('discovered trophy', () => {
    it('renders the image', () => {
      const {getByAltText} = render(
        <ImageDisplay trophy_key="discovered" unlocked_at="2020-01-01" />
      )
      const style = window.getComputedStyle(getByAltText('discovered'))
      expect(style.filter).not.toMatch(/blur.* grayscale.*/)
    })
  })

  describe('undiscovered trophy', () => {
    it('obscures the image', () => {
      const {getByAltText} = render(<ImageDisplay trophy_key="undiscovered" />)
      const style = window.getComputedStyle(getByAltText('undiscovered'))
      expect(style.filter).toMatch(/blur.* grayscale.*/)
    })
  })
})
