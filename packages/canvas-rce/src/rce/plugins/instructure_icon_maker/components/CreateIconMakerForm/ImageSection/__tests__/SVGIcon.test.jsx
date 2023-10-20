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

import SVGThumbnail from '../SVGThumbnail'

describe('SVGThumbnail', () => {
  let name

  const source = {
    foo: {
      source: () => '<svg />',
      label: 'Foo',
    },
  }

  const subject = () => render(<SVGThumbnail name={name} source={source} />)

  describe('when the name corresponds to an icon', () => {
    beforeEach(() => (name = 'foo'))

    it('renders the SVG icon', () => {
      const {getByTestId} = subject()
      expect(getByTestId('icon-foo')).toBeInTheDocument()
    })
  })

  describe('when the name does not correspond to an icon', () => {
    beforeEach(() => (name = 'banana'))

    it('renders the empty SVG without error', () => {
      const {getByTestId} = subject()
      expect(getByTestId('icon-banana')).toBeInTheDocument()
    })
  })
})
