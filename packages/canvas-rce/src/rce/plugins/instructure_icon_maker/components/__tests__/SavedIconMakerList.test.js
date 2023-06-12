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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import SavedIconMakerList from '../SavedIconMakerList'

const flushPromises = () => new Promise(setTimeout)

let mockContent = {
  images: {
    Course: {
      files: [
        {
          id: 722,
          filename: 'grid.png',
          thumbnail_url:
            'http://canvas.docker/images/thumbnails/722/E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b',
          display_name: 'image_one.png',
          href: 'http://canvas.docker/courses/21/files/722?wrap=1',
          download_url: 'http://canvas.docker/files/722/download?download_frd=1',
          content_type: 'image/png',
          published: true,
          hidden_to_user: true,
          locked_for_user: false,
          unlock_at: null,
          lock_at: null,
          date: '2021-11-03T19:21:27Z',
          uuid: 'E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b',
        },
        {
          id: 716,
          filename: '1635371359_565__0266554465.jpeg',
          thumbnail_url:
            'http://canvas.docker/images/thumbnails/716/9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt',
          display_name: 'image_two.jpg',
          href: 'http://canvas.docker/courses/21/files/716?wrap=1',
          download_url: 'http://canvas.docker/files/716/download?download_frd=1',
          content_type: 'image/jpeg',
          published: true,
          hidden_to_user: false,
          locked_for_user: false,
          unlock_at: null,
          lock_at: null,
          date: '2021-10-27T21:49:19Z',
          uuid: '9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt',
        },
        {
          id: 715,
          filename: '1635371358_548__h3zmqPb-6dw.jpg',
          thumbnail_url:
            'http://canvas.docker/images/thumbnails/715/rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw',
          display_name: 'image_three.jpg',
          href: 'http://canvas.docker/courses/21/files/715?wrap=1',
          download_url: 'http://canvas.docker/files/715/download?download_frd=1',
          content_type: 'image/jpeg',
          published: true,
          hidden_to_user: false,
          locked_for_user: false,
          unlock_at: null,
          lock_at: null,
          date: '2021-10-27T21:49:18Z',
          uuid: 'rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw',
        },
      ],
      bookmark: 'bookmark',
      isLoading: false,
      hasMore: false,
    },
  },
  contextType: 'Course',
  fetchInitialImages: jest.fn(),
  fetchNextImages: jest.fn(),
}
jest.mock('../../../shared/StoreContext', () => {
  return {
    useStoreProps: () => mockContent,
  }
})
describe('SavedIconMakerList()', () => {
  let props
  const subject = () => render(<SavedIconMakerList {...props} />)

  beforeEach(() => {
    props = {
      onImageEmbed: jest.fn(),
      sortBy: {sort: 'alphabetical', order: 'asc'},
      searchString: '',
      canvasOrigin: 'https://canvas.instructor.com',
      ...mockContent,
    }
  })

  afterEach(() => jest.clearAllMocks())

  it('renders the image list', () => {
    const {getByTitle} = subject()

    expect(getByTitle('Click to embed image_one.png')).toBeInTheDocument()
    expect(getByTitle('Click to embed image_two.jpg')).toBeInTheDocument()
    expect(getByTitle('Click to embed image_three.jpg')).toBeInTheDocument()
  })

  describe('fetch icons when', () => {
    it('sort dropdown changes its value', async () => {
      const {rerender} = subject()
      expect(mockContent.fetchInitialImages).toHaveBeenCalledTimes(1)
      rerender(
        <SavedIconMakerList
          {...props}
          sortBy={{
            sort: 'date_added',
            order: 'desc',
          }}
        />
      )
      await flushPromises()
      expect(mockContent.fetchInitialImages).toHaveBeenCalledTimes(2)
    })

    it('search text changes its value', async () => {
      const {rerender} = subject()
      expect(mockContent.fetchInitialImages).toHaveBeenCalledTimes(1)
      rerender(<SavedIconMakerList {...props} searchString="grid" />)
      await flushPromises()
      expect(mockContent.fetchInitialImages).toHaveBeenCalledTimes(2)
    })
  })

  describe('when an image is clicked', () => {
    beforeEach(() => {
      const {getByTitle} = subject()

      // Click the first image
      fireEvent.click(getByTitle('Click to embed image_one.png'))
    })

    it('dispatches a "loading" action', () => {
      expect(props.onImageEmbed.mock.calls[0][0]).toMatchInlineSnapshot(`
        Object {
          "content_type": "image/png",
          "date": "2021-11-03T19:21:27Z",
          "display_name": "image_one.png",
          "download_url": "http://canvas.docker/files/722/download?download_frd=1",
          "filename": "grid.png",
          "hidden_to_user": true,
          "href": "http://canvas.docker/courses/21/files/722?wrap=1",
          "id": 722,
          "lock_at": null,
          "locked_for_user": false,
          "published": true,
          "thumbnail_url": "http://canvas.docker/images/thumbnails/722/E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b",
          "unlock_at": null,
          "uuid": "E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b",
        }
      `)
    })
  })
  describe('When no course icons', () => {
    beforeAll(() => {
      mockContent = {
        images: {
          Course: {
            files: [],
            bookmark: 'bookmark',
            isLoading: false,
            hasMore: false,
          },
        },
        contextType: 'Course',
        fetchInitialImages: jest.fn(),
        fetchNextImages: jest.fn(),
      }
    })
    it('displays No results message', () => {
      const {getByText} = subject()
      expect(getByText('No results.')).toBeInTheDocument()
    })
  })
})
