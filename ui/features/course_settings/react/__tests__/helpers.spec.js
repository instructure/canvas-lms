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

import Helpers from '../helpers'

describe('Course Settings Helpers', () => {
  test('isValidImageType', () => {
    expect(Helpers.isValidImageType('image/jpeg')).toBe(true) // accepts jpeg
    expect(Helpers.isValidImageType('image/gif')).toBe(true) // accepts gif
    expect(Helpers.isValidImageType('image/png')).toBe(true) // accepts png
    expect(Helpers.isValidImageType('image/tiff')).toBe(false) // denies tiff
  })

  test('extractInfoFromEvent', () => {
    const changeEvent = {
      type: 'change',
      target: {
        files: [{type: 'image/jpeg'}],
      },
    }

    const dragEvent = {
      type: 'drop',
      dataTransfer: {
        files: [
          {
            name: 'test',
            type: 'image/jpeg',
          },
        ],
      },
    }

    const changeResults = Helpers.extractInfoFromEvent(changeEvent)
    const expectedChangeResults = {
      file: {
        type: 'image/jpeg',
      },
      type: 'image/jpeg',
    }

    const dragResults = Helpers.extractInfoFromEvent(dragEvent)
    const expectedDragResults = {
      file: {
        name: 'test',
        type: 'image/jpeg',
      },
      type: 'image/jpeg',
    }

    expect(changeResults).toEqual(expectedChangeResults) // creates the proper info from change events
    expect(dragResults).toEqual(expectedDragResults) // creates the proper info from drag events
  })
})
