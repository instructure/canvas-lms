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
import {render, fireEvent, act} from '@testing-library/react'
import * as mediaUtils from '../../util/mediaUtils'
import Attachment from '../Attachment'

jest.useFakeTimers()

// EVAL-3907 - remove or rewrite to remove spies on imports
describe.skip('Attachment', () => {
  beforeEach(() => {
    mediaUtils.hasMediaFeature = jest.fn(() => true)
    mediaUtils.getUserMedia = jest.fn(() => Promise.resolve())
  })

  const getProps = (override = {}) => {
    return {
      index: 0,
      setBlob: jest.fn(),
      ...override,
    }
  }

  it('only displays LegacyFileUpload when hasMediaFeature is false', () => {
    mediaUtils.hasMediaFeature = jest.fn(() => false)
    const {queryByText, queryByTestId} = render(<Attachment {...getProps()} />)
    expect(queryByText('Upload File')).not.toBeInTheDocument()
    expect(queryByText('Use Webcam')).not.toBeInTheDocument()
    expect(queryByTestId('file-upload-0')).toBeInTheDocument()
  })

  it('shows Upload File and Use Webcam button', () => {
    const {getByText} = render(<Attachment {...getProps()} />)
    expect(getByText('Upload File')).toBeInTheDocument()
    expect(getByText('Use Webcam')).toBeInTheDocument()
  })

  it('shows LegacyFileUpload when click on Upload File', () => {
    const {getByTestId, getByText} = render(<Attachment {...getProps()} />)
    fireEvent.click(getByText('Upload File'))
    expect(getByTestId('file-upload-0')).toBeInTheDocument()
  })

  it('displays WebcamModal when click on Use Webcam', async () => {
    const {getByLabelText, getByText} = render(<Attachment {...getProps()} />)
    fireEvent.click(getByText('Use Webcam'))
    expect(getByLabelText('Webcam')).toBeInTheDocument()
    await act(() => mediaUtils.getUserMedia())
  })

  it('displays picture when user take and select picture and calls setBlob with blob', async () => {
    const mockedBlob = jest.mock()
    jest
      .spyOn(HTMLCanvasElement.prototype, 'toBlob')
      .mockImplementationOnce(callback => callback(mockedBlob))
    const props = getProps()
    const {getByText, getByAltText} = render(<Attachment {...props} />)
    fireEvent.click(getByText('Use Webcam'))
    await act(() => mediaUtils.getUserMedia())
    fireEvent.click(getByText('Take Photo'))
    fireEvent.click(getByText('Use This Photo'))
    expect(getByAltText('Captured Image')).toBeInTheDocument()
    expect(props.setBlob).toHaveBeenCalledWith(mockedBlob)
  })
})
