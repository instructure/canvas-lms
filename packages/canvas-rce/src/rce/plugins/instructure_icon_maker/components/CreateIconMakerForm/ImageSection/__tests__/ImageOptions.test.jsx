/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {fireEvent, render, waitFor, act} from '@testing-library/react'
import {ImageOptions} from '../ImageOptions'
import {actions} from '../../../../reducers/imageSection'
import {actions as trayActions} from '../../../../reducers/svgSettings'

jest.mock('../../../../../shared/ImageCropper/imageCropUtils', () => ({
  createCroppedImageSvg: jest.fn(() =>
    Promise.resolve({
      outerHTML: '<svg />',
    })
  ),
}))

jest.mock('../../../../../shared/fileUtils', () => {
  return {
    convertFileToBase64: jest
      .fn()
      .mockReturnValue(Promise.resolve('data:image/png;base64,CROPPED')),
  }
})

describe('ImageOptions', () => {
  const dispatchFn = jest.fn()
  const trayDispatchFn = jest.fn()
  const defaultProps = {
    state: {
      image: null,
      imageName: null,
      mode: null,
      collectionOpen: false,
      cropperOpen: false,
      loading: false,
      cropperSettings: null,
      compressed: false,
    },
    settings: {
      shape: 'square',
      embedImage: null,
    },
    dispatch: dispatchFn,
    trayDispatch: trayDispatchFn,
  }

  beforeAll(() => {
    global.fetch = jest.fn().mockResolvedValue({
      blob: () => Promise.resolve(new Blob(['somedata'], {type: 'image/svg+xml'})),
    })
  })

  const subject = overrides => render(<ImageOptions {...{...defaultProps, ...overrides}} />)

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

  describe('cropper modal', () => {
    beforeEach(() => {
      subject({
        state: {
          image: 'data:image/png;base64,asdfasdfjksdf==',
          imageName: 'banana.jpg',
          mode: 'Course',
          collectionOpen: false,
          cropperOpen: true,
          loading: false,
          compressed: false,
        },
      })
    })

    it('renders', async () => {
      await waitFor(() => {
        expect(document.querySelector('[data-cid="Modal"] [type="submit"]')).toBeInTheDocument()
      })
    })

    it('sets state cropper settings when submitting', async () => {
      await waitFor(() => {
        fireEvent.click(document.querySelector('[data-cid="Modal"] [type="submit"]'))
        expect(dispatchFn).toHaveBeenCalledWith({
          type: 'SetCropperSettings',
          payload: {
            rotation: 0,
            scaleRatio: 1,
            shape: 'square',
            translateX: 0,
            translateY: 0,
          },
        })
      })
    })

    describe('when editing', () => {
      let overrides

      beforeEach(() => {
        overrides = {
          state: {
            image: 'data:image/png;base64,asdfasdfjksdf==',
            imageName: 'banana.png',
            mode: 'Course',
            collectionOpen: false,
            cropperOpen: false,
            loading: false,
            compressed: false,
            cropperSettings: {
              shape: 'square',
              rotation: 0,
              scaleRatio: 1.0,
              translateX: 0,
              translateY: 0,
            },
          },
          settings: {
            shape: 'square',
            embedImage: null,
            imageSettings: {
              cropperSettings: {
                shape: 'square',
                rotation: 0,
                scaleRatio: 1.0,
                translateX: 0,
                translateY: 0,
              },
            },
          },
        }
      })

      it('updates icon shape if shape is different', async () => {
        const {rerender} = subject(overrides)

        overrides.state.cropperSettings = {
          shape: 'circle',
          rotation: 90,
          scaleRatio: 1.5,
          translateX: 0,
          translateY: 0,
        }
        rerender(<ImageOptions {...{...defaultProps, ...overrides}} />)
        await waitFor(() => {
          expect(defaultProps.trayDispatch).toHaveBeenCalledWith({shape: 'circle'})
        })
      })

      it('does not update icon shape if shape is not different', async () => {
        const {rerender} = subject(overrides)

        overrides.state.cropperSettings = {
          shape: 'square',
          rotation: 90,
          scaleRatio: 1.5,
          translateX: 0,
          translateY: 0,
        }
        rerender(<ImageOptions {...{...defaultProps, ...overrides}} />)
        await waitFor(() => {
          expect(defaultProps.trayDispatch).not.toHaveBeenCalledWith({shape: 'square'})
        })
      })

      it('updates embed image', async () => {
        const {rerender} = subject(overrides)

        overrides.state.cropperSettings = {
          shape: 'circle',
          rotation: 90,
          scaleRatio: 1.5,
          translateX: 0,
          translateY: 0,
        }
        rerender(<ImageOptions {...{...defaultProps, ...overrides}} />)
        await waitFor(() => {
          expect(defaultProps.trayDispatch).toHaveBeenCalledWith({
            type: 'SetEmbedImage',
            payload: 'data:image/png;base64,CROPPED',
          })
        })
      })

      describe('if cropper settings did not change', () => {
        beforeEach(() => {
          overrides = {
            state: {
              image: 'data:image/png;base64,asdfasdfjksdf==',
              imageName: 'banana.png',
              mode: 'Course',
              collectionOpen: false,
              cropperOpen: false,
              loading: false,
              compressed: false,
              cropperSettings: {
                shape: 'circle',
                rotation: 90,
                scaleRatio: 1.5,
                translateX: 0,
                translateY: 0,
              },
            },
            settings: {
              imageSettings: {
                cropperSettings: {
                  shape: 'circle',
                  rotation: 90,
                  scaleRatio: 1.5,
                  translateX: 0,
                  translateY: 0,
                },
              },
            },
          }
          const {rerender} = subject(overrides)

          overrides.state.cropperSettings = {
            shape: 'circle',
            rotation: 90,
            scaleRatio: 1.5,
            translateX: 0,
            translateY: 0,
          }
          rerender(<ImageOptions {...{...defaultProps, ...overrides}} />)
        })

        it('does not update icon shape', async () => {
          await waitFor(() => {
            expect(defaultProps.trayDispatch).not.toHaveBeenCalledWith({
              type: 'SetImageSettings',
              payload: {
                shape: 'circle',
                rotation: 90,
                scaleRatio: 1.5,
                translateX: 0,
                translateY: 0,
              },
            })
          })
        })

        it('does not update embed image', async () => {
          await waitFor(() => {
            expect(defaultProps.trayDispatch).not.toHaveBeenCalledWith({
              type: 'SetEmbedImage',
              payload: 'data:image/png;base64,CROPPED',
            })
          })
        })
      })
    })
  })

  describe('focus management', () => {
    const state = {
      image: null,
      imageName: 'banana.jpg',
      mode: 'Course',
      collectionOpen: false,
      cropperOpen: false,
      loading: false,
      compressed: false,
    }

    it('focuses Clear button when an image is selected', async () => {
      const {getByTestId, rerender} = subject({state})

      const addImage = await getByTestId('add-image')
      act(() => addImage.focus())

      state.image = 'data:image/png;base64,asdfasdfjksdf=='

      rerender(<ImageOptions {...defaultProps} state={state} />)

      await waitFor(() => expect(getByTestId('clear-image')).toHaveFocus())
    })

    it('focuses Add Image button when an image is cleared', async () => {
      state.image = 'data:image/png;base64,asdfasdfjksdf=='
      const {getByTestId, rerender} = subject({state})

      const clearImage = getByTestId('clear-image')
      act(() => clearImage.focus())

      state.image = null
      rerender(<ImageOptions {...defaultProps} state={state} />)

      await waitFor(() => expect(getByTestId('add-image')).toHaveFocus())
    })
  })

  describe('when image is set', () => {
    let getByText, getByTestId, queryByText, rerender
    const initialState = {
      image: 'data:image/png;base64,asdfasdfjksdf==',
      imageName: 'banana.jpg',
      mode: 'Course',
      collectionOpen: false,
      cropperOpen: false,
      loading: false,
      compressed: false,
    }

    beforeEach(() => {
      const component = subject({
        state: initialState,
        settings: {
          shape: 'square',
          embedImage: 'data:image/png;base64,EMBED_IMAGE',
        },
      })
      getByText = component.getByText
      getByTestId = component.getByTestId
      rerender = component.rerender
      queryByText = component.queryByText
    })

    it('sets the image name', () => {
      expect(getByText('banana.jpg')).toBeInTheDocument()
    })

    it('sets the image preview', () => {
      expect(getByTestId('selected-image-preview')).toHaveStyle(
        'backgroundImage: url(data:image/png;base64,EMBED_IMAGE)'
      )
    })

    describe('crop button', () => {
      it('is rendered for course images', () => {
        rerender(<ImageOptions {...{...defaultProps, state: {...initialState, mode: 'Course'}}} />)
        expect(queryByText(/crop image/i)).toBeInTheDocument()
      })

      it('is rendered for upload images', () => {
        rerender(<ImageOptions {...{...defaultProps, state: {...initialState, mode: 'Upload'}}} />)
        expect(queryByText(/crop image/i)).toBeInTheDocument()
      })

      it('is not rendered for single color images', () => {
        rerender(
          <ImageOptions {...{...defaultProps, state: {...initialState, mode: 'SingleColor'}}} />
        )
        expect(queryByText(/crop image/i)).not.toBeInTheDocument()
      })

      it('is not rendered for multi color images', () => {
        rerender(
          <ImageOptions {...{...defaultProps, state: {...initialState, mode: 'MultiColor'}}} />
        )
        expect(queryByText(/crop image/i)).not.toBeInTheDocument()
      })

      it('calls dispatch callback', () => {
        fireEvent.click(getByText(/crop image/i))

        expect(dispatchFn.mock.calls[0][0]).toEqual({
          type: 'SetCropperOpen',
          payload: true,
        })
      })
    })

    describe('clear button', () => {
      it('is rendered', async () => {
        expect(getByText(/clear image/i)).toBeInTheDocument()
      })

      it('executes dispatch callback', () => {
        fireEvent.click(getByText(/clear image/i))

        expect(dispatchFn).toHaveBeenCalledWith(actions.RESET_ALL)
      })

      it('executes tray dispatch callback', () => {
        fireEvent.click(getByText(/clear image/i))

        expect(trayDispatchFn).toHaveBeenCalledWith({
          type: trayActions.SET_EMBED_IMAGE,
          payload: null,
        })
      })
    })
  })

  describe('when the "Upload Image" mode is selected', () => {
    beforeEach(() => {
      const component = subject()

      fireEvent.click(component.getByText('Add Image'))
      fireEvent.click(component.getByText('Upload Image'))
    })

    it('executes dispatch callback', () => {
      expect(dispatchFn).toHaveBeenCalledWith({type: 'Upload'})
    })
  })

  describe('when the "Course Images" mode is selected', () => {
    beforeEach(() => {
      const component = subject()

      fireEvent.click(component.getByText('Add Image'))
      fireEvent.click(component.getByText('Course Images'))
    })

    it('executes dispatch callback', () => {
      expect(dispatchFn).toHaveBeenCalledWith({type: 'Course'})
    })
  })

  describe('when the "Multi Color Image" mode is selected', () => {
    beforeEach(() => {
      const component = subject()

      fireEvent.click(component.getByText('Add Image'))
      fireEvent.click(component.getByText('Multi Color Image'))
    })

    it('executes dispatch callback', () => {
      expect(dispatchFn).toHaveBeenCalledWith({type: 'MultiColor'})
    })
  })
})
