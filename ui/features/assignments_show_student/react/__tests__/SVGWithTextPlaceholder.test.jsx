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
import ReactDOM from 'react-dom'
import $ from 'jquery'

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

  afterEach(() => {
    ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
  })

  it('renders correctly with required props', () => {
    ReactDOM.render(
      <SVGWithTextPlaceholder url="www.test.com" text="coolest test ever" />,
      document.getElementById('fixtures')
    )
    const textContainer = $('#fixtures:contains("coolest test ever")')
    const imgContainer = $("img[src$='www.test.com']")
    expect(textContainer).toHaveLength(1)
    expect(imgContainer).toHaveLength(1)
  })

  it('renders if empty is provided to the text prop', () => {
    ReactDOM.render(
      <SVGWithTextPlaceholder url="www.test.com" text="" />,
      document.getElementById('fixtures')
    )
    const imgContainer = $("img[src$='www.test.com']")
    expect(imgContainer).toHaveLength(1)
  })

  it('renders with null in img prop', () => {
    ReactDOM.render(
      <SVGWithTextPlaceholder text="coolest test ever" url="" />,
      document.getElementById('fixtures')
    )
    const textContainer = $('#fixtures:contains("coolest test ever")')
    expect(textContainer).toHaveLength(1)
  })

  it('renders when no props provided', () => {
    ReactDOM.render(
      <SVGWithTextPlaceholder text="coolest test ever" url="" />,
      document.getElementById('fixtures')
    )
    const imgContainer = $('img')
    expect(imgContainer).toHaveLength(1)
  })
})
