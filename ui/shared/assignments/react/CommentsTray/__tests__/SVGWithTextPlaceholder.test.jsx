/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import SVGWithTextPlaceholder from '../SVGWithTextPlaceholder'

describe('SVGWithTextPlaceholder', () => {
  beforeAll(() => {
    const found = document.getElementById('fixtures')
    if (!found) {
      const fixtures = document.createElement('div')
      fixtures.setAttribute('id', 'fixtures')
      document.body.appendChild(fixtures)
    }
  })

  it('renders correctly with required props', () => {
    const container = render(<SVGWithTextPlaceholder url="www.test.com" text="coolest test ever" />)
    expect(container.getByText('coolest test ever')).toBeInTheDocument()
    expect(container.getByRole('img')).toHaveAttribute('src', 'www.test.com')
  })

  it('renders if empty is provided to the text prop', () => {
    const container = render(<SVGWithTextPlaceholder url="www.test.com" text="" />)
    expect(container.getByRole('img')).toHaveAttribute('src', 'www.test.com')
  })

  it('renders with null in img prop', () => {
    const container = render(<SVGWithTextPlaceholder text="coolest test ever" url="" />)
    expect(container.getByText('coolest test ever')).toBeInTheDocument()
  })

  it('renders when no props provided', () => {
    const container = render(<SVGWithTextPlaceholder text="coolest test ever" url="" />)
    expect(container.getByRole('img')).toBeInTheDocument()
  })
})
