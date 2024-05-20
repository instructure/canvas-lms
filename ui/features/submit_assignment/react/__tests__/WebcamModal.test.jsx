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
import * as mediaUtils from '../../util/mediaUtils'

jest.useFakeTimers()

// EVAL-3907 - remove or rewrite to remove spies on imports
describe.skip('WebcamModal', () => {
  beforeEach(() => {
    mediaUtils.getUserMedia = jest.fn(() => Promise.resolve())
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
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    await act(async () => jest.runAllTimers())
    expect(result.getByText('Take Photo').closest('button')).toHaveFocus()
    fireEvent.click(result.getByText('Take Photo'))
    await act(async () => jest.runAllTimers())
    expect(result.getByText('Use This Photo').closest('button')).toHaveFocus()
  })

  it('does not request webcam access if open false', () => {
    render(<WebcamModal {...getProps()} />)
    expect(mediaUtils.getUserMedia).not.toHaveBeenCalled()
  })

  it('requests webcam access if open is true', async () => {
    await act(async () => {
      render(<WebcamModal {...getProps({open: true})} />)
    })
    expect(mediaUtils.getUserMedia).toHaveBeenCalled()
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
    mediaUtils.getUserMedia = jest.fn(() =>
      Promise.resolve({
        getTracks: () => [{stop}],
      })
    )
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    result.rerender(<WebcamModal {...getProps()} />)
    expect(stop).toHaveBeenCalled()
  })

  it('shows request message if user has not accepted yet', async () => {
    const sleep1s = new Promise(resolve => setTimeout(resolve, 1000))
    mediaUtils.getUserMedia.mockImplementationOnce(() => sleep1s)
    const {getByText} = render(<WebcamModal {...getProps({open: true})} />)

    act(() => jest.advanceTimersByTime(500))
    expect(getByText('Canvas needs acccess to your camera.')).toBeInTheDocument()
  })

  it('shows request message if user has declined', async () => {
    const fail = Promise.reject(new Error('fail'))
    mediaUtils.getUserMedia.mockImplementationOnce(() => fail)
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    expect(result.getByText('Canvas needs acccess to your camera.')).toBeInTheDocument()
  })

  it('displays Try Again button when granted and has already took picture', async () => {
    const mockedToBlob = jest.spyOn(HTMLCanvasElement.prototype, 'toBlob')
    mockedToBlob.mockImplementationOnce(callback => callback())
    let result
    await act(async () => {
      result = render(<WebcamModal {...getProps({open: true})} />)
    })
    fireEvent.click(result.getByText('Take Photo'))
    expect(result.getByText('Try Again')).toBeInTheDocument()
  })

  it('calls onSelectImage passing blob and dataURL when select picture', async () => {
    const mockedBlob = jest.mock()
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
      })
    )
  })
})
