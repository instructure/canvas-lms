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
import fetchMock from 'fetch-mock'

import {render, fireEvent, waitFor} from '@testing-library/react'
import Course from '../Course'
import {actions} from '../../../../reducers/imageSection'
import {useStoreProps} from '../../../../../shared/StoreContext'
import {compressImage, shouldCompressImage} from '../../../../../shared/compressionUtils'
import {isAnUnsupportedGifPngImage} from '../utils'

const storeProps = {
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

jest.mock('../../../../../shared/StoreContext', () => {
  return {
    useStoreProps: jest.fn(),
  }
})

jest.mock('../../../../../shared/compressionUtils', () => ({
  shouldCompressImage: jest.fn().mockReturnValue(false),
  compressImage: jest.fn().mockReturnValue(Promise.resolve('data:image/jpeg;base64,abcdefghijk==')),
  canCompressImage: jest.fn().mockReturnValue(true),
}))

jest.mock('../utils', () => ({
  ...jest.requireActual('../utils'),
  isAnUnsupportedGifPngImage: jest.fn().mockReturnValue(false),
}))

describe('Course()', () => {
  let props
  const subject = (customProps = {}) => render(<Course {...props} {...customProps} />)

  beforeEach(() => {
    useStoreProps.mockReturnValue(storeProps)
    props = {
      dispatch: jest.fn(),
      onChange: jest.fn(),
      canvasOrigin: 'https://canvas.instructor.com',
    }
  })

  afterEach(() => jest.clearAllMocks())

  it('renders the image list', () => {
    const {getByTitle} = subject()

    expect(getByTitle('Click to embed image_one.png')).toBeInTheDocument()
    expect(getByTitle('Click to embed image_two.jpg')).toBeInTheDocument()
    expect(getByTitle('Click to embed image_three.jpg')).toBeInTheDocument()
  })

  describe('when an image is clicked', () => {
    beforeEach(() => {
      const image = new Blob(['somedata'], {type: 'image/png'})
      fetchMock.mock('http://canvas.docker/files/722/download?download_frd=1', {
        body: image,
        sendAsJson: false,
      })

      jest.spyOn(global, 'FileReader').mockImplementation(function () {
        this.readAsDataURL = () => {
          this.result = 'data:text/png;base64,SGVsbG8sIFdvcmxkIQ=='
          this.onloadend()
        }
      })

      const {getByTitle} = subject()

      // Click the first image
      fireEvent.click(getByTitle('Click to embed image_one.png'))
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('dispatches a "stop loading" action', () => {
      expect(props.dispatch.mock.calls[0][0]).toEqual({
        type: 'StopLoading',
      })
    })

    it('dispatches a "set image name" action', () => {
      expect(props.dispatch.mock.calls[1][0]).toEqual({
        type: 'SetImageName',
        payload: 'grid.png',
      })
    })

    it('dispatches a "loading" action', () => {
      expect(props.dispatch.mock.calls[2][0]).toEqual({
        type: 'StartLoading',
      })
    })

    it('dispatches a "set image" action', async () => {
      await waitFor(() => {
        expect(props.dispatch).toHaveBeenCalledWith({
          type: 'SetImage',
          payload: 'data:text/png;base64,SGVsbG8sIFdvcmxkIQ==',
        })
      })
    })

    it('dispatches a "open cropper" action', async () => {
      await waitFor(() => {
        expect(props.dispatch).toHaveBeenCalledWith({
          type: 'SetCropperOpen',
          payload: true,
        })
      })
    })

    it('dispatches a "set embed image" action', async () => {
      await waitFor(() => {
        expect(props.onChange).toHaveBeenCalledWith({
          type: 'SetEmbedImage',
          payload: 'data:text/png;base64,SGVsbG8sIFdvcmxkIQ==',
        })
      })
    })

    it('dispatches a "set image collection open" action', async () => {
      await waitFor(() =>
        expect(props.dispatch).toHaveBeenCalledWith({
          ...actions.SET_IMAGE_COLLECTION_OPEN,
          payload: false,
        })
      )
    })

    describe('and is unsupported', () => {
      beforeAll(() => {
        isAnUnsupportedGifPngImage.mockReturnValue(true)
      })

      afterAll(() => {
        isAnUnsupportedGifPngImage.mockReturnValue(false)
      })

      it('dispatches a "clear image" action', async () => {
        await waitFor(() => {
          expect(props.dispatch).toHaveBeenCalledWith({
            type: 'ClearImage',
          })
        })
      })

      it('invokes onChange action "set error"', async () => {
        await waitFor(() => {
          expect(props.onChange).toHaveBeenCalledWith({
            type: 'SetError',
            payload: 'GIF/PNG format images larger than 250 KB are not currently supported.',
          })
        })
      })
    })
  })

  describe('when a image to be compressed is clicked', () => {
    let originalResponse

    beforeAll(() => {
      const image = new Blob(['somedata'], {type: 'image/jpeg', size: 600000})
      fetchMock.mock('http://canvas.docker/files/722/download?download_frd=1', {
        body: image,
        sendAsJson: false,
      })

      jest.spyOn(global, 'FileReader').mockImplementation(function () {
        this.readAsDataURL = () => {
          this.result = 'data:image/jpeg;base64,SGVsbG8sIFdvcmxkIQ=='
          this.onloadend()
        }
      })

      originalResponse = global.Response
      global.Response = function () {
        this.blob = () => {
          return Promise.resolve('XXXXXXXX')
        }
      }
      shouldCompressImage.mockReturnValue(true)
    })

    beforeEach(() => {
      const {getByTitle} = subject()

      // Click the first image
      fireEvent.click(getByTitle('Click to embed image_one.png'))
    })

    afterAll(() => {
      fetchMock.restore()
      global.Response = originalResponse
    })

    it('dispatches a "stop loading" action', () => {
      expect(props.dispatch.mock.calls[0][0]).toEqual({
        type: 'StopLoading',
      })
    })

    it('dispatches a "set image name" action', () => {
      expect(props.dispatch.mock.calls[1][0]).toEqual({
        type: 'SetImageName',
        payload: 'grid.png',
      })
    })

    it('dispatches a "loading" action', () => {
      expect(props.dispatch.mock.calls[2][0]).toEqual({
        type: 'StartLoading',
      })
    })

    it('compressImage() was called', async () => {
      await waitFor(() => {
        expect(compressImage).toHaveBeenCalledWith({
          encodedImage: 'data:image/jpeg;base64,SGVsbG8sIFdvcmxkIQ==',
          previewHeight: 350,
          previewWidth: 942,
        })
      })
    })

    it('dispatches a "set compression status" action', async () => {
      await waitFor(() => {
        expect(props.dispatch).toHaveBeenCalledWith({
          type: 'SetCompressionStatus',
          payload: true,
        })
      })
    })

    it('dispatches a "set image" action', async () => {
      await waitFor(() => {
        expect(props.dispatch).toHaveBeenCalledWith({
          type: 'SetImage',
          payload: 'data:image/jpeg;base64,abcdefghijk==',
        })
      })
    })

    it('dispatches a "open cropper" action', async () => {
      await waitFor(() => {
        expect(props.dispatch).toHaveBeenCalledWith({
          type: 'SetCropperOpen',
          payload: true,
        })
      })
    })

    it('dispatches a "set embed image" action', async () => {
      await waitFor(() => {
        expect(props.onChange).toHaveBeenCalledWith({
          type: 'SetEmbedImage',
          payload: 'data:image/jpeg;base64,abcdefghijk==',
        })
      })
    })

    it('dispatches a "set image collection open" action', async () => {
      await waitFor(() =>
        expect(props.dispatch).toHaveBeenCalledWith({
          ...actions.SET_IMAGE_COLLECTION_OPEN,
          payload: false,
        })
      )
    })
  })

  describe('when loading state changes', () => {
    it('calls "onLoading"', () => {
      const onLoading = jest.fn()
      const loadingStoreProps = {
        ...storeProps,
        images: JSON.parse(JSON.stringify(storeProps.images)),
      }
      loadingStoreProps.images.Course.isLoading = true
      useStoreProps.mockReturnValue(loadingStoreProps)
      subject({onLoading})
      expect(onLoading).toHaveBeenCalled()
    })

    it('calls "onLoaded"', () => {
      const onLoaded = jest.fn()
      subject({onLoaded})
      expect(onLoaded).toHaveBeenCalled()
    })
  })
})
