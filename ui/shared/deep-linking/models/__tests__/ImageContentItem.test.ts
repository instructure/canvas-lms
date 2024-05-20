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

import {
  imageContentItem,
  imageContentItemToHtmlString,
  type ImageContentItem,
} from '../ImageContentItem'

const json = imageContentItem({
  url: 'https://www.test.com/image',
  title: 'Title',
  text: 'some text',
})

const overrideImageContentItem = (overrides: Partial<ImageContentItem>) => ({
  ...json,
  ...overrides,
})

describe('toHtmlString', () => {
  it('creates an image tag', () => {
    expect(imageContentItemToHtmlString(json)).toEqual(
      '<img src="https://www.test.com/image" alt="some text">'
    )
  })

  describe('when width and height are given', () => {
    const contentItem = overrideImageContentItem({
      width: 100,
      height: 200,
    })

    it('sets the width and height', () => {
      expect(imageContentItemToHtmlString(contentItem)).toEqual(
        '<img src="https://www.test.com/image" alt="some text" width="100" height="200">'
      )
    })
  })

  describe('when a thumbnail is provided', () => {
    const contentItem = overrideImageContentItem({
      thumbnail: 'http://www.test.com/thumbnail',
      width: 100,
      height: 200,
    })

    it('creates a link to the image using the thumbnail', () => {
      expect(imageContentItemToHtmlString(contentItem)).toEqual(
        '<a href="https://www.test.com/image" title="Title" target="_blank"><img src="http://www.test.com/thumbnail" alt="some text"></a>'
      )
    })
  })
})
