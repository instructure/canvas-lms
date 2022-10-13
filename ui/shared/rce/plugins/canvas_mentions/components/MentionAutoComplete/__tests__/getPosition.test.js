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
import getPosition from '../getPosition'

describe('Get Position tests', () => {
  const editor = {
    getContainer: () => ({
      querySelector: () => ({
        getBoundingClientRect: () => ({
          top: 10,
          bottom: 10,
          left: 10,
          right: 10,
          width: 10,
          height: 10,
        }),
      }),
    }),
  }
  const tinymce = {
    dom: {
      DomQuery: () => [
        {
          getBoundingClientRect: () => ({
            top: 10,
            bottom: 10,
            left: 10,
            right: 10,
            width: 10,
            height: 10,
          }),
        },
      ],
    },
  }

  beforeEach(() => {
    global.tinymce = tinymce
  })

  afterEach(() => {
    global.tinymce = null
  })

  it('should return a getClientRect object that is the sum of two clientRects', () => {
    const position = getPosition(editor, '')
    expect(position.top).toBe(20)
    expect(position.bottom).toBe(20)
    expect(position.left).toBe(20)
    expect(position.right).toBe(20)
    expect(position.width).toBe(10)
    expect(position.height).toBe(10)
  })
})
