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

describe('applyCategory()', () => {
  let fileText, fileType

  let file = () => ({
    slice: () => ({
      text: async () => fileText
    }),
    type: fileType
  })

  const fileOptions = () => [
    {
      file: file()
    }
  ]

  const subject = () => FileOptionsCollection.applyCategory(fileOptions())

  describe('when the file is an svg', () => {
    beforeEach(() => {
      fileType = 'image/svg'
    })

    describe('when the file is a button & icon', () => {
      beforeEach(() => {
        fileText = 'something something image/svg+xml-buttons-and-icons'
      })

      it('adds the button and icon category', async () => {
        const options = await subject()
        expect(options[0].category).toEqual('buttons_and_icons')
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
  let fileText, fileType

  let file = () => ({
    slice: () => ({
      text: async () => fileText
    }),
    type: fileType
  })

  const fileOptions = () => [
    {
      file: file()
    }
  ]

  beforeEach(() => {
    FileOptionsCollection.setState({
      resolvedNames: fileOptions()
    })

    FileOptionsCollection.applyCategory = jest.fn(() => Promise.resolve([{}]))
  })

  const subject = () => FileOptionsCollection.queueUploads(1, 'course')

  afterEach(() => jest.resetAllMocks())

  it('applies categories to each resolved file option', () => {
    subject()
    expect(FileOptionsCollection.applyCategory).toHaveBeenCalledWith(
      FileOptionsCollection.state.resolvedNames
    )
  })
})
