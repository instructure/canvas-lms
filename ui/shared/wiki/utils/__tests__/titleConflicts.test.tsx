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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import {render} from '@testing-library/react'

const server = setupServer()

describe('titleConflicts', () => {
  beforeAll(() => server.listen())
  afterAll(() => server.close())

  beforeEach(() => {
    window.ENV.TITLE_AVAILABILITY_PATH = '/title_availability'
    window.ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN = 'https://canvas.com'
    window.ENV.context_asset_string = 'course_1'
    expect.hasAssertions()
  })

  afterEach(() => {
    server.resetHandlers()
  })

  describe('conflictMessage', () => {
    it('returns the correct message for courses', () => {
      const {getByTestId, getByText} = render(<>{conflictMessage().text}</>)
      expect(getByTestId('warning-icon')).toBeInTheDocument()
      expect(
        getByText(
          'There is already a page in this course with this title. Hitting save will create a duplicate.',
        ),
      ).toBeInTheDocument()
    })

    it('returns the correct message for groups', () => {
      window.ENV.context_asset_string = 'group_1'
      const {getByTestId, getByText} = render(<>{conflictMessage().text}</>)
      expect(getByTestId('warning-icon')).toBeInTheDocument()
      expect(
        getByText(
          'There is already a page in this group with this title. Hitting save will create a duplicate.',
        ),
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
    it('returns true if the title is already used', async () => {
      const title = 'anything'
      server.use(
        http.get('https://canvas.com/title_availability', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('title') === title) {
            return HttpResponse.json({conflict: true})
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
      const result = await fetchTitleAvailability(title)
      expect(result).toEqual(true)
    })

    it('returns false if the title is unused', async () => {
      const title = 'something else'
      server.use(
        http.get('https://canvas.com/title_availability', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('title') === title) {
            return HttpResponse.json({conflict: false})
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
      const result = await fetchTitleAvailability(title)
      expect(result).toEqual(false)
    })

    it('throws an error if the response is not ok', async () => {
      const title = 'uh oh'
      const message = 'not found'
      server.use(
        http.get('https://canvas.com/title_availability', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('title') === title) {
            return HttpResponse.json({errors: [{message}]}, {status: 404})
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
      await expect(fetchTitleAvailability(title)).rejects.toThrow(message)
    })
  })

  describe('checkForTitleConflict', () => {
    const mockCallback = vi.fn()

    beforeEach(() => {
      mockCallback.mockReset()
    })

    it('calls the callback with the conflict message if the title is already used', async () => {
      const title = 'anything'
      server.use(
        http.get('https://canvas.com/title_availability', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('title') === title) {
            return HttpResponse.json({conflict: true})
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
      await checkForTitleConflict(title, mockCallback)
      expect(mockCallback).toHaveBeenCalledWith(
        expect.arrayContaining([
          expect.objectContaining({
            text: expect.anything(),
            type: 'hint',
          }),
        ]),
      )
    })

    it('calls the callback with [] if the title is unused', async () => {
      const title = 'something else'
      server.use(
        http.get('https://canvas.com/title_availability', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('title') === title) {
            return HttpResponse.json({conflict: false})
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
      await checkForTitleConflict(title, mockCallback)
      expect(mockCallback).toHaveBeenCalledWith([])
    })

    it('calls the callback with [] if the response is not ok', async () => {
      const consoleLogSpy = vi.spyOn(console, 'log').mockImplementation(() => {})
      const title = 'uh oh'
      server.use(
        http.get('https://canvas.com/title_availability', ({request}) => {
          const url = new URL(request.url)
          if (url.searchParams.get('title') === title) {
            return HttpResponse.json({errors: [{message: 'not found'}]}, {status: 404})
          }
          return new HttpResponse(null, {status: 404})
        }),
      )
      await checkForTitleConflict(title, mockCallback)
      expect(mockCallback).toHaveBeenCalledWith([])
      consoleLogSpy.mockRestore()
    })
  })
})
