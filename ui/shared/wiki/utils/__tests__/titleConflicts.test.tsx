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
import {
  conflictMessage,
  generateUrl,
  fetchTitleAvailability,
  checkForTitleConflict,
} from '../titleConflicts'
import fetchMock from 'fetch-mock'
import {render} from '@testing-library/react'

describe('titleConflicts', () => {
  beforeEach(() => {
    window.ENV.TITLE_AVAILABILITY_PATH = '/title_availability'
    window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'https://canvas.com'
    window.ENV.context_asset_string = 'course_1'
    expect.hasAssertions()
  })

  describe('conflictMessage', () => {
    it('returns the correct message for courses', () => {
      const {getByTestId, getByText} = render(<>{conflictMessage().text}</>)
      expect(getByTestId('warning-icon')).toBeInTheDocument()
      expect(
        getByText('There is already a page in this course with this title.')
      ).toBeInTheDocument()
    })

    it('returns the correct message for groups', () => {
      window.ENV.context_asset_string = 'group_1'
      const {getByTestId, getByText} = render(<>{conflictMessage().text}</>)
      expect(getByTestId('warning-icon')).toBeInTheDocument()
      expect(
        getByText('There is already a page in this group with this title.')
      ).toBeInTheDocument()
    })
  })

  describe('generateUrl', () => {
    it('generates the correct url with the provided title', () => {
      const title = 'i like dogs'
      const url = new URL(generateUrl(title))
      expect(url.origin).toEqual(window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN)
      expect(url.pathname).toEqual(window.ENV.TITLE_AVAILABILITY_PATH)
      expect(url.searchParams).toEqual(new URLSearchParams({title}))
    })

    it('throws an error if TITLE_AVAILABILITY_PATH is not set', () => {
      window.ENV.TITLE_AVAILABILITY_PATH = undefined
      expect(() => generateUrl('i like dogs')).toThrow('Title availability path required')
    })
  })

  describe('fetchTitleAvailability', () => {
    beforeEach(() => {
      fetchMock.reset()
    })

    it('returns true if the title is already used', async () => {
      const title = 'anything'
      fetchMock.get(generateUrl(title), JSON.stringify({conflict: true}))
      const result = await fetchTitleAvailability(title)
      expect(result).toEqual(true)
    })

    it('returns false if the title is unused', async () => {
      const title = 'something else'
      fetchMock.get(generateUrl(title), JSON.stringify({conflict: false}))
      const result = await fetchTitleAvailability(title)
      expect(result).toEqual(false)
    })

    it('throws an error if the response is not ok', async () => {
      const title = 'uh oh'
      const message = 'not found'
      const body = JSON.stringify({errors: [{message}]})
      fetchMock.get(generateUrl(title), {status: 404, body})
      await expect(fetchTitleAvailability(title)).rejects.toThrow(message)
    })
  })

  describe('checkForTitleConflict', () => {
    const mockCallback = jest.fn()

    beforeEach(() => {
      fetchMock.reset()
      mockCallback.mockReset()
    })

    it('calls the callback with the conflict message if the title is already used', async () => {
      const title = 'anything'
      fetchMock.get(generateUrl(title), JSON.stringify({conflict: true}))
      await checkForTitleConflict(title, mockCallback)
      expect(mockCallback).toHaveBeenCalledWith([conflictMessage()])
    })

    it('calls the callback with [] if the title is unused', async () => {
      const title = 'something else'
      fetchMock.get(generateUrl(title), JSON.stringify({conflict: false}))
      await checkForTitleConflict(title, mockCallback)
      expect(mockCallback).toHaveBeenCalledWith([])
    })

    it('calls the callback with [] if the response is not ok', async () => {
      const title = 'uh oh'
      const body = JSON.stringify({errors: [{message: 'not found'}]})
      fetchMock.get(generateUrl(title), {status: 404, body})
      await checkForTitleConflict(title, mockCallback)
      expect(mockCallback).toHaveBeenCalledWith([])
    })
  })
})
