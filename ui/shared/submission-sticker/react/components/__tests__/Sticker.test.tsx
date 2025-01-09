/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import Sticker from '../Sticker'
import type {StickerProps} from '../../types/stickers.d'

const renderComponent = (props: StickerProps) => {
  return render(<Sticker {...props} />)
}

describe('Sticker', () => {
  let props: StickerProps
  let liveRegion: HTMLElement

  beforeEach(() => {
    liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    document.body.appendChild(liveRegion)
  })

  afterEach(() => {
    liveRegion.remove()
    fetchMock.restore()
  })

  describe('when not editable', () => {
    beforeEach(() => {
      props = {
        editable: false,
        confetti: false,
        size: 'medium',
        submission: {
          assignmentId: '2',
          courseId: '3',
          sticker: 'grad',
          userId: '1',
        },
      }
    })

    it('renders an image', () => {
      const {getByTestId} = renderComponent(props)
      expect(getByTestId('sticker-image')).toBeInTheDocument()
    })

    it('does not render an image when the submission does not have a sticker', () => {
      props.submission.sticker = null
      const {queryByTestId} = renderComponent(props)
      expect(queryByTestId('sticker-image')).not.toBeInTheDocument()
    })

    it('does not render a button', () => {
      const {queryByTestId} = renderComponent(props)
      expect(queryByTestId('sticker-button')).not.toBeInTheDocument()
    })

    describe('when confetti is enabled', () => {
      beforeEach(() => {
        props.confetti = true
      })

      it('renders a button', () => {
        const {getByTestId} = renderComponent(props)
        expect(getByTestId('sticker-button')).toBeInTheDocument()
      })

      it('does not render a button when the submission does not have a sticker', () => {
        props.submission.sticker = null
        const {queryByTestId} = renderComponent(props)
        expect(queryByTestId('sticker-button')).not.toBeInTheDocument()
      })

      it('shows confetti when the button is clicked', () => {
        const {getByTestId} = renderComponent(props)
        const button = getByTestId('sticker-button')
        fireEvent.click(button)
        expect(getByTestId('confetti-explosion')).toBeInTheDocument()
      })

      it('does not show confetti prior to the button being clicked', () => {
        const {queryByTestId} = renderComponent(props)
        expect(queryByTestId('confetti-explosion')).not.toBeInTheDocument()
      })
    })
  })

  describe('when editable', () => {
    let baseUrl: string
    let updateUrl: string

    beforeEach(() => {
      props = {
        editable: true,
        confetti: false,
        size: 'medium',
        submission: {
          assignmentId: '2',
          courseId: '3',
          sticker: 'grad',
          userId: '1',
        },
      }

      baseUrl = `/api/v1/courses/${props.submission.courseId}/assignments/${props.submission.assignmentId}`
      updateUrl = `${baseUrl}/submissions/${props.submission.userId}`
    })

    it('renders a button', () => {
      const {getByTestId} = renderComponent(props)
      expect(getByTestId('sticker-button')).toBeInTheDocument()
    })

    it('renders a button with a default image when the submission has no sticker', () => {
      props.submission.sticker = null
      const {getByTestId} = renderComponent(props)
      expect(getByTestId('sticker-button')).toBeInTheDocument()
      expect(
        getByTestId((content, element) => {
          return (
            content === 'sticker-image' &&
            element?.getAttribute('alt') ===
              'A placeholder sticker with a smiley face and a plus sign.'
          )
        }),
      ).toBeInTheDocument()
    })

    it('does not show the edit icon overlay', () => {
      const {getByTestId} = renderComponent(props)
      const overlay = getByTestId('edit-icon-overlay')
      expect(overlay).not.toHaveClass('showing')
    })

    it('shows the edit icon overlay on button focus', () => {
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.focus(button)
      const overlay = getByTestId('edit-icon-overlay')
      expect(overlay).toHaveClass('showing')
    })

    it('hides the edit icon overlay on button blur', () => {
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.focus(button)
      fireEvent.blur(button)
      const overlay = getByTestId('edit-icon-overlay')
      expect(overlay).not.toHaveClass('showing')
    })

    it('shows the edit icon overlay on button hover', () => {
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.mouseEnter(button)
      const overlay = getByTestId('edit-icon-overlay')
      expect(overlay).toHaveClass('showing')
    })

    it('hides the edit icon overlay when no longer hovering on the button', () => {
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.mouseEnter(button)
      fireEvent.mouseLeave(button)
      const overlay = getByTestId('edit-icon-overlay')
      expect(overlay).not.toHaveClass('showing')
    })

    it('does not show the modal prior to clicking the trigger', () => {
      const {queryByTestId} = renderComponent(props)
      expect(queryByTestId('sticker-modal')).not.toBeInTheDocument()
    })

    it('shows the modal on button click', () => {
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.click(button)
      expect(getByTestId('sticker-modal')).toBeInTheDocument()
    })

    it('optimistically updates the sticker', async () => {
      fetchMock.put(updateUrl, {status: 200, body: {...props.submission, sticker: 'book'}})
      props.onStickerChange = jest.fn()
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.click(button)
      const newSticker = getByTestId((content, element) => {
        return (
          content === 'sticker-image' &&
          element?.getAttribute('alt') === 'A sticker with a picture of a book.'
        )
      })
      fireEvent.click(newSticker)
      await fetchMock.flush(true)

      expect(props.onStickerChange).toHaveBeenCalledTimes(1)
      expect(props.onStickerChange).toHaveBeenLastCalledWith('book')
    })

    it('reverts back to the original sticker if the update fails', async () => {
      fetchMock.put(updateUrl, 404)
      props.onStickerChange = jest.fn()
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.click(button)
      const newSticker = getByTestId((content, element) => {
        return (
          content === 'sticker-image' &&
          element?.getAttribute('alt') === 'A sticker with a picture of a book.'
        )
      })
      fireEvent.click(newSticker)
      await fetchMock.flush(true)

      expect(props.onStickerChange).toHaveBeenCalledTimes(2)
      expect(props.onStickerChange).toHaveBeenNthCalledWith(1, 'book')
      expect(props.onStickerChange).toHaveBeenNthCalledWith(2, 'grad')
    })

    it('works with anonymous assignments', async () => {
      props.submission = {
        anonymousId: '6D5Ys',
        assignmentId: '2',
        courseId: '3',
        sticker: 'grad',
      }
      props.onStickerChange = jest.fn()
      const anonymousUpdateUrl = `${baseUrl}/anonymous_submissions/${props.submission.anonymousId}`
      fetchMock.put(anonymousUpdateUrl, {status: 200, body: {...props.submission, sticker: 'book'}})
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.click(button)
      const newSticker = getByTestId((content, element) => {
        return (
          content === 'sticker-image' &&
          element?.getAttribute('alt') === 'A sticker with a picture of a book.'
        )
      })
      fireEvent.click(newSticker)
      await fetchMock.flush(true)

      expect(props.onStickerChange).toHaveBeenCalledTimes(1)
      expect(props.onStickerChange).toHaveBeenLastCalledWith('book')
    })

    it('removes stickers', async () => {
      fetchMock.put(updateUrl, {status: 200, body: {...props.submission, sticker: null}})
      props.onStickerChange = jest.fn()
      const {getByTestId} = renderComponent(props)
      const button = getByTestId('sticker-button')
      fireEvent.click(button)
      const removeStickerButton = getByTestId('sticker-remove')
      fireEvent.click(removeStickerButton)
      await fetchMock.flush(true)

      expect(props.onStickerChange).toHaveBeenCalledTimes(1)
      expect(props.onStickerChange).toHaveBeenLastCalledWith(null)
    })
  })
})
