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
import {fireEvent, render, screen} from '@testing-library/react'
import {ImageOptions} from '../ImageOptions'

describe('ImageOptions', () => {
  const dispatchFn = jest.fn()
  const defaultProps = {
    state: {
      image: null,
      imageName: null,
      mode: null,
      loading: false
    },
    dispatch: dispatchFn
  }

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

  describe('when image is set', () => {
    let getByText, getByTestId, queryByTestId, rerender

    beforeEach(() => {
      const component = subject({
        state: {
          image: 'data:image/png;base64,asdfasdfjksdf==',
          imageName: 'banana.jpg',
          mode: 'Course',
          loading: false
        }
      })
      getByText = component.getByText
      getByTestId = component.getByTestId
      queryByTestId = component.queryByTestId
      rerender = component.rerender
    })

    it('sets the image name', () => {
      expect(getByText('banana.jpg')).toBeInTheDocument()
    })

    it('sets the image preview', () => {
      expect(getByTestId('selected-image-preview')).toHaveStyle(
        'backgroundImage: url(data:image/png;base64,asdfasdfjksdf==)'
      )
    })

    describe('crop button', () => {
      it('is rendered', () => {
        expect(getByText(/crop image/i)).toBeInTheDocument()
      })

      it('is not rendered', () => {
        rerender(
          <ImageOptions
            dispatch={dispatchFn}
            state={{
              image: 'data:image/png;base64,asdfasdfjksdf==',
              imageName: 'banana.jpg',
              mode: 'Upload',
              loading: false
            }}
          />
        )
        expect(queryByTestId('crop-image-button')).not.toBeInTheDocument()
      })

      it('opens crop modal', () => {
        fireEvent.click(getByText(/crop image/i))

        expect(screen.getByText('Crop Image')).toBeInTheDocument()
      })
    })

    describe('clear button', () => {
      it('is rendered', async () => {
        expect(getByText(/clear image/i)).toBeInTheDocument()
      })

      it('executes dispatch callback', () => {
        fireEvent.click(getByText(/clear image/i))

        expect(dispatchFn).toHaveBeenCalledWith({type: 'ClearImage'})
        expect(dispatchFn).toHaveBeenCalledWith({type: 'ClearMode'})
      })
    })
  })

  describe('when the "Upload Image" mode is selected', () => {
    beforeEach(() => {
      ENV.FEATURES.buttons_and_icons_cropper = true

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
      ENV.FEATURES.buttons_and_icons_cropper = true

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
