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
import FakeEditor from '../../../../../shared/__tests__/FakeEditor'
import fetchMock from 'fetch-mock'

jest.mock('../../../../../../../bridge', () => {
  return {
    trayProps: {
      get: () => ({foo: 'bar'})
    }
  }
})

let props
const subject = () => render(<Upload {...props} />)

describe('Upload()', () => {
  beforeEach(() => {
    props = {editor: new FakeEditor(), dispatch: jest.fn()}
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
    const theFile = {
      preview:
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAASwAAAEBCAMAAAD1kWivAAADAFBMVEWysrL5nCYYGBj7/+rceo3w1tD+yAfwFTPrIj36',
      name: 'Test Image.png'
    }

    const onSubmitCall = () =>
      onSubmit(dispatch)(
        {},
        {},
        {},
        {
          theFile
        }
      )

    afterEach(() => jest.clearAllMocks())

    it('sets the selected image', () => {
      onSubmitCall()
      expect(dispatch).toHaveBeenCalledWith({...actions.SET_IMAGE, payload: theFile.preview})
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
  })
})
