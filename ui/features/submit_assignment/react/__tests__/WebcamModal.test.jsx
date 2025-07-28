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
import WebcamModal from '../WebcamModal'
import {render, fireEvent, act} from '@testing-library/react'

jest.useFakeTimers()

describe('WebcamModal', () => {
  let mockGetUserMedia
  let mockStream
  let mockVideoRef

  beforeEach(() => {
    mockStream = {
      getTracks: jest.fn(() => [{stop: jest.fn()}]),
    }
    mockGetUserMedia = jest.fn(() => Promise.resolve(mockStream))

    // Mock navigator.mediaDevices.getUserMedia
    Object.defineProperty(navigator, 'mediaDevices', {
      value: {
        getUserMedia: mockGetUserMedia,
      },
      writable: true,
    })

    // Mock video element
    mockVideoRef = {
      srcObject: null,
      videoWidth: 640,
      videoHeight: 480,
    }
    jest.spyOn(React, 'useRef').mockReturnValue({current: mockVideoRef})

    // Mock canvas methods
    jest.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue({
      drawImage: jest.fn(),
    })
    jest
      .spyOn(HTMLCanvasElement.prototype, 'toDataURL')
      .mockReturnValue('data:image/png;base64,mockData')
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.restoreAllMocks()
  })

  const getProps = (override = {}) => {
    return {
      onSelectImage: jest.fn(),
      onDismiss: jest.fn(),
      open: false,
      ...override,
    }
  }

  it('focus Take Photo and Use This Photo when showed', async () => {
    // Mock toBlob to call callback immediately
    jest.spyOn(HTMLCanvasElement.prototype, 'toBlob').mockImplementation(callback => {
      callback(new Blob(['test'], {type: 'image/png'}))
    })

    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
      await jest.runAllTimers()
    })

    // Verify Take Photo button exists and is visible
    const takePhotoButton = result.getByText('Take Photo').closest('button')
    expect(takePhotoButton).toBeInTheDocument()

    // Click Take Photo
    fireEvent.click(takePhotoButton)

    // Verify Use This Photo button exists and is visible
    const useThisPhotoButton = result.getByText('Use This Photo').closest('button')
    expect(useThisPhotoButton).toBeInTheDocument()
  })

  it('does not request webcam access if open false', () => {
    render(<WebcamModal {...getProps()} />)
    expect(mockGetUserMedia).not.toHaveBeenCalled()
  })

  it('requests webcam access if open is true', async () => {
    await act(async () => {
      render(<WebcamModal {...getProps({open: true})} />)
    })
    expect(mockGetUserMedia).toHaveBeenCalled()
  })

  it('renders Take Photo button', async () => {
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    expect(result.getByText('Take Photo')).toBeInTheDocument()
  })

  it('closes all tracks when prop open goes from true to false', async () => {
    const stop = jest.fn()
    mockStream.getTracks.mockReturnValue([{stop}])

    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    result.rerender(<WebcamModal {...getProps()} />)
    expect(stop).toHaveBeenCalled()
  })

  it('shows request message if user has not accepted yet', async () => {
    const sleep1s = new Promise(resolve => setTimeout(resolve, 1000))
    mockGetUserMedia.mockImplementationOnce(() => sleep1s)
    const {getByText} = render(<WebcamModal {...getProps({open: true})} />)

    act(() => jest.advanceTimersByTime(500))
    expect(getByText('Canvas needs acccess to your camera.')).toBeInTheDocument()
  })

  it('shows request message if user has declined', async () => {
    const fail = Promise.reject(new Error('fail'))
    mockGetUserMedia.mockImplementationOnce(() => fail)
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    expect(result.getByText('Canvas needs acccess to your camera.')).toBeInTheDocument()
  })

  it('displays Try Again button when granted and has already took picture', async () => {
    const mockedToBlob = jest.spyOn(HTMLCanvasElement.prototype, 'toBlob')
    mockedToBlob.mockImplementationOnce(callback =>
      callback(new Blob(['test'], {type: 'image/png'})),
    )
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    fireEvent.click(result.getByText('Take Photo'))
    expect(result.getByText('Try Again')).toBeInTheDocument()
    mockedToBlob.mockRestore()
  })

  it('calls onSelectImage passing blob and dataURL when select picture', async () => {
    const mockedBlob = new Blob(['test'], {type: 'image/png'})
    const mockedToBlob = jest.spyOn(HTMLCanvasElement.prototype, 'toBlob')
    mockedToBlob.mockImplementationOnce(callback => callback(mockedBlob))
    const props = getProps({open: true})
    let result
    await act(async () => {
      result = render(<WebcamModal {...props} />)
    })
    fireEvent.click(result.getByText('Take Photo'))
    fireEvent.click(result.getByText('Use This Photo'))
    expect(props.onSelectImage).toHaveBeenCalledWith(
      expect.objectContaining({
        blob: mockedBlob,
      }),
    )
    mockedToBlob.mockRestore()
  })
})
