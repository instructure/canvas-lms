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
import {fireEvent, render, screen} from '@testing-library/react'
import WebcamCapture from '../WebcamCapture'

const onSelectImage = jest.fn()
const defaultProps = (props = {}) => ({
  onSelectImage,
  ...props,
})
const renderWebcamCapture = (props = {}) => render(<WebcamCapture {...defaultProps(props)} />)

describe('WebcamCapture', () => {
  let fakeStream
  let getUserMedia
  let tracks

  beforeEach(() => {
    jest.useFakeTimers()

    tracks = {forEach: jest.fn()}
    fakeStream = {
      getTracks: () => tracks,
      clientWidth: 640,
      clientHeight: 480,
    }
    getUserMedia = jest.fn()
    navigator.mediaDevices = {getUserMedia}
    HTMLCanvasElement.prototype.getContext = () => ({
      drawImage: jest.fn(),
    })
    HTMLCanvasElement.prototype.toDataURL = jest.fn().mockReturnValue('data:image/png;base64,')
    HTMLCanvasElement.prototype.toBlob = jest.fn().mockImplementation(cb => cb(new Blob()))
  })

  afterEach(() => {
    jest.resetAllMocks()
    jest.runAllTimers()
    delete navigator.mediaDevices
  })

  it('shows a message indicating it needs permission to access the camera after a brief delay', () => {
    getUserMedia.mockImplementation(() => new Promise(() => {}))
    renderWebcamCapture()

    jest.advanceTimersByTime(1000)

    expect(screen.getByText(/Canvas needs access to your camera/)).toBeInTheDocument()
  })

  it('continues to say it needs webcam access if the user does not grant permission', async () => {
    getUserMedia.mockRejectedValue(new Error('NO'))
    renderWebcamCapture()

    expect(await screen.findByText(/Canvas needs access to your camera/)).toBeInTheDocument()
  })

  describe('when permission has been granted', () => {
    beforeEach(() => {
      getUserMedia.mockResolvedValue(fakeStream)
    })

    it('shows a video feed', async () => {
      renderWebcamCapture()

      expect(await screen.findByTestId('webcam-capture-video')).toBeVisible()
    })

    it('shows a button to take a photo', async () => {
      renderWebcamCapture()

      expect(
        await screen.findByRole('button', {
          name: /take photo/i,
        })
      ).toBeInTheDocument()
    })

    it('shows a countdown when the user clicks the "record" button', async () => {
      renderWebcamCapture()

      const recordButton = await screen.findByRole('button', {
        name: /take photo/i,
      })

      fireEvent.click(recordButton)

      expect(await screen.findByTestId('webcam-countdown-container')).toBeInTheDocument()
    })

    describe('when the user takes a photo and the countdown has completed', () => {
      const renderAndTakePhoto = async () => {
        const wrapper = renderWebcamCapture()
        const recordButton = await screen.findByRole('button', {
          name: /take photo/i,
        })

        fireEvent.click(recordButton)
        await screen.findByTestId('webcam-countdown-container')
        jest.advanceTimersByTime(10000)

        return {...wrapper}
      }

      it('no longer shows the video feed', async () => {
        await renderAndTakePhoto()

        expect(screen.queryByTestId('webcam-capture-video')).not.toBeVisible()
      })

      it('shows an image containing the photo that was taken', async () => {
        await renderAndTakePhoto()

        expect(await screen.findByAltText('Captured Image')).toBeInTheDocument()
      })

      it('shows a text field to rename the image', async () => {
        await renderAndTakePhoto()

        expect(await screen.findByRole('textbox')).toBeInTheDocument()
      })

      it('populates the text field with a default name for the file', async () => {
        await renderAndTakePhoto()

        expect(await screen.findByRole('textbox')).toHaveValue('webcam-picture.png')
      })

      it('shows a "Start Over" button', async () => {
        await renderAndTakePhoto()

        expect(await screen.findByRole('button', {name: 'Start Over'})).toBeInTheDocument()
      })

      it('returns the user to the video feed if the "Start Over" button is clicked', async () => {
        await renderAndTakePhoto()

        const startOverButton = await screen.findByRole('button', {name: 'Start Over'})

        fireEvent.click(startOverButton)

        expect(await screen.findByTestId('webcam-capture-video')).toBeVisible()
      })

      it('shows a "Save" button', async () => {
        await renderAndTakePhoto()

        expect(await screen.findByRole('button', {name: 'Save'})).toBeInTheDocument()
      })

      it('calls the onSelectImage prop when the user clicks the "Save" button', async () => {
        await renderAndTakePhoto()
        const saveButton = await screen.findByRole('button', {name: 'Save'})

        fireEvent.click(saveButton)

        expect(onSelectImage).toHaveBeenCalledTimes(1)
      })

      it('passes the filename specified by the user as the "filename" prop to onSelectImage', async () => {
        await renderAndTakePhoto()

        const filenameInput = await screen.findByRole('textbox')

        fireEvent.change(filenameInput, {target: {value: 'not-a-webcam-picture.png'}})

        const saveButton = await screen.findByRole('button', {name: 'Save'})

        fireEvent.click(saveButton)

        expect(onSelectImage).toHaveBeenCalledWith(
          expect.objectContaining({filename: 'not-a-webcam-picture.png'})
        )
      })

      it('passes an "image" prop to onSelectImage containing the captured blob and URL', async () => {
        await renderAndTakePhoto()
        const saveButton = await screen.findByRole('button', {name: 'Save'})

        fireEvent.click(saveButton)

        const [{image}] = onSelectImage.mock.calls[0]

        expect(image.blob).toBeDefined()
        expect(image.dataURL).toBeDefined()
      })
    })
  })
})
