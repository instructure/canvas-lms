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
import {act, fireEvent, render, waitFor} from '@testing-library/react'
import {ImageSection} from '../ImageSection'
import fetchMock from 'fetch-mock'
import FakeEditor from '../../../../../../__tests__/FakeEditor'
import {Size} from '../../../../svg/constants'
import {convertFileToBase64} from '../../../../../shared/fileUtils'

jest.useFakeTimers()
jest.mock('../../../../../shared/StoreContext', () => {
  return {
    ...jest.requireActual('../../../../../shared/StoreContext'),
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
    }),
  }
})

jest.mock('../../../../../../../bridge', () => {
  return {
    trayProps: {
      get: () => ({foo: 'bar'}),
    },
  }
})

jest.mock('../../../../../shared/ImageCropper/imageCropUtils', () => {
  return {
    createCroppedImageSvg: () =>
      Promise.resolve({
        outerHTML: '<svg />',
      }),
  }
})

jest.mock('../../../../../shared/fileUtils')

describe('ImageSection', () => {
  let scrollIntoView
  const defaultProps = {
    settings: {
      embedImage: 'data:image/png;base64,EMBED_IMAGE',
      size: Size.Small,
    },
    editing: false,
    editor: {},
    onChange: jest.fn(),
    canvasOrigin: 'https://canvas.instructor.com',
  }

  const subject = overrides => render(<ImageSection {...{...defaultProps, ...overrides}} />)

  beforeEach(() => {
    scrollIntoView = jest.fn()
    window.HTMLElement.prototype.scrollIntoView = scrollIntoView
    convertFileToBase64.mockImplementation(() => Promise.resolve('data:image/png;base64,CROPPED'))
  })

  afterEach(async () => {
    await act(async () => {
      jest.runOnlyPendingTimers()
    })
    jest.clearAllMocks()
  })

  describe('calls onChange passing metadata when state prop changes', () => {
    let getByTestId, getByText, getByTitle, container

    const lastPayloadOfActionType = (mockFn, type) =>
      mockFn.mock.calls.reverse().find(call => call[0].type === type)[0].payload

    beforeEach(() => {
      const rendered = subject({
        settings: {size: Size.Small, shape: 'square'},
      })

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText
      getByTitle = rendered.getByTitle
      container = rendered.container
    })

    describe('using course images', () => {
      let originalFileReader

      beforeAll(() => {
        fetchMock.mock('http://canvas.docker/files/722/download?download_frd=1', {})
        originalFileReader = FileReader
        Object.defineProperty(global, 'FileReader', {
          writable: true,
          value: jest.fn().mockImplementation(() => ({
            set onload(value) {
              // Used when FileReader for converting to Blob
              value()
            },
            readAsDataURL() {
              // Used to fetch url
              this.onloadend && this.onloadend()
            },
            result: 'data:image/png;base64,asdfasdfjksdf==',
          })),
        })
      })

      afterAll(() => {
        fetchMock.restore('http://canvas.docker/files/722/download?download_frd=1')
        Object.defineProperty(global, 'FileReader', {
          writable: true,
          value: originalFileReader,
        })
      })

      it('when select mode', async () => {
        fireEvent.click(getByText('Add Image'))
        fireEvent.click(getByText('Course Images'))
        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        const payload = lastPayloadOfActionType(defaultProps.onChange, 'SetImageSettings')
        expect(payload.mode).toEqual('Course')
      })

      it('when select image', async () => {
        fireEvent.click(getByText('Add Image'))
        fireEvent.click(getByText('Course Images'))
        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        fireEvent.click(getByTitle('Click to embed image_one.png'))
        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        const payload = lastPayloadOfActionType(defaultProps.onChange, 'SetImageSettings')
        expect(payload.image).toEqual('data:image/png;base64,asdfasdfjksdf==')
        expect(payload.imageName).toEqual('grid.png')
      })

      it('when crop image ', async () => {
        fireEvent.click(getByText('Add Image'))
        fireEvent.click(getByText('Course Images'))
        fireEvent.click(getByTitle('Click to embed image_one.png'))
        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        // Zooms in just to change cropper settings
        fireEvent.click(getByTestId('zoom-in-button'))
        await waitFor(() =>
          expect(document.querySelector('[data-cid="Modal"] [type="submit"]')).toBeInTheDocument(),
        )
        fireEvent.click(document.querySelector('[data-cid="Modal"] [type="submit"]'))
        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        const payload = lastPayloadOfActionType(defaultProps.onChange, 'SetImageSettings')
        expect(payload.cropperSettings).toEqual({
          shape: 'square',
          rotation: 0,
          scaleRatio: 1.1,
          translateX: 0,
          translateY: 0,
        })
      })
    })

    it('when select multi color images', async () => {
      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Multi Color Image'))
      await waitFor(() => expect(getByTestId('multicolor-svg-list')).toBeInTheDocument())
      fireEvent.click(getByTestId('icon-maker-art'))
      await act(async () => {
        jest.runOnlyPendingTimers()
      })
      const payload = lastPayloadOfActionType(defaultProps.onChange, 'SetImageSettings')
      expect(payload.imageName).toEqual('Art Icon')
    })

    it('when select single color images', async () => {
      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Single Color Image'))
      await waitFor(() => expect(getByTestId('singlecolor-svg-list')).toBeInTheDocument())
      fireEvent.click(getByTestId('icon-maker-art'))
      await act(async () => {
        jest.runOnlyPendingTimers()
      })
      await waitFor(() => {
        expect(container.querySelector('[name="single-color-image-fill"]')).toBeInTheDocument()
      })
      fireEvent.change(container.querySelector('[name="single-color-image-fill"]'), {
        target: {value: '#00FF00'},
      })
      await act(async () => {
        jest.runOnlyPendingTimers()
      })
      const payload = lastPayloadOfActionType(defaultProps.onChange, 'SetImageSettings')
      expect(payload.iconFillColor).toEqual('#00FF00')
    })
  })

  describe('when the "upload image" mode is selected', () => {
    let rendered

    beforeEach(async () => {
      fetchMock.mock('/api/session', '{}')

      await act(async () => {
        rendered = subject({
          editor: new FakeEditor(),
        })
      })

      fireEvent.click(rendered.getByText('Add Image'))
      fireEvent.click(rendered.getByText('Upload Image'))
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('renders the image upload modal', async () => {
      await waitFor(() => {
        const uploadImages = rendered.getAllByText('Upload Image')
        expect(uploadImages.length).toBeGreaterThan(0)
        expect(uploadImages[0]).toBeInTheDocument()
      })
    })

    describe('and the the "close" button is clicked', () => {
      beforeEach(async () => {
        const button = await rendered.findAllByText(/Close/i)
        fireEvent.click(button[0])
      })

      it('closes the modal', () => {
        expect(rendered.queryByText('Upload Image')).toBe(null)
      })
    })
  })

  describe('when the "course images" mode is selected', () => {
    let getByTestId, getByText

    beforeEach(() => {
      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Course Images'))
    })

    it('renders the course images component', () => {
      expect(getByTestId('instructure_links-ImagesPanel')).toBeInTheDocument()
    })

    it('scrolls the component into view smoothly 😎', async () => {
      await waitFor(() => expect(scrollIntoView).toHaveBeenCalledWith({behavior: 'smooth'}))
    })
  })

  describe('when the "Multi Color Image" mode is selected', () => {
    let getByTestId, getByText

    beforeEach(() => {
      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Multi Color Image'))
    })

    it('renders the course images component', async () => {
      await waitFor(() => expect(getByTestId('multicolor-svg-list')).toBeInTheDocument())
    })

    it('scrolls the component into view smoothly 😎', async () => {
      await waitFor(() => expect(scrollIntoView).toHaveBeenCalledWith({behavior: 'smooth'}))
    })
  })
})
