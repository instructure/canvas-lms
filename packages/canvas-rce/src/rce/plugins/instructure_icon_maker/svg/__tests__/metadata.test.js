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

import {DEFAULT_SETTINGS} from '../constants'
import {createSvgElement} from '../utils'

import {buildMetadata, parseMetadata} from '../metadata'

describe('buildMetadata() / parseMetadata()', () => {
  it('builds metadata element and parse it back', () => {
    const settings = {...DEFAULT_SETTINGS, shape: 'triangle', color: '#f0f'}

    const metadata = buildMetadata(settings)
    expect(metadata).toMatchInlineSnapshot(`
      <metadata>
        {"type":"image/svg+xml-icon-maker-icons","alt":"","shape":"triangle","size":"small","color":"#f0f","outlineColor":"#000000","outlineSize":"none","text":"","textSize":"small","textColor":"#000000","textBackgroundColor":null,"textPosition":"middle","encodedImage":"","encodedImageType":"","encodedImageName":"","x":0,"y":0,"translateX":0,"translateY":0,"width":0,"height":0,"transform":"","imageSettings":null}
      </metadata>
    `)

    const svg = createSvgElement('svg')
    svg.appendChild(metadata)
    expect(parseMetadata(svg)).toEqual(settings)
  })
})
