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

import * as SvgCategoryProcessor from '../SvgCategoryProcessor'

describe('process()', () => {
  let fileText

  const file = () => ({
    slice: () => ({
      text: async () => fileText
    })
  })

  beforeEach(() => {
    fileText = 'some text in the file'
  })

  const subject = (fileOverride = null) => SvgCategoryProcessor.process(fileOverride || file())

  describe('when the file includes button and icon type', () => {
    beforeEach(() => {
      fileText = 'something something image/svg+xml-buttons-and-icons'
    })

    it('returns the button and icons category', async () => {
      const category = await subject()
      expect(category).toMatchObject({
        category: 'buttons_and_icons'
      })
    })
  })

  describe('when the file does not include button and icon type', () => {
    beforeEach(() => {
      fileText = 'something something not buttons and icons'
    })

    it('returns undefined', async () => {
      const category = await subject()
      expect(category).toBeUndefined()
    })
  })

  describe('when an exception is raised', () => {
    const fileWithError = {
      slice: () => ({
        text: async () => {
          throw 'an error'
        }
      })
    }

    it('returns undefined', async () => {
      const category = await subject(fileWithError)
      expect(category).toBeUndefined()
    })
  })
})
