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

import {formatFileSize, getFileThumbnail} from '../fileHelper'

describe('formatFileSize', () => {
  const testCases = [
    {size: 0, expectation: '0 B'},
    {size: 1000, expectation: '1000 B'},
    {size: 2048, expectation: '2 KB'},
    {size: 2560, expectation: '2.5 KB'},
    {size: 1048576, expectation: '1 MB'},
    {size: 3407872, expectation: '3.25 MB'},
    {size: 1073742000, expectation: '1 GB'},
  ]

  it('formats and returns file sizes as expected', () => {
    testCases.forEach(test => {
      expect(formatFileSize(test.size)).toEqual(test.expectation)
    })
  })
})

describe('getFileThumbnail', () => {
  const testCases = [
    {
      file: {
        mime_class: 'image',
        display_name: 'super_dank_image.png',
        thumbnail_url: 'http://dank_images.com/super_dank_image',
      },
      expectation: {
        type: 'img',
        size: '3rem',
      },
    },
    {
      file: {
        mime_class: 'image',
        display_name: 'super_dank_image.png',
        thumbnail_url: 'http://dank_images.com/super_dank_image',
      },
      size: 'x-small',
      expectation: {
        type: 'img',
        size: '1.125rem',
      },
    },
    {
      file: {mime_class: 'pdf'},
      expectation: {
        type: 'pdf',
        size: 'medium',
      },
    },
    {
      file: {mime_class: 'audio'},
      size: 'large',
      expectation: {
        type: 'attach-media',
        size: 'large',
      },
    },
    {
      file: {mime_class: 'text'},
      size: 'x-large',
      expectation: {
        type: 'document',
        size: 'x-large',
      },
    },
    // This is to account for both file objects obtained through graphql and
    // through the files API.
    {
      file: {
        mimeClass: 'image',
        displayName: 'neat_image.png',
        thumbnailUrl: 'http://neat_images.com/neat_image',
      },
      expectation: {
        type: 'img',
        size: '3rem',
      },
    },
  ]

  it('returns the appropriate element', () => {
    testCases.forEach(test => {
      const icon = getFileThumbnail(test.file, test.size)
      if (test.expectation.type === 'img') {
        expect(icon.type).toEqual(test.expectation.type)
        expect(icon.props.style.height).toEqual(test.expectation.size)
        expect(icon.props.style.width).toEqual(test.expectation.size)
      } else {
        expect(icon.type.glyphName).toEqual(test.expectation.type)
        expect(icon.props.size).toEqual(test.expectation.size)
      }
    })
  })
})
