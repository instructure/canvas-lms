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
import {act, render, waitFor} from '@testing-library/react'
import {ImageSection} from '../ImageSection'
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

  describe('when changing shape', () => {
    let overrides

    beforeEach(() => {
      overrides = {
        settings: {
          shape: 'square',
          size: Size.Small,
          imageSettings: {
            mode: '',
            image: '',
            imageName: '',
            icon: '',
            iconFillColor: '#000000',
            cropperSettings: {
              shape: 'square',
              rotation: 0,
              scaleRatio: 1.0,
              translateX: 0,
              translateY: 0,
            },
          },
        },
        editing: false,
        editor: {},
        onChange: jest.fn(),
      }
    })

    it('updates cropper settings if has a value', async () => {
      const {rerender} = subject(overrides)

      overrides.settings.shape = 'circle'
      rerender(<ImageSection {...{...defaultProps, ...overrides}} />)
      await waitFor(() => {
        expect(overrides.onChange).toHaveBeenCalledWith({
          type: 'SetImageSettings',
          payload: {
            mode: '',
            image: '',
            imageName: '',
            icon: '',
            iconFillColor: '#000000',
            cropperSettings: {
              shape: 'circle',
              rotation: 0,
              scaleRatio: 1.0,
              translateX: 0,
              translateY: 0,
            },
          },
        })
      })
    })

    it('updates embed image', async () => {
      const {rerender} = subject(overrides)

      overrides.settings.shape = 'circle'
      rerender(<ImageSection {...{...defaultProps, ...overrides}} />)

      await waitFor(() => {
        expect(overrides.onChange).toHaveBeenCalledWith({
          type: 'SetEmbedImage',
          payload: 'data:image/png;base64,CROPPED',
        })
      })
    })

    describe('if cropper settings is null', () => {
      beforeEach(() => {
        overrides = {
          settings: {
            shape: 'square',
            size: Size.Small,
            imageSettings: {
              mode: '',
              image: '',
              imageName: '',
              icon: '',
              iconFillColor: '#000000',
              cropperSettings: null,
            },
          },
          editing: false,
          editor: {},
          onChange: jest.fn(),
        }
        const {rerender} = subject(overrides)

        overrides.settings.shape = 'circle'
        rerender(<ImageSection {...{...defaultProps, ...overrides}} />)
      })

      it('does not update cropper settings', async () => {
        await waitFor(() => {
          expect(overrides.onChange).not.toHaveBeenCalledWith({
            type: 'SetImageSettings',
            payload: {
              shape: 'circle',
              rotation: 0,
              scaleRatio: 1.0,
              translateX: 0,
              translateY: 0,
            },
          })
        })
      })

      it('does not update embed image', async () => {
        await waitFor(() => {
          expect(overrides.onChange).not.toHaveBeenCalledWith({
            type: 'SetEmbedImage',
            payload: 'data:image/png;base64,CROPPED',
          })
        })
      })
    })

    describe('if cropper settings has already the same shape', () => {
      beforeEach(() => {
        const {rerender} = subject(overrides)
        overrides.settings.shape = 'square'
        rerender(<ImageSection {...{...defaultProps, ...overrides}} />)
      })

      it('does not update cropper settings', async () => {
        await waitFor(() => {
          expect(overrides.onChange).not.toHaveBeenCalledWith({
            type: 'SetImageSettings',
            payload: {
              shape: 'square',
              rotation: 0,
              scaleRatio: 1.0,
              translateX: 0,
              translateY: 0,
            },
          })
        })
      })

      it('does not update embed image', async () => {
        await waitFor(() => {
          expect(overrides.onChange).not.toHaveBeenCalledWith({
            type: 'SetEmbedImage',
            payload: 'data:image/png;base64,CROPPED',
          })
        })
      })
    })
  })

  describe('when no image is selected', () => {
    it('renders a "None Selected" message', () => {
      const {getByText} = subject()
      expect(getByText('None Selected')).toBeInTheDocument()
    })
  })
})
