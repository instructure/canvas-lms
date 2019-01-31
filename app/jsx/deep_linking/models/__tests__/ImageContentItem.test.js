/*
* Copyright (C) 2018 - present Instructure, Inc.
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

import ImageContentItem from '../ImageContentItem'

const json = {
  url: 'https://www.test.com/image',
  title: 'Title',
  text: 'some text',
  invalidProp: 'banana'
}

const imageContentItem = overrides => {
  const mergedJson = {...json, ...overrides}
  return new ImageContentItem(mergedJson)
}


describe('constructor', () => {
  it('sets the type', () => {
    expect(imageContentItem().type).toEqual('image')
  })
})

describe('toHtmlString', () => {
  it('creates an image tag', () => {
    expect(imageContentItem().toHtmlString()).toEqual(
      '<img src="https://www.test.com/image" alt="some text">'
    )
  })

  describe('when width and height are given', () => {
    const contentItem = imageContentItem({
      width: 100,
      height: 200
    })

    it('sets the width and height', () => {
      expect(contentItem.toHtmlString()).toEqual(
        '<img src="https://www.test.com/image" alt="some text" width="100" height="200">'
      )
    })
  })

  describe('when a thumnail is provided', () => {
    const contentItem = imageContentItem({
      thumbnail: 'http://www.test.com/thumbnail',
      width: 100,
      height: 200
    })

    it('creates a link to the image using the thumbnail', () => {
      expect(contentItem.toHtmlString()).toEqual(
        '<a href="https://www.test.com/image" title="Title"><img src="http://www.test.com/thumbnail" alt="some text"></a>'
      )
    })
  })
})