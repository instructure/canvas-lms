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

import SVGList, {TYPE} from '../SVGList'
import MultiColorSVG from '../MultiColor/svg'

describe('SVGList', () => {
  let type, onSelect, onMount

  beforeEach(() => (onSelect = () => {}))

  const subject = () => render(<SVGList type={type} onSelect={onSelect} onMount={onMount} />)

  describe('when "type" is "multicolor"', () => {
    beforeEach(() => (type = TYPE.Multicolor))

    it('renders the multicolor SVG list', () => {
      const {getByTestId} = subject()
      expect(getByTestId('multicolor-svg-list')).toBeInTheDocument()
    })

    it('renders an entry for each multicolor icon', () => {
      const {getByTestId} = subject()

      Object.keys(MultiColorSVG).forEach(iconName => {
        expect(getByTestId(`icon-${iconName}`)).toBeInTheDocument()
      })
    })
  })

  describe('when an entry is clicked', () => {
    beforeEach(() => {
      type = TYPE.Multicolor
      onSelect = jest.fn()
    })

    afterEach(() => jest.clearAllMocks())

    it('calls the "onSelect" handler with the selected icon', () => {
      const {getByTestId} = subject()
      fireEvent.click(getByTestId('icon-maker-art'))
      expect(onSelect).toHaveBeenCalledWith(
        expect.stringContaining('art'),
        expect.objectContaining({
          label: 'Art Icon',
        })
      )
    })
  })

  describe('when an "onMount" function is given', () => {
    beforeEach(() => (onMount = jest.fn()))

    it('calls "onMount"', () => {
      subject()
      expect(onMount).toHaveBeenCalledTimes(1)
    })
  })
})
