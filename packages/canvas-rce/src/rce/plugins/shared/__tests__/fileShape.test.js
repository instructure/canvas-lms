/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {contentTrayDocumentShape} from '../fileShape'

describe('fileShape', () => {
  it('validates valid documents', () => {
    expect(
      contentTrayDocumentShape(
        {
          documents: {
            user: {
              bookmark: null,
              hasMore: false,
              isLoading: false,
              files: [
                {
                  id: 1,
                  filename: 'foo.pdf',
                  href: 'http://example.com/foo.pdf',
                  content_type: 'application/pdf',
                  display_name: 'foo.pdf',
                  date: '2019-01-01T00:00:00Z',
                },
              ],
            },
            searchString: '',
          },
        },
        'documents',
        'someComponent'
      )
    ).toBeUndefined()
  })

  it('validates images', () => {
    expect(
      contentTrayDocumentShape(
        {
          images: {
            user: {
              bookmark: null,
              hasMore: false,
              isLoading: false,
              files: [
                {
                  id: 1,
                  filename: 'foo.png',
                  href: 'http://example.com/foo.png',
                  content_type: 'image/png',
                  display_name: 'foo.png',
                  date: '2019-01-01T00:00:00Z',
                  thumbnail_url: 'http://example.com/foo.png',
                },
              ],
            },
            searchString: '',
          },
        },
        'images',
        'someComponent'
      )
    ).toBeUndefined()
  })

  it('validates media objects', () => {
    expect(
      contentTrayDocumentShape(
        {
          media: {
            user: {
              bookmark: null,
              hasMore: false,
              isLoading: false,
              files: [
                {
                  id: 1,
                  filename: 'foo.mp4',
                  href: 'http://example.com/foo.mp4',
                  content_type: 'video/mp4',
                  display_name: 'foo.mp4',
                  date: '2019-01-01T00:00:00Z',
                  thumbnail_url: 'http://example.com/foo.png',
                  title: 'foo',
                  embedded_iframe_url: 'http://example.com/foo.mp4',
                },
              ],
            },
            searchString: '',
          },
        },
        'media',
        'someComponent'
      )
    ).toBeUndefined()
  })

  it('rejects invalid files', () => {
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {})
    contentTrayDocumentShape(
      {
        documents: {
          user: {
            bookmark: null,
            hasMore: false,
            isLoading: false,
            files: [
              {
                id: 1,
                filename: 'foo.pdf',
                href: 'http://example.com/foo.pdf',
                content_type: undefined, // this is required
                display_name: 'foo.pdf',
                date: '2019-01-01T00:00:00Z',
              },
            ],
          },
          searchString: '',
        },
      },
      'documents',
      'someComponent'
    )

    expect(consoleError).toHaveBeenCalledWith(
      'Warning: Failed someComponent type: The someComponent `docs.files[0].content_type` is marked as required in `someComponent`, but its value is `undefined`.'
    )
  })

  it('expects searchString to be a string', () => {
    expect(
      contentTrayDocumentShape(
        {
          documents: {
            user: {
              bookmark: null,
              hasMore: false,
              isLoading: false,
              files: [
                {
                  id: 1,
                  filename: 'foo.pdf',
                  href: 'http://example.com/foo.pdf',
                  content_type: 'application/pdf',
                  display_name: 'foo.pdf',
                  date: '2019-01-01T00:00:00Z',
                },
              ],
            },
            searchString: 123,
          },
        },
        'documents',
        'someCompnent'
      )
    ).toMatchObject({
      message:
        'Invalid prop `documents` supplied to `someCompnent`. "searchString" must be a string.',
    })
  })

  it('can be optional', () => {
    expect(
      contentTrayDocumentShape(
        {
          documents: undefined,
        },
        'documents',
        'someComponent'
      )
    ).toBeUndefined()
  })

  it('can be required', () => {
    expect(
      contentTrayDocumentShape.isRequired(
        {
          documents: undefined,
        },
        'documents',
        'someComponent',
        true
      )
    ).toMatchObject({
      message: 'Required prop `documents` not supplied to `someComponent`. Validation failed.',
    })
  })
})
