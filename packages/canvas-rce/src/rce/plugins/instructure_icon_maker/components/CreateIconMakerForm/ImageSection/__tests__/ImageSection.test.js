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
import svg from '../SingleColor/svg'
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

  it('renders the image mode selector', () => {
    const {getByText} = subject()
    expect(getByText('Add Image')).toBeInTheDocument()
  })

  it('renders the image preview', () => {
    const {getByTestId} = subject()
    expect(getByTestId('selected-image-preview')).toBeInTheDocument()
  })

  it('sets default crop settings', () => {
    subject()

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetX',
      payload: '50%',
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetY',
      payload: '50%',
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetWidth',
      payload: 75,
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetHeight',
      payload: 75,
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetTranslateX',
      payload: -37.5,
    })

    expect(defaultProps.onChange).toHaveBeenCalledWith({
      type: 'SetTranslateY',
      payload: -37.5,
    })
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
          expect(document.querySelector('[data-cid="Modal"] [type="submit"]')).toBeInTheDocument()
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

    beforeEach(() => {
      fetchMock.mock('/api/session', '{}')

      rendered = subject({
        editor: new FakeEditor(),
      })

      fireEvent.click(rendered.getByText('Add Image'))
      fireEvent.click(rendered.getByText('Upload Image'))
    })

    afterEach(() => {
      fetchMock.restore()
    })

    it('renders the image upload modal', async () => {
      await waitFor(() => expect(rendered.getByText('Upload Image')).toBeInTheDocument())
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

  describe('when the "Single Color Image" mode is selected', () => {
    let spyFn, getByTestId, getByText, container, rerender

    beforeAll(() => {
      spyFn = jest.spyOn(svg.art, 'source')
      scrollIntoView = jest.fn()
    })

    beforeEach(() => {
      const rendered = subject()

      getByTestId = rendered.getByTestId
      getByText = rendered.getByText
      container = rendered.container
      rerender = rendered.rerender

      fireEvent.click(getByText('Add Image'))
      fireEvent.click(getByText('Single Color Image'))
    })

    afterEach(() => jest.clearAllMocks())

    it('renders the single color images component', async () => {
      await waitFor(() => expect(getByTestId('singlecolor-svg-list')).toBeInTheDocument())
    })

    it('scrolls the component into view smoothly 😎', async () => {
      await waitFor(() => expect(scrollIntoView).toHaveBeenCalledWith({behavior: 'smooth'}))
    })

    describe('user selects an image', () => {
      beforeEach(async () => {
        await waitFor(() => {
          expect(getByTestId('selected-image-preview')).toBeInTheDocument()
        })
        fireEvent.click(getByTestId('icon-maker-art'))
        convertFileToBase64.mockImplementation(
          jest.requireActual('../../../../../shared/fileUtils').convertFileToBase64
        )
      })

      it('sets default icon color', async () => {
        await waitFor(() => {
          expect(spyFn).toHaveBeenCalledWith('#000000')
          expect(getByTestId('selected-image-preview')).toHaveStyle(
            'backgroundImage: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgwIiBoZWlnaHQ9IjQ4MCIgdmlld0JveD0iMCAwIDQ4MCA0ODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgICAgIDxwYXRoIGQ9Ik0yNDAgMEMxMDcuNTUgMCAwIDEwNy41NSAwIDI0MEMwIDM3Mi41NTEgMTA3LjQ1NCA0ODAgMjQwIDQ4MEMyNDYuNDQ2IDQ4MCAyNTIuODMgNDc5Ljc0OSAyNTkuMTUyIDQ3OS4yNDhDMjg4LjU0NiA0NzYuOTI3IDMxMS4xNTggNDUyLjI3NSAzMTEuMTU4IDQyMi43OTJWMzU5LjgyQzMxMS4xNTggMzQ2LjkxNCAzMTYuMjg0IDMzNC41MzYgMzI1LjQxIDMyNS40MUMzMzQuNTM2IDMxNi4yODQgMzQ2LjkxNCAzMTEuMTU4IDM1OS44MiAzMTEuMTU4SDQyMy4zMTFDNDM3LjM5IDMxMS4xNjUgNDUwLjk1NiAzMDUuODc0IDQ2MS4zMTIgMjk2LjMzNkM0NzEuNjY4IDI4Ni43OTkgNDc4LjA1NiAyNzMuNzE0IDQ3OS4yMDUgMjU5LjY4MkM0NzkuNzM1IDI1My4xOTQgNDgwIDI0Ni42MzMgNDgwIDI0MEM0ODAgMTA3LjQ1NCAzNzIuNTUxIDAgMjQwIDBaTTkyLjYxNDYgMzA5LjAyOEM4NC43MzA2IDMxMC40OTQgNzYuNTg4OSAzMDkuNTg5IDY5LjIxOSAzMDYuNDI4QzYxLjg0OSAzMDMuMjY4IDU1LjU4MTYgMjk3Ljk5MyA1MS4yMDkyIDI5MS4yNzFDNDYuODM2NyAyODQuNTQ4IDQ0LjU1NTUgMjc2LjY4MSA0NC42NTQgMjY4LjY2MkM0NC43NTI0IDI2MC42NDQgNDcuMjI2MSAyNTIuODM0IDUxLjc2MjMgMjQ2LjIyMkM1Ni4yOTg1IDIzOS42MDkgNjIuNjkzNSAyMzQuNDg5IDcwLjEzODggMjMxLjUxMUM3Ny41ODQyIDIyOC41MzIgODUuNzQ1NSAyMjcuODI3IDkzLjU5MTIgMjI5LjQ4NkMxMDEuNDM3IDIzMS4xNDUgMTA4LjYxNCAyMzUuMDkzIDExNC4yMTcgMjQwLjgzMUMxMTkuODE5IDI0Ni41NjkgMTIzLjU5NCAyNTMuODM5IDEyNS4wNjUgMjYxLjcyMkMxMjYuMDQxIDI2Ni45NTkgMTI1Ljk3NyAyNzIuMzM3IDEyNC44NzQgMjc3LjU0OUMxMjMuNzcyIDI4Mi43NjEgMTIxLjY1MyAyODcuNzA0IDExOC42NCAyOTIuMDk3QzExNS42MjYgMjk2LjQ5IDExMS43NzcgMzAwLjI0NyAxMDcuMzExIDMwMy4xNTJDMTAyLjg0NiAzMDYuMDU3IDk3Ljg1MTkgMzA4LjA1MyA5Mi42MTQ2IDMwOS4wMjhaTTEwOS4xODcgMTI4LjAyNkMxMDcuNzE5IDEyMC4xNDIgMTA4LjYyMiAxMTEuOTk5IDExMS43ODIgMTA0LjYyN0MxMTQuOTQzIDk3LjI1NTUgMTIwLjIxOCA5MC45ODY2IDEyNi45NDEgODYuNjEzMkMxMzMuNjY0IDgyLjIzOTggMTQxLjUzMyA3OS45NTgyIDE0OS41NTIgODAuMDU3QzE1Ny41NzIgODAuMTU1OCAxNjUuMzgzIDgyLjYzMDYgMTcxLjk5NiA4Ny4xNjgzQzE3OC42MDkgOTEuNzA2MSAxODMuNzI4IDk4LjEwMyAxODYuNzA2IDEwNS41NUMxODkuNjgzIDExMi45OTcgMTkwLjM4NiAxMjEuMTYgMTg4LjcyNCAxMjkuMDA3QzE4Ny4wNjIgMTM2Ljg1MyAxODMuMTExIDE0NC4wMyAxNzcuMzcgMTQ5LjYzMUMxNzEuNjI5IDE1NS4yMzIgMTY0LjM1NyAxNTkuMDA0IDE1Ni40NzIgMTYwLjQ3MkMxNTEuMjM2IDE2MS40NDYgMTQ1Ljg2IDE2MS4zODEgMTQwLjY1MSAxNjAuMjc4QzEzNS40NDEgMTU5LjE3NSAxMzAuNSAxNTcuMDU2IDEyNi4xMDkgMTU0LjA0M0MxMjEuNzE4IDE1MS4wMyAxMTcuOTYzIDE0Ny4xODIgMTE1LjA2IDE0Mi43MThDMTEyLjE1NiAxMzguMjU0IDExMC4xNjEgMTMzLjI2MiAxMDkuMTg3IDEyOC4wMjZaTTIxNS43NzIgNDMyLjg0OEMyMDUuMjk0IDQzMi44NDggMTk1LjA1MSA0MjkuNzQgMTg2LjMzOCA0MjMuOTE5QzE3Ny42MjUgNDE4LjA5NyAxNzAuODM1IDQwOS44MjMgMTY2LjgyNSA0MDAuMTQyQzE2Mi44MTUgMzkwLjQ2MSAxNjEuNzY2IDM3OS44MDkgMTYzLjgxIDM2OS41MzJDMTY1Ljg1NCAzNTkuMjU0IDE3MC45IDM0OS44MTQgMTc4LjMxIDM0Mi40MDVDMTg1LjcxOSAzMzQuOTk2IDE5NS4xNTkgMzI5Ljk1IDIwNS40MzYgMzI3LjkwNUMyMTUuNzEzIDMyNS44NjEgMjI2LjM2NiAzMjYuOTEgMjM2LjA0NyAzMzAuOTJDMjQ1LjcyOCAzMzQuOTMgMjU0LjAwMiAzNDEuNzIxIDI1OS44MjQgMzUwLjQzM0MyNjUuNjQ1IDM1OS4xNDYgMjY4Ljc1MiAzNjkuMzg5IDI2OC43NTIgMzc5Ljg2OEMyNjguNzUyIDM5My45MTkgMjYzLjE3IDQwNy4zOTQgMjUzLjIzNSA0MTcuMzNDMjQzLjI5OSA0MjcuMjY2IDIyOS44MjMgNDMyLjg0OCAyMTUuNzcyIDQzMi44NDhaTTMxMy4xNjYgMTQ0LjI0NEMzMDUuMjgxIDE0NS43MSAyOTcuMTM4IDE0NC44MDYgMjg5Ljc2OCAxNDEuNjQ1QzI4Mi4zOTcgMTM4LjQ4NCAyNzYuMTI5IDEzMy4yMDkgMjcxLjc1NiAxMjYuNDg2QzI2Ny4zODQgMTE5Ljc2MyAyNjUuMTAzIDExMS44OTQgMjY1LjIwMiAxMDMuODc1QzI2NS4zMDEgOTUuODU1MyAyNjcuNzc2IDg4LjA0NTUgMjcyLjMxNCA4MS40MzI4QzI3Ni44NTIgNzQuODIgMjgzLjI0OCA2OS43MDEzIDI5MC42OTUgNjYuNzIzOEMyOTguMTQyIDYzLjc0NjMgMzA2LjMwNCA2My4wNDM4IDMxNC4xNSA2NC43MDUxQzMyMS45OTYgNjYuMzY2NCAzMjkuMTczIDcwLjMxNjkgMzM0Ljc3NCA3Ni4wNTdDMzQwLjM3NSA4MS43OTcyIDM0NC4xNDggODkuMDY5MiAzNDUuNjE2IDk2Ljk1MzZDMzQ3LjU4MyAxMDcuNTI4IDM0NS4yNyAxMTguNDUgMzM5LjE4NCAxMjcuMzE5QzMzMy4wOTkgMTM2LjE4OCAzMjMuNzQgMTQyLjI3NSAzMTMuMTY2IDE0NC4yNDRaTTQwNS45NiAyNjguNTU2QzM5OC4wNzUgMjcwLjAyNCAzODkuOTMyIDI2OS4xMjEgMzgyLjU2MSAyNjUuOTYxQzM3NS4xODkgMjYyLjgwMSAzNjguOTIgMjU3LjUyNSAzNjQuNTQ3IDI1MC44MDJDMzYwLjE3NCAyNDQuMDc5IDM1Ny44OTIgMjM2LjIxIDM1Ny45OTEgMjI4LjE5MUMzNTguMDkgMjIwLjE3MSAzNjAuNTY0IDIxMi4zNjEgMzY1LjEwMiAyMDUuNzQ3QzM2OS42NCAxOTkuMTM0IDM3Ni4wMzcgMTk0LjAxNSAzODMuNDg0IDE5MS4wMzdDMzkwLjkzMSAxODguMDYgMzk5LjA5NCAxODcuMzU3IDQwNi45NCAxODkuMDE5QzQxNC43ODcgMTkwLjY4MSA0MjEuOTY0IDE5NC42MzIgNDI3LjU2NSAyMDAuMzczQzQzMy4xNjUgMjA2LjExNCA0MzYuOTM4IDIxMy4zODcgNDM4LjQwNSAyMjEuMjcyQzQzOS4zOCAyMjYuNTA3IDQzOS4zMTQgMjMxLjg4MyA0MzguMjExIDIzNy4wOTJDNDM3LjEwOCAyNDIuMzAyIDQzNC45OSAyNDcuMjQzIDQzMS45NzcgMjUxLjYzNEM0MjguOTY0IDI1Ni4wMjUgNDI1LjExNiAyNTkuNzggNDIwLjY1MiAyNjIuNjgzQzQxNi4xODggMjY1LjU4NyA0MTEuMTk2IDI2Ny41ODIgNDA1Ljk2IDI2OC41NTZaIiBmaWxsPSIjMTExMTExIi8+CiAgICA8L3N2Zz4=))'
          )
        })
      })

      it('changes the icon color', async () => {
        await waitFor(() => {
          expect(container.querySelector('[name="single-color-image-fill"]')).toBeInTheDocument()
          fireEvent.change(container.querySelector('[name="single-color-image-fill"]'), {
            target: {value: '#00FF00'},
          })
        })
        await act(async () => {
          jest.runOnlyPendingTimers()
        })
        await waitFor(() => {
          expect(spyFn).toHaveBeenCalledWith('#00FF00')
          expect(defaultProps.onChange).toHaveBeenCalledWith({
            type: 'SetEmbedImage',
            payload:
              'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgwIiBoZWlnaHQ9IjQ4MCIgdmlld0JveD0iMCAwIDQ4MCA0ODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgICAgIDxwYXRoIGQ9Ik0yNDAgOTBDMTU3LjIxOSA5MCA5MCAxNTcuMjE5IDkwIDI0MEM5MCAzMjIuODQ0IDE1Ny4xNTkgMzkwIDI0MCAzOTBDMjQ0LjAyOSAzOTAgMjQ4LjAxOSAzODkuODQzIDI1MS45NyAzODkuNTNDMjcwLjM0MSAzODguMDc5IDI4NC40NzQgMzcyLjY3MiAyODQuNDc0IDM1NC4yNDVWMzE0Ljg4N0MyODQuNDc0IDMwNi44MjEgMjg3LjY3OCAyOTkuMDg1IDI5My4zODIgMjkzLjM4MkMyOTkuMDg1IDI4Ny42NzggMzA2LjgyMSAyODQuNDc0IDMxNC44ODcgMjg0LjQ3NEgzNTQuNTdDMzYzLjM2OSAyODQuNDc4IDM3MS44NDcgMjgxLjE3MSAzNzguMzIgMjc1LjIxQzM4NC43OTIgMjY5LjI0OSAzODguNzg1IDI2MS4wNzEgMzg5LjUwMyAyNTIuMzAxQzM4OS44MzQgMjQ4LjI0NiAzOTAgMjQ0LjE0NiAzOTAgMjQwQzM5MCAxNTcuMTU5IDMyMi44NDQgOTAgMjQwIDkwWk0xNDcuODg0IDI4My4xNDJDMTQyLjk1NyAyODQuMDU5IDEzNy44NjggMjgzLjQ5MyAxMzMuMjYyIDI4MS41MThDMTI4LjY1NiAyNzkuNTQyIDEyNC43MzkgMjc2LjI0NiAxMjIuMDA2IDI3Mi4wNDRDMTE5LjI3MyAyNjcuODQzIDExNy44NDcgMjYyLjkyNSAxMTcuOTA5IDI1Ny45MTRDMTE3Ljk3IDI1Mi45MDIgMTE5LjUxNiAyNDguMDIyIDEyMi4zNTEgMjQzLjg4OUMxMjUuMTg3IDIzOS43NTUgMTI5LjE4MyAyMzYuNTU2IDEzMy44MzcgMjM0LjY5NEMxMzguNDkgMjMyLjgzMiAxNDMuNTkxIDIzMi4zOTIgMTQ4LjQ5NCAyMzMuNDI5QzE1My4zOTggMjM0LjQ2NiAxNTcuODg0IDIzNi45MzMgMTYxLjM4NSAyNDAuNTE5QzE2NC44ODcgMjQ0LjEwNiAxNjcuMjQ2IDI0OC42NDkgMTY4LjE2NiAyNTMuNTc2QzE2OC43NzYgMjU2Ljg0OSAxNjguNzM1IDI2MC4yMTEgMTY4LjA0NiAyNjMuNDY4QzE2Ny4zNTcgMjY2LjcyNSAxNjYuMDMzIDI2OS44MTUgMTY0LjE1IDI3Mi41NjFDMTYyLjI2NiAyNzUuMzA2IDE1OS44NjEgMjc3LjY1NCAxNTcuMDcgMjc5LjQ3QzE1NC4yNzkgMjgxLjI4NSAxNTEuMTU3IDI4Mi41MzMgMTQ3Ljg4NCAyODMuMTQyVjI4My4xNDJaTTE1OC4yNDIgMTcwLjAxN0MxNTcuMzI0IDE2NS4wODkgMTU3Ljg4OSAxNTkuOTk5IDE1OS44NjQgMTU1LjM5MkMxNjEuODM5IDE1MC43ODUgMTY1LjEzNiAxNDYuODY3IDE2OS4zMzggMTQ0LjEzM0MxNzMuNTQgMTQxLjQgMTc4LjQ1OCAxMzkuOTc0IDE4My40NyAxNDAuMDM2QzE4OC40ODMgMTQwLjA5NyAxOTMuMzY0IDE0MS42NDQgMTk3LjQ5NyAxNDQuNDhDMjAxLjYzMSAxNDcuMzE2IDIwNC44MyAxNTEuMzE0IDIwNi42OTEgMTU1Ljk2OUMyMDguNTUyIDE2MC42MjMgMjA4Ljk5MSAxNjUuNzI1IDIwNy45NTIgMTcwLjYyOUMyMDYuOTE0IDE3NS41MzMgMjA0LjQ0NCAxODAuMDE5IDIwMC44NTYgMTgzLjUxOUMxOTcuMjY4IDE4Ny4wMiAxOTIuNzIzIDE4OS4zNzggMTg3Ljc5NSAxOTAuMjk1QzE4NC41MjMgMTkwLjkwNCAxODEuMTYzIDE5MC44NjMgMTc3LjkwNyAxOTAuMTczQzE3NC42NTEgMTg5LjQ4NCAxNzEuNTYyIDE4OC4xNiAxNjguODE4IDE4Ni4yNzdDMTY2LjA3NCAxODQuMzk0IDE2My43MjcgMTgxLjk4OSAxNjEuOTEyIDE3OS4xOTlDMTYwLjA5OCAxNzYuNDA5IDE1OC44NSAxNzMuMjg5IDE1OC4yNDIgMTcwLjAxN1pNMjI0Ljg1OCAzNjAuNTNDMjE4LjMwOSAzNjAuNTMgMjExLjkwNyAzNTguNTg4IDIwNi40NjEgMzU0Ljk0OUMyMDEuMDE2IDM1MS4zMTEgMTk2Ljc3MiAzNDYuMTM5IDE5NC4yNjYgMzQwLjA4OUMxOTEuNzU5IDMzNC4wMzggMTkxLjEwNCAzMjcuMzggMTkyLjM4MSAzMjAuOTU3QzE5My42NTkgMzE0LjUzNCAxOTYuODEzIDMwOC42MzQgMjAxLjQ0MyAzMDQuMDAzQzIwNi4wNzQgMjk5LjM3MiAyMTEuOTc0IDI5Ni4yMTkgMjE4LjM5OCAyOTQuOTQxQzIyNC44MjEgMjkzLjY2MyAyMzEuNDc5IDI5NC4zMTkgMjM3LjUyOSAyOTYuODI1QzI0My41OCAyOTkuMzMxIDI0OC43NTEgMzAzLjU3NiAyNTIuMzkgMzA5LjAyMUMyNTYuMDI4IDMxNC40NjYgMjU3Ljk3IDMyMC44NjggMjU3Ljk3IDMyNy40MTdDMjU3Ljk3IDMzNi4xOTkgMjU0LjQ4MiAzNDQuNjIyIDI0OC4yNzIgMzUwLjgzMUMyNDIuMDYyIDM1Ny4wNDEgMjMzLjY0IDM2MC41MyAyMjQuODU4IDM2MC41M1YzNjAuNTNaTTI4NS43MjggMTgwLjE1MkMyODAuODAxIDE4MS4wNjkgMjc1LjcxMSAxODAuNTA0IDI3MS4xMDUgMTc4LjUyOEMyNjYuNDk4IDE3Ni41NTMgMjYyLjU4MSAxNzMuMjU1IDI1OS44NDggMTY5LjA1NEMyNTcuMTE1IDE2NC44NTIgMjU1LjY4OSAxNTkuOTM0IDI1NS43NTEgMTU0LjkyMkMyNTUuODEzIDE0OS45MSAyNTcuMzYgMTQ1LjAyOCAyNjAuMTk2IDE0MC44OTVDMjYzLjAzMiAxMzYuNzYzIDI2Ny4wMyAxMzMuNTYzIDI3MS42ODQgMTMxLjcwMkMyNzYuMzM5IDEyOS44NDEgMjgxLjQ0IDEyOS40MDIgMjg2LjM0NCAxMzAuNDQxQzI5MS4yNDggMTMxLjQ3OSAyOTUuNzMzIDEzMy45NDggMjk5LjIzNCAxMzcuNTM2QzMwMi43MzQgMTQxLjEyMyAzMDUuMDkyIDE0NS42NjggMzA2LjAxIDE1MC41OTZDMzA3LjI0IDE1Ny4yMDUgMzA1Ljc5NCAxNjQuMDMyIDMwMS45OSAxNjkuNTc0QzI5OC4xODcgMTc1LjExNyAyOTIuMzM3IDE3OC45MjIgMjg1LjcyOCAxODAuMTUyWk0zNDMuNzI1IDI1Ny44NDhDMzM4Ljc5NyAyNTguNzY1IDMzMy43MDggMjU4LjIwMSAzMjkuMSAyNTYuMjI1QzMyNC40OTMgMjU0LjI1IDMyMC41NzUgMjUwLjk1MyAzMTcuODQyIDI0Ni43NTFDMzE1LjEwOCAyNDIuNTUgMzEzLjY4MiAyMzcuNjMxIDMxMy43NDQgMjMyLjYxOUMzMTMuODA2IDIyNy42MDcgMzE1LjM1MyAyMjIuNzI1IDMxOC4xODkgMjE4LjU5MkMzMjEuMDI1IDIxNC40NTkgMzI1LjAyMyAyMTEuMjU5IDMyOS42NzcgMjA5LjM5OEMzMzQuMzMyIDIwNy41MzcgMzM5LjQzNCAyMDcuMDk4IDM0NC4zMzggMjA4LjEzN0MzNDkuMjQyIDIwOS4xNzYgMzUzLjcyNyAyMTEuNjQ1IDM1Ny4yMjggMjE1LjIzM0MzNjAuNzI4IDIxOC44MjEgMzYzLjA4NiAyMjMuMzY3IDM2NC4wMDMgMjI4LjI5NUMzNjQuNjEzIDIzMS41NjcgMzY0LjU3MSAyMzQuOTI3IDM2My44ODIgMjM4LjE4M0MzNjMuMTkzIDI0MS40MzkgMzYxLjg2OSAyNDQuNTI3IDM1OS45ODYgMjQ3LjI3MUMzNTguMTAzIDI1MC4wMTYgMzU1LjY5NyAyNTIuMzYyIDM1Mi45MDcgMjU0LjE3N0MzNTAuMTE3IDI1NS45OTIgMzQ2Ljk5NyAyNTcuMjM5IDM0My43MjUgMjU3Ljg0OFYyNTcuODQ4WiIgZmlsbD0iIzAwRkYwMCIvPgogICAgPC9zdmc+CiAgICA=',
          })
          // Simulating rerender after updating settings' embedImage
          rerender(
            <ImageSection
              {...{
                ...defaultProps,
                settings: {
                  ...defaultProps.settings,
                  embedImage:
                    'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgwIiBoZWlnaHQ9IjQ4MCIgdmlld0JveD0iMCAwIDQ4MCA0ODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgICAgIDxwYXRoIGQ9Ik0yNDAgOTBDMTU3LjIxOSA5MCA5MCAxNTcuMjE5IDkwIDI0MEM5MCAzMjIuODQ0IDE1Ny4xNTkgMzkwIDI0MCAzOTBDMjQ0LjAyOSAzOTAgMjQ4LjAxOSAzODkuODQzIDI1MS45NyAzODkuNTNDMjcwLjM0MSAzODguMDc5IDI4NC40NzQgMzcyLjY3MiAyODQuNDc0IDM1NC4yNDVWMzE0Ljg4N0MyODQuNDc0IDMwNi44MjEgMjg3LjY3OCAyOTkuMDg1IDI5My4zODIgMjkzLjM4MkMyOTkuMDg1IDI4Ny42NzggMzA2LjgyMSAyODQuNDc0IDMxNC44ODcgMjg0LjQ3NEgzNTQuNTdDMzYzLjM2OSAyODQuNDc4IDM3MS44NDcgMjgxLjE3MSAzNzguMzIgMjc1LjIxQzM4NC43OTIgMjY5LjI0OSAzODguNzg1IDI2MS4wNzEgMzg5LjUwMyAyNTIuMzAxQzM4OS44MzQgMjQ4LjI0NiAzOTAgMjQ0LjE0NiAzOTAgMjQwQzM5MCAxNTcuMTU5IDMyMi44NDQgOTAgMjQwIDkwWk0xNDcuODg0IDI4My4xNDJDMTQyLjk1NyAyODQuMDU5IDEzNy44NjggMjgzLjQ5MyAxMzMuMjYyIDI4MS41MThDMTI4LjY1NiAyNzkuNTQyIDEyNC43MzkgMjc2LjI0NiAxMjIuMDA2IDI3Mi4wNDRDMTE5LjI3MyAyNjcuODQzIDExNy44NDcgMjYyLjkyNSAxMTcuOTA5IDI1Ny45MTRDMTE3Ljk3IDI1Mi45MDIgMTE5LjUxNiAyNDguMDIyIDEyMi4zNTEgMjQzLjg4OUMxMjUuMTg3IDIzOS43NTUgMTI5LjE4MyAyMzYuNTU2IDEzMy44MzcgMjM0LjY5NEMxMzguNDkgMjMyLjgzMiAxNDMuNTkxIDIzMi4zOTIgMTQ4LjQ5NCAyMzMuNDI5QzE1My4zOTggMjM0LjQ2NiAxNTcuODg0IDIzNi45MzMgMTYxLjM4NSAyNDAuNTE5QzE2NC44ODcgMjQ0LjEwNiAxNjcuMjQ2IDI0OC42NDkgMTY4LjE2NiAyNTMuNTc2QzE2OC43NzYgMjU2Ljg0OSAxNjguNzM1IDI2MC4yMTEgMTY4LjA0NiAyNjMuNDY4QzE2Ny4zNTcgMjY2LjcyNSAxNjYuMDMzIDI2OS44MTUgMTY0LjE1IDI3Mi41NjFDMTYyLjI2NiAyNzUuMzA2IDE1OS44NjEgMjc3LjY1NCAxNTcuMDcgMjc5LjQ3QzE1NC4yNzkgMjgxLjI4NSAxNTEuMTU3IDI4Mi41MzMgMTQ3Ljg4NCAyODMuMTQyVjI4My4xNDJaTTE1OC4yNDIgMTcwLjAxN0MxNTcuMzI0IDE2NS4wODkgMTU3Ljg4OSAxNTkuOTk5IDE1OS44NjQgMTU1LjM5MkMxNjEuODM5IDE1MC43ODUgMTY1LjEzNiAxNDYuODY3IDE2OS4zMzggMTQ0LjEzM0MxNzMuNTQgMTQxLjQgMTc4LjQ1OCAxMzkuOTc0IDE4My40NyAxNDAuMDM2QzE4OC40ODMgMTQwLjA5NyAxOTMuMzY0IDE0MS42NDQgMTk3LjQ5NyAxNDQuNDhDMjAxLjYzMSAxNDcuMzE2IDIwNC44MyAxNTEuMzE0IDIwNi42OTEgMTU1Ljk2OUMyMDguNTUyIDE2MC42MjMgMjA4Ljk5MSAxNjUuNzI1IDIwNy45NTIgMTcwLjYyOUMyMDYuOTE0IDE3NS41MzMgMjA0LjQ0NCAxODAuMDE5IDIwMC44NTYgMTgzLjUxOUMxOTcuMjY4IDE4Ny4wMiAxOTIuNzIzIDE4OS4zNzggMTg3Ljc5NSAxOTAuMjk1QzE4NC41MjMgMTkwLjkwNCAxODEuMTYzIDE5MC44NjMgMTc3LjkwNyAxOTAuMTczQzE3NC42NTEgMTg5LjQ4NCAxNzEuNTYyIDE4OC4xNiAxNjguODE4IDE4Ni4yNzdDMTY2LjA3NCAxODQuMzk0IDE2My43MjcgMTgxLjk4OSAxNjEuOTEyIDE3OS4xOTlDMTYwLjA5OCAxNzYuNDA5IDE1OC44NSAxNzMuMjg5IDE1OC4yNDIgMTcwLjAxN1pNMjI0Ljg1OCAzNjAuNTNDMjE4LjMwOSAzNjAuNTMgMjExLjkwNyAzNTguNTg4IDIwNi40NjEgMzU0Ljk0OUMyMDEuMDE2IDM1MS4zMTEgMTk2Ljc3MiAzNDYuMTM5IDE5NC4yNjYgMzQwLjA4OUMxOTEuNzU5IDMzNC4wMzggMTkxLjEwNCAzMjcuMzggMTkyLjM4MSAzMjAuOTU3QzE5My42NTkgMzE0LjUzNCAxOTYuODEzIDMwOC42MzQgMjAxLjQ0MyAzMDQuMDAzQzIwNi4wNzQgMjk5LjM3MiAyMTEuOTc0IDI5Ni4yMTkgMjE4LjM5OCAyOTQuOTQxQzIyNC44MjEgMjkzLjY2MyAyMzEuNDc5IDI5NC4zMTkgMjM3LjUyOSAyOTYuODI1QzI0My41OCAyOTkuMzMxIDI0OC43NTEgMzAzLjU3NiAyNTIuMzkgMzA5LjAyMUMyNTYuMDI4IDMxNC40NjYgMjU3Ljk3IDMyMC44NjggMjU3Ljk3IDMyNy40MTdDMjU3Ljk3IDMzNi4xOTkgMjU0LjQ4MiAzNDQuNjIyIDI0OC4yNzIgMzUwLjgzMUMyNDIuMDYyIDM1Ny4wNDEgMjMzLjY0IDM2MC41MyAyMjQuODU4IDM2MC41M1YzNjAuNTNaTTI4NS43MjggMTgwLjE1MkMyODAuODAxIDE4MS4wNjkgMjc1LjcxMSAxODAuNTA0IDI3MS4xMDUgMTc4LjUyOEMyNjYuNDk4IDE3Ni41NTMgMjYyLjU4MSAxNzMuMjU1IDI1OS44NDggMTY5LjA1NEMyNTcuMTE1IDE2NC44NTIgMjU1LjY4OSAxNTkuOTM0IDI1NS43NTEgMTU0LjkyMkMyNTUuODEzIDE0OS45MSAyNTcuMzYgMTQ1LjAyOCAyNjAuMTk2IDE0MC44OTVDMjYzLjAzMiAxMzYuNzYzIDI2Ny4wMyAxMzMuNTYzIDI3MS42ODQgMTMxLjcwMkMyNzYuMzM5IDEyOS44NDEgMjgxLjQ0IDEyOS40MDIgMjg2LjM0NCAxMzAuNDQxQzI5MS4yNDggMTMxLjQ3OSAyOTUuNzMzIDEzMy45NDggMjk5LjIzNCAxMzcuNTM2QzMwMi43MzQgMTQxLjEyMyAzMDUuMDkyIDE0NS42NjggMzA2LjAxIDE1MC41OTZDMzA3LjI0IDE1Ny4yMDUgMzA1Ljc5NCAxNjQuMDMyIDMwMS45OSAxNjkuNTc0QzI5OC4xODcgMTc1LjExNyAyOTIuMzM3IDE3OC45MjIgMjg1LjcyOCAxODAuMTUyWk0zNDMuNzI1IDI1Ny44NDhDMzM4Ljc5NyAyNTguNzY1IDMzMy43MDggMjU4LjIwMSAzMjkuMSAyNTYuMjI1QzMyNC40OTMgMjU0LjI1IDMyMC41NzUgMjUwLjk1MyAzMTcuODQyIDI0Ni43NTFDMzE1LjEwOCAyNDIuNTUgMzEzLjY4MiAyMzcuNjMxIDMxMy43NDQgMjMyLjYxOUMzMTMuODA2IDIyNy42MDcgMzE1LjM1MyAyMjIuNzI1IDMxOC4xODkgMjE4LjU5MkMzMjEuMDI1IDIxNC40NTkgMzI1LjAyMyAyMTEuMjU5IDMyOS42NzcgMjA5LjM5OEMzMzQuMzMyIDIwNy41MzcgMzM5LjQzNCAyMDcuMDk4IDM0NC4zMzggMjA4LjEzN0MzNDkuMjQyIDIwOS4xNzYgMzUzLjcyNyAyMTEuNjQ1IDM1Ny4yMjggMjE1LjIzM0MzNjAuNzI4IDIxOC44MjEgMzYzLjA4NiAyMjMuMzY3IDM2NC4wMDMgMjI4LjI5NUMzNjQuNjEzIDIzMS41NjcgMzY0LjU3MSAyMzQuOTI3IDM2My44ODIgMjM4LjE4M0MzNjMuMTkzIDI0MS40MzkgMzYxLjg2OSAyNDQuNTI3IDM1OS45ODYgMjQ3LjI3MUMzNTguMTAzIDI1MC4wMTYgMzU1LjY5NyAyNTIuMzYyIDM1Mi45MDcgMjU0LjE3N0MzNTAuMTE3IDI1NS45OTIgMzQ2Ljk5NyAyNTcuMjM5IDM0My43MjUgMjU3Ljg0OFYyNTcuODQ4WiIgZmlsbD0iIzAwRkYwMCIvPgogICAgPC9zdmc+CiAgICA=',
                },
              }}
            />
          )
          expect(getByTestId('selected-image-preview')).toHaveStyle(
            'backgroundImage: url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDgwIiBoZWlnaHQ9IjQ4MCIgdmlld0JveD0iMCAwIDQ4MCA0ODAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI+CiAgICAgIDxwYXRoIGQ9Ik0yNDAgOTBDMTU3LjIxOSA5MCA5MCAxNTcuMjE5IDkwIDI0MEM5MCAzMjIuODQ0IDE1Ny4xNTkgMzkwIDI0MCAzOTBDMjQ0LjAyOSAzOTAgMjQ4LjAxOSAzODkuODQzIDI1MS45NyAzODkuNTNDMjcwLjM0MSAzODguMDc5IDI4NC40NzQgMzcyLjY3MiAyODQuNDc0IDM1NC4yNDVWMzE0Ljg4N0MyODQuNDc0IDMwNi44MjEgMjg3LjY3OCAyOTkuMDg1IDI5My4zODIgMjkzLjM4MkMyOTkuMDg1IDI4Ny42NzggMzA2LjgyMSAyODQuNDc0IDMxNC44ODcgMjg0LjQ3NEgzNTQuNTdDMzYzLjM2OSAyODQuNDc4IDM3MS44NDcgMjgxLjE3MSAzNzguMzIgMjc1LjIxQzM4NC43OTIgMjY5LjI0OSAzODguNzg1IDI2MS4wNzEgMzg5LjUwMyAyNTIuMzAxQzM4OS44MzQgMjQ4LjI0NiAzOTAgMjQ0LjE0NiAzOTAgMjQwQzM5MCAxNTcuMTU5IDMyMi44NDQgOTAgMjQwIDkwWk0xNDcuODg0IDI4My4xNDJDMTQyLjk1NyAyODQuMDU5IDEzNy44NjggMjgzLjQ5MyAxMzMuMjYyIDI4MS41MThDMTI4LjY1NiAyNzkuNTQyIDEyNC43MzkgMjc2LjI0NiAxMjIuMDA2IDI3Mi4wNDRDMTE5LjI3MyAyNjcuODQzIDExNy44NDcgMjYyLjkyNSAxMTcuOTA5IDI1Ny45MTRDMTE3Ljk3IDI1Mi45MDIgMTE5LjUxNiAyNDguMDIyIDEyMi4zNTEgMjQzLjg4OUMxMjUuMTg3IDIzOS43NTUgMTI5LjE4MyAyMzYuNTU2IDEzMy44MzcgMjM0LjY5NEMxMzguNDkgMjMyLjgzMiAxNDMuNTkxIDIzMi4zOTIgMTQ4LjQ5NCAyMzMuNDI5QzE1My4zOTggMjM0LjQ2NiAxNTcuODg0IDIzNi45MzMgMTYxLjM4NSAyNDAuNTE5QzE2NC44ODcgMjQ0LjEwNiAxNjcuMjQ2IDI0OC42NDkgMTY4LjE2NiAyNTMuNTc2QzE2OC43NzYgMjU2Ljg0OSAxNjguNzM1IDI2MC4yMTEgMTY4LjA0NiAyNjMuNDY4QzE2Ny4zNTcgMjY2LjcyNSAxNjYuMDMzIDI2OS44MTUgMTY0LjE1IDI3Mi41NjFDMTYyLjI2NiAyNzUuMzA2IDE1OS44NjEgMjc3LjY1NCAxNTcuMDcgMjc5LjQ3QzE1NC4yNzkgMjgxLjI4NSAxNTEuMTU3IDI4Mi41MzMgMTQ3Ljg4NCAyODMuMTQyVjI4My4xNDJaTTE1OC4yNDIgMTcwLjAxN0MxNTcuMzI0IDE2NS4wODkgMTU3Ljg4OSAxNTkuOTk5IDE1OS44NjQgMTU1LjM5MkMxNjEuODM5IDE1MC43ODUgMTY1LjEzNiAxNDYuODY3IDE2OS4zMzggMTQ0LjEzM0MxNzMuNTQgMTQxLjQgMTc4LjQ1OCAxMzkuOTc0IDE4My40NyAxNDAuMDM2QzE4OC40ODMgMTQwLjA5NyAxOTMuMzY0IDE0MS42NDQgMTk3LjQ5NyAxNDQuNDhDMjAxLjYzMSAxNDcuMzE2IDIwNC44MyAxNTEuMzE0IDIwNi42OTEgMTU1Ljk2OUMyMDguNTUyIDE2MC42MjMgMjA4Ljk5MSAxNjUuNzI1IDIwNy45NTIgMTcwLjYyOUMyMDYuOTE0IDE3NS41MzMgMjA0LjQ0NCAxODAuMDE5IDIwMC44NTYgMTgzLjUxOUMxOTcuMjY4IDE4Ny4wMiAxOTIuNzIzIDE4OS4zNzggMTg3Ljc5NSAxOTAuMjk1QzE4NC41MjMgMTkwLjkwNCAxODEuMTYzIDE5MC44NjMgMTc3LjkwNyAxOTAuMTczQzE3NC42NTEgMTg5LjQ4NCAxNzEuNTYyIDE4OC4xNiAxNjguODE4IDE4Ni4yNzdDMTY2LjA3NCAxODQuMzk0IDE2My43MjcgMTgxLjk4OSAxNjEuOTEyIDE3OS4xOTlDMTYwLjA5OCAxNzYuNDA5IDE1OC44NSAxNzMuMjg5IDE1OC4yNDIgMTcwLjAxN1pNMjI0Ljg1OCAzNjAuNTNDMjE4LjMwOSAzNjAuNTMgMjExLjkwNyAzNTguNTg4IDIwNi40NjEgMzU0Ljk0OUMyMDEuMDE2IDM1MS4zMTEgMTk2Ljc3MiAzNDYuMTM5IDE5NC4yNjYgMzQwLjA4OUMxOTEuNzU5IDMzNC4wMzggMTkxLjEwNCAzMjcuMzggMTkyLjM4MSAzMjAuOTU3QzE5My42NTkgMzE0LjUzNCAxOTYuODEzIDMwOC42MzQgMjAxLjQ0MyAzMDQuMDAzQzIwNi4wNzQgMjk5LjM3MiAyMTEuOTc0IDI5Ni4yMTkgMjE4LjM5OCAyOTQuOTQxQzIyNC44MjEgMjkzLjY2MyAyMzEuNDc5IDI5NC4zMTkgMjM3LjUyOSAyOTYuODI1QzI0My41OCAyOTkuMzMxIDI0OC43NTEgMzAzLjU3NiAyNTIuMzkgMzA5LjAyMUMyNTYuMDI4IDMxNC40NjYgMjU3Ljk3IDMyMC44NjggMjU3Ljk3IDMyNy40MTdDMjU3Ljk3IDMzNi4xOTkgMjU0LjQ4MiAzNDQuNjIyIDI0OC4yNzIgMzUwLjgzMUMyNDIuMDYyIDM1Ny4wNDEgMjMzLjY0IDM2MC41MyAyMjQuODU4IDM2MC41M1YzNjAuNTNaTTI4NS43MjggMTgwLjE1MkMyODAuODAxIDE4MS4wNjkgMjc1LjcxMSAxODAuNTA0IDI3MS4xMDUgMTc4LjUyOEMyNjYuNDk4IDE3Ni41NTMgMjYyLjU4MSAxNzMuMjU1IDI1OS44NDggMTY5LjA1NEMyNTcuMTE1IDE2NC44NTIgMjU1LjY4OSAxNTkuOTM0IDI1NS43NTEgMTU0LjkyMkMyNTUuODEzIDE0OS45MSAyNTcuMzYgMTQ1LjAyOCAyNjAuMTk2IDE0MC44OTVDMjYzLjAzMiAxMzYuNzYzIDI2Ny4wMyAxMzMuNTYzIDI3MS42ODQgMTMxLjcwMkMyNzYuMzM5IDEyOS44NDEgMjgxLjQ0IDEyOS40MDIgMjg2LjM0NCAxMzAuNDQxQzI5MS4yNDggMTMxLjQ3OSAyOTUuNzMzIDEzMy45NDggMjk5LjIzNCAxMzcuNTM2QzMwMi43MzQgMTQxLjEyMyAzMDUuMDkyIDE0NS42NjggMzA2LjAxIDE1MC41OTZDMzA3LjI0IDE1Ny4yMDUgMzA1Ljc5NCAxNjQuMDMyIDMwMS45OSAxNjkuNTc0QzI5OC4xODcgMTc1LjExNyAyOTIuMzM3IDE3OC45MjIgMjg1LjcyOCAxODAuMTUyWk0zNDMuNzI1IDI1Ny44NDhDMzM4Ljc5NyAyNTguNzY1IDMzMy43MDggMjU4LjIwMSAzMjkuMSAyNTYuMjI1QzMyNC40OTMgMjU0LjI1IDMyMC41NzUgMjUwLjk1MyAzMTcuODQyIDI0Ni43NTFDMzE1LjEwOCAyNDIuNTUgMzEzLjY4MiAyMzcuNjMxIDMxMy43NDQgMjMyLjYxOUMzMTMuODA2IDIyNy42MDcgMzE1LjM1MyAyMjIuNzI1IDMxOC4xODkgMjE4LjU5MkMzMjEuMDI1IDIxNC40NTkgMzI1LjAyMyAyMTEuMjU5IDMyOS42NzcgMjA5LjM5OEMzMzQuMzMyIDIwNy41MzcgMzM5LjQzNCAyMDcuMDk4IDM0NC4zMzggMjA4LjEzN0MzNDkuMjQyIDIwOS4xNzYgMzUzLjcyNyAyMTEuNjQ1IDM1Ny4yMjggMjE1LjIzM0MzNjAuNzI4IDIxOC44MjEgMzYzLjA4NiAyMjMuMzY3IDM2NC4wMDMgMjI4LjI5NUMzNjQuNjEzIDIzMS41NjcgMzY0LjU3MSAyMzQuOTI3IDM2My44ODIgMjM4LjE4M0MzNjMuMTkzIDI0MS40MzkgMzYxLjg2OSAyNDQuNTI3IDM1OS45ODYgMjQ3LjI3MUMzNTguMTAzIDI1MC4wMTYgMzU1LjY5NyAyNTIuMzYyIDM1Mi45MDcgMjU0LjE3N0MzNTAuMTE3IDI1NS45OTIgMzQ2Ljk5NyAyNTcuMjM5IDM0My43MjUgMjU3Ljg0OFYyNTcuODQ4WiIgZmlsbD0iIzAwRkYwMCIvPgogICAgPC9zdmc+CiAgICA=)'
          )
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
                imageSettings: {
                  image: 'data:image/jpg;base64,asdfasdfjksdf==',
                  mode: 'Course',
                  imageName: 'banana.jpg',
                },
              },
              editing: true,
            },
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
                embedImage: 'data:image/png;base64,EMBED_IMAGE_2',
                imageSettings: {
                  image: 'data:image/jpg;base64,asdfasdfjksdf==',
                  mode: 'Course',
                  imageName: 'banana.jpg',
                },
              },
              editing: true,
            },
          }}
        />
      )
      expect(getByTestId('selected-image-preview')).toHaveStyle(
        'backgroundImage: url(data:image/png;base64,EMBED_IMAGE_2)'
      )
    })

    it('renders color picker for single color icon', async () => {
      const rendered = subject({editing: true})
      rendered.rerender(
        <ImageSection
          {...{
            ...defaultProps,
            ...{
              settings: {
                imageSettings: {
                  image: 'data:image/jpg;base64,asdfasdfjksdf==',
                  imageName: 'banana.jpg',
                  mode: 'SingleColor',
                  icon: 'art',
                },
              },
              editing: true,
            },
          }}
        />
      )
      expect(
        rendered.container.querySelector('[name="single-color-image-fill"]')
      ).toBeInTheDocument()
    })

    it('gets the color for selected icon', async () => {
      const rendered = subject({editing: true})
      rendered.rerender(
        <ImageSection
          {...{
            ...defaultProps,
            ...{
              settings: {
                imageSettings: {
                  image: 'data:image/jpg;base64,asdfasdfjksdf==',
                  imageName: 'banana.jpg',
                  mode: 'SingleColor',
                  icon: 'art',
                  iconFillColor: '#00FF00',
                },
              },
              editing: true,
            },
          }}
        />
      )
      await act(async () => {
        jest.runOnlyPendingTimers()
      })
      expect(rendered.container.querySelector('[name="single-color-image-fill"]')).toHaveValue(
        '#00FF00'
      )
    })
  })
})
