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

import * as CategoryProcessor from '../CategoryProcessor'
import {TYPE, ICON_MAKER_ICONS, SVG_TYPE} from '../../../instructure_icon_maker/svg/constants'

describe('process()', () => {
  let fileText, fileType

  const file = () => ({
    slice: () => ({
      text: async () => fileText,
    }),
    type: fileType,
  })

  const subject = (fileOverride = null) => CategoryProcessor.process(fileOverride || file())

  beforeEach(() => {
    fileText = 'some text in the file'
  })

  describe('when the file type matches the SVG processor', () => {
    beforeEach(() => {
      fileType = SVG_TYPE
      fileText = 'something something ' + TYPE
    })

    it('processes the file with the SVG processor', async () => {
      const category = await subject()
      expect(category).toMatchObject({
        category: ICON_MAKER_ICONS,
      })
    })
  })

  describe('when the file type does not match a processor', () => {
    beforeEach(() => {
      fileType = 'image/png'
    })

    it('returns undefined', async () => {
      const category = await subject()
      expect(category).toBeUndefined()
    })
  })

  describe('when no file is given', () => {
    it('returns undefined', async () => {
      const category = await CategoryProcessor.process(undefined)
      expect(category).toBeUndefined()
    })
  })
})
