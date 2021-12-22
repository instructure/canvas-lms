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
import {fireEvent, render} from '@testing-library/react'
import {ImageSection} from '../ImageSection'
import fetchMock from 'fetch-mock'

jest.mock('../../../../../shared/StoreContext', () => {
  return {
    useStoreProps: () => ({
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
              uuid: 'E6uaQSJaQYl95XaVMnoqYU7bOlt0WepMsTB9MJ8b'
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
              uuid: '9zLFcMIFlNPVtkTHulDGRS1bhiBg8hsL0ms6VeMt'
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
              uuid: 'rIlrdxCJ1h5Ff18Y4C6KJf7HIvCDn5ZAbtnVpNcw'
            }
          ],
          bookmark: 'bookmark',
          isLoading: false,
          hasMore: false
        }
      },
      contextType: 'Course',
      fetchInitialImages: jest.fn(),
      fetchNextImages: jest.fn()
    })
  }
})

describe('ImageSection', () => {
  const defaultProps = {
    settings: {},
    editing: false,
    editor: {},
    onChange: jest.fn()
  }

  const subject = overrides => render(<ImageSection {...{...defaultProps, ...overrides}} />)

  afterEach(() => jest.clearAllMocks())

  it('renders the image mode selector', () => {
    const {getByText} = subject()
    expect(getByText('Add Image')).toBeInTheDocument()
  })

  it('renders the image preview', () => {
    const {getByTestId} = subject()
    expect(getByTestId('selected-image-preview')).toBeInTheDocument()
  })

  describe('when no image is selected', () => {
    it('renders a "None Selected" message', () => {
      const {getByText} = subject()
      expect(getByText('None Selected')).toBeInTheDocument()
    })
  })

  describe('when the "course images" mode is selected', () => {
    let getByTestId, getByText, getByTitle

    beforeEach(() => {
      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText
      getByTitle = rendered.getByTitle

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Course Images'))
    })

    it('renders the course images component', () => {
      expect(getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
    })

    describe('and an image is clicked', () => {
      const flushPromises = () => new Promise(setImmediate)

      beforeEach(() => {
        fetchMock.mock('http://canvas.docker/files/722/download?download_frd=1', {})

        Object.defineProperty(global, 'FileReader', {
          writable: true,
          value: jest.fn().mockImplementation(() => ({
            readAsDataURL: function () {
              this.onloadend()
            },
            result: 'data:image/png;base64,asdfasdfjksdf=='
          }))
        })

        // Click the first image
        fireEvent.click(getByTitle('Click to embed image_one.png'))
      })

      afterEach(() => {
        fetchMock.restore('http://canvas.docker/files/722/download?download_frd=1')
      })

      it('sets the image name', () => {
        expect(getByText('grid.png')).toBeInTheDocument()
      })

      it('updates the image preview', async () => {
        await flushPromises()
        expect(getByTestId('selected-image-preview')).toHaveStyle(
          'backgroundImage: url(data:image/png;base64,asdfasdfjksdf==)'
        )
      })

      it('dispatches an action to update parent state image', async () => {
        await flushPromises()
        expect(defaultProps.onChange).toHaveBeenCalledWith({
          type: 'SetEncodedImage',
          payload: 'data:image/png;base64,asdfasdfjksdf=='
        })
      })

      it('dispatches an action to update parent state image type', async () => {
        await flushPromises()
        expect(defaultProps.onChange).toHaveBeenCalledWith({
          type: 'SetEncodedImageType',
          payload: 'Course'
        })
      })

      it('dispatches an action to update parent state image name', async () => {
        await flushPromises()
        expect(defaultProps.onChange).toHaveBeenCalledWith({
          type: 'SetEncodedImageName',
          payload: 'grid.png'
        })
      })
    })
  })

  describe('when editing mode', () => {
    it('sets the image name', async () => {
      const {getByText, rerender} = subject({editing: true})
      rerender(
        <ImageSection
          {...{
            ...defaultProps,
            ...{
              settings: {
                encodedImage: 'data:image/jpg;base64,asdfasdfjksdf==',
                encodedImageType: 'Course',
                encodedImageName: 'banana.jpg'
              },
              editing: true
            }
          }}
        />
      )
      expect(getByText('banana.jpg')).toBeInTheDocument()
    })

    it('sets the image preview', async () => {
      const {getByTestId, rerender} = subject({editing: true})
      rerender(
        <ImageSection
          {...{
            ...defaultProps,
            ...{
              settings: {
                encodedImage: 'data:image/jpg;base64,asdfasdfjksdf==',
                encodedImageType: 'Course',
                encodedImageName: 'banana.jpg'
              },
              editing: true
            }
          }}
        />
      )
      expect(getByTestId('selected-image-preview')).toHaveStyle(
        'backgroundImage: url(data:image/jpg;base64,asdfasdfjksdf==)'
      )
    })
  })
})
