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
import {render, waitFor, fireEvent} from '@testing-library/react'
import Upload, {onSubmit} from '../Upload'
import {actions} from '../../../../reducers/imageSection'
import {actions as svgActions} from '../../../../reducers/svgSettings'
import FakeEditor from '../../../../../../__tests__/FakeEditor'
import fetchMock from 'fetch-mock'
import {isAnUnsupportedGifPngImage} from '../utils'

jest.mock('../../../../../../../bridge', () => {
  return {
    trayProps: {
      get: () => ({foo: 'bar'}),
    },
  }
})

jest.mock('../../../../../shared/compressionUtils', () => ({
  ...jest.requireActual('../../../../../shared/compressionUtils'),
  compressImage: jest.fn().mockReturnValue(Promise.resolve('data:image/jpeg;base64,abcdefghijk==')),
}))

jest.mock('../utils', () => ({
  ...jest.requireActual('../utils'),
  isAnUnsupportedGifPngImage: jest.fn().mockReturnValue(false),
}))

let props
const subject = () => render(<Upload {...props} />)

describe('Upload()', () => {
  beforeEach(() => {
    props = {editor: new FakeEditor(), dispatch: jest.fn(), canvasOrigin: 'http://canvas.docker'}
    fetchMock.mock('/api/session', '{}')
  })

  afterEach(() => {
    fetchMock.restore()
    jest.clearAllMocks()
  })

  it('renders an upload modal', async () => {
    const {getAllByText} = subject(props)
    await waitFor(() => expect(getAllByText('Upload Image').length).toBe(2))
  })

  describe('when the "Close" button is pressed', () => {
    let rendered

    beforeEach(async () => {
      rendered = subject()
      const button = await rendered.findAllByText(/Close/i)
      fireEvent.click(button[0])
    })

    it('closes the modal', async () => {
      expect(props.dispatch).toHaveBeenCalled()
    })
  })

  describe('onSubmit()', () => {
    const dispatch = jest.fn()
    const onChange = jest.fn()
    const theFile = {
      preview:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAEBCAMAAAD1kWivAAADAFBMVEWysrL5nCYYGBj7/+rceo3w1tD+yAfwFTPrIj36',
      name: 'Test Image.png',
      type: 'image/png',
      size: 100000,
    }

    const onSubmitCall = () =>
      onSubmit(dispatch, onChange)(
        {},
        {},
        {},
        {
          theFile,
        }
      )

    afterEach(() => jest.clearAllMocks())

    it('sets the selected image to preview', () => {
      onSubmitCall()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_IMAGE, payload: theFile.preview})
    })

    it('sets the selected image as embed image', () => {
      onSubmitCall()
      expect(onChange).toHaveBeenCalledWith({
        type: svgActions.SET_EMBED_IMAGE,
        payload: theFile.preview,
      })
    })

    it('sets the selected image name', () => {
      onSubmitCall()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_IMAGE_NAME, payload: theFile.name})
    })

    it('closes the collection', () => {
      onSubmitCall()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
    })

    it('opens image cropper', () => {
      onSubmitCall()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_CROPPER_OPEN, payload: true})
    })

    describe('with an unsupported image', () => {
      beforeAll(() => {
        isAnUnsupportedGifPngImage.mockReturnValue(true)
      })

      afterAll(() => {
        isAnUnsupportedGifPngImage.mockReturnValue(false)
      })

      it('closes the collection', () => {
        onSubmitCall()
        expect(dispatch).toHaveBeenCalledWith({
          ...actions.SET_IMAGE_COLLECTION_OPEN,
          payload: false,
        })
      })

      it('sets the error', () => {
        onSubmitCall()
        expect(onChange).toHaveBeenCalledWith({
          type: 'SetError',
          payload: 'GIF/PNG format images larger than 250 KB are not currently supported.',
        })
      })
    })
  })

  describe('onSubmit() with an image to be compressed', () => {
    const dispatch = jest.fn()
    const onChange = jest.fn()
    const theFile = {
      preview:
        'data:image/jpeg;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAEBCAMAAAD1kWivAAADAFBMVEWysrL5nCYYGBj7/+rceo3w1tD+yAfwFTPrIj36',
      name: 'Test Image.jpeg',
      type: 'image/jpeg',
      size: 600000,
    }

    const onSubmitCall = () =>
      onSubmit(dispatch, onChange)(
        {},
        {},
        {},
        {
          theFile,
        }
      )

    const flushPromises = () => new Promise(setTimeout)

    afterEach(() => jest.clearAllMocks())

    it('sets the compression status', async () => {
      onSubmitCall()
      await flushPromises()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_COMPRESSION_STATUS, payload: true})
    })

    it('sets the selected image to preview', async () => {
      onSubmitCall()
      await flushPromises()
      expect(dispatch).toHaveBeenCalledWith({
        ...actions.SET_IMAGE,
        payload: 'data:image/jpeg;base64,abcdefghijk==',
      })
    })

    it('sets the selected image as embed image', async () => {
      onSubmitCall()
      await flushPromises()
      expect(onChange).toHaveBeenCalledWith({
        type: svgActions.SET_EMBED_IMAGE,
        payload: 'data:image/jpeg;base64,abcdefghijk==',
      })
    })

    it('sets the selected image name', async () => {
      onSubmitCall()
      await flushPromises()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_IMAGE_NAME, payload: 'Test Image.jpeg'})
    })

    it('closes the collection', async () => {
      onSubmitCall()
      await flushPromises()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
    })

    it('opens image cropper', async () => {
      onSubmitCall()
      await flushPromises()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_CROPPER_OPEN, payload: true})
    })
  })
})
