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

import {act, fireEvent, render, waitFor} from '@testing-library/react'
import React from 'react'
import WebcamCapture from '../WebcamCapture'

describe('WebcamCapture', () => {
  let fakeStream
  let getUserMedia
  let onSelectImage
  let tracks

  beforeEach(() => {
    jest.useFakeTimers()

    onSelectImage = jest.fn()

    getUserMedia = jest.fn()
    tracks = [{stop: jest.fn()}]
    fakeStream = {getTracks: () => tracks}

    navigator.mediaDevices = {getUserMedia}
  })

  afterEach(async () => {
    await act(async () => {
      jest.runAllTimers()
    })
    delete navigator.mediaDevices
  })

  it('shows a message indicating it needs permission to access the camera after a brief delay', () => {
    getUserMedia.mockImplementation(() => new Promise(() => {}))
    const {getByText} = render(<WebcamCapture onSelectImage={onSelectImage} />)
    act(() => {
      jest.advanceTimersByTime(1000)
    })
    expect(getByText(/Canvas needs access to your camera/)).toBeInTheDocument()
  })

  it('continues to say it needs webcam access if the user does not grant permission', async () => {
    getUserMedia.mockRejectedValue(new Error('NO'))
    const {getByText} = render(<WebcamCapture onSelectImage={onSelectImage} />)

    await waitFor(() => {
      expect(getByText(/Canvas needs access to your camera/)).toBeInTheDocument()
    })
  })

  describe('when permission has been granted', () => {
    beforeEach(() => {
      getUserMedia.mockResolvedValue(fakeStream)
    })

    it('shows a video feed', async () => {
      const {getByTestId} = render(<WebcamCapture onSelectImage={onSelectImage} />)
      await waitFor(() => {
        expect(getByTestId('webcam-capture-video')).toBeVisible()
      })
    })

    it('shows a button to take a photo', async () => {
      const {findByRole} = render(<WebcamCapture onSelectImage={onSelectImage} />)
      expect(await findByRole('button', {name: 'Take Photo'})).toBeInTheDocument()
    })

    it('shows a countdown when the user clicks the "record" button', async () => {
      const {findByRole, findByTestId} = render(<WebcamCapture onSelectImage={onSelectImage} />)

      const recordButton = await findByRole('button', {name: 'Take Photo'})
      act(() => {
        fireEvent.click(recordButton)
      })

      expect(await findByTestId('webcam-countdown-container')).toBeInTheDocument()
    })

    describe('when the user takes a photo and the countdown has completed', () => {
      const renderAndTakePhoto = async () => {
        const renderResult = render(<WebcamCapture onSelectImage={onSelectImage} />)
        const recordButton = await renderResult.findByRole('button', {name: 'Take Photo'})
        fireEvent.click(recordButton)

        act(() => {
          jest.advanceTimersByTime(10000)
        })

        return renderResult
      }

      it('no longer shows the video feed', async () => {
        const {getByTestId} = await renderAndTakePhoto()
        expect(getByTestId('webcam-capture-video')).not.toBeVisible()
      })

      it('shows an image containing the photo that was taken', async () => {
        const {getByAltText} = await renderAndTakePhoto()
        expect(getByAltText('Captured Image')).toBeInTheDocument()
      })

      it('shows a text field to rename the image', async () => {
        const {getByRole} = await renderAndTakePhoto()
        expect(getByRole('textbox')).toBeInTheDocument()
      })

      it('populates the text field with a default name for the file', async () => {
        const {getByRole} = await renderAndTakePhoto()
        const textInput = getByRole('textbox')
        expect(textInput).toHaveValue('webcam-picture.png')
      })

      it('shows a "Start Over" button', async () => {
        const {getByRole} = await renderAndTakePhoto()
        expect(getByRole('button', {name: 'Start Over'})).toBeInTheDocument()
      })

      it('returns the user to the video feed if the "Start Over" button is clicked', async () => {
        const {getByRole, getByTestId} = await renderAndTakePhoto()
        const startOverButton = getByRole('button', {name: 'Start Over'})
        fireEvent.click(startOverButton)

        expect(getByTestId('webcam-capture-video')).toBeVisible()
      })

      it('shows a "Save" button', async () => {
        const {getByRole} = await renderAndTakePhoto()
        expect(getByRole('button', {name: 'Save'})).toBeInTheDocument()
      })

      it('calls the onSelectImage prop when the user clicks the "Save" button', async () => {
        const {getByRole} = await renderAndTakePhoto()
        const saveButton = getByRole('button', {name: 'Save'})
        fireEvent.click(saveButton)

        expect(onSelectImage).toHaveBeenCalledTimes(1)
      })

      it('passes the filename specified by the user as the "filename" prop to onSelectImage', async () => {
        const {getByRole} = await renderAndTakePhoto()

        const filenameInput = getByRole('textbox')
        fireEvent.change(filenameInput, {target: {value: 'not-a-webcam-picture.png'}})
        const saveButton = getByRole('button', {name: 'Save'})
        fireEvent.click(saveButton)

        expect(onSelectImage).toHaveBeenCalledWith(
          expect.objectContaining({filename: 'not-a-webcam-picture.png'})
        )
      })

      it('passes an "image" prop to onSelectImage containing the captured blob and URL', async () => {
        const {getByRole} = await renderAndTakePhoto()

        const saveButton = getByRole('button', {name: 'Save'})
        fireEvent.click(saveButton)

        const [{image}] = onSelectImage.mock.calls[0]
        expect(image.blob).toBeDefined()
        expect(image.dataURL).toBeDefined()
      })
    })
  })
})
