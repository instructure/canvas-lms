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

import FileOptionsCollection from '../FileOptionsCollection'
import UploadQueue from '../UploadQueue'
import {
  TYPE,
  ICON_MAKER_ICONS,
  SVG_TYPE,
} from '@instructure/canvas-rce/src/rce/plugins/instructure_icon_maker/svg/constants'

jest.mock('../UploadQueue')

interface FileOption {
  file: {
    slice: () => {text: () => Promise<string>}
    type: string
  }
  category?: string
}

describe('FileOptionsCollection', () => {
  let fileText: string
  let fileType: string

  const file = (): FileOption['file'] => ({
    slice: () => ({
      text: async () => fileText,
    }),
    type: fileType,
  })

  const fileOptions = (): FileOption[] => [
    {
      file: file(),
    },
  ]

  beforeEach(() => {
    jest.clearAllMocks()
    FileOptionsCollection.folder = {id: '1'}
  })

  describe('applyCategory()', () => {
    const subject = async (): Promise<FileOption[]> =>
      FileOptionsCollection.applyCategory(fileOptions())

    describe('when the file is an svg', () => {
      beforeEach(() => {
        fileType = SVG_TYPE
      })

      describe('when the file is a button & icon', () => {
        beforeEach(() => {
          fileText = 'something something ' + TYPE
        })

        it('adds the icon maker icons category', async () => {
          const options = await subject()
          expect(options[0].category).toEqual(ICON_MAKER_ICONS)
        })
      })

      describe('when the file is not a button & icon', () => {
        beforeEach(() => {
          fileText = 'something something not buttons and icons'
        })

        it('sets the category to undefined', async () => {
          const options = await subject()
          expect(options[0].category).toBeUndefined()
        })
      })
    })

    describe('when the file is not an SVG', () => {
      beforeEach(() => {
        fileType = 'image/png'
      })

      it('sets the category to undefined', async () => {
        const options = await subject()
        expect(options[0].category).toBeUndefined()
      })
    })
  })

  describe('queueUploads()', () => {
    beforeEach(() => {
      FileOptionsCollection.setState({
        resolvedNames: fileOptions(),
      })
    })

    it('applies categories to each resolved file option', async () => {
      await FileOptionsCollection.queueUploads(1, 'course')
      expect(UploadQueue.enqueue).toHaveBeenCalledTimes(1)
    })
  })
})
