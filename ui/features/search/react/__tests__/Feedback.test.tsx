/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {fireEvent, render, waitFor} from '@testing-library/react'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import Feedback from '../Feedback'

const server = setupServer()

const props = {
  courseId: '1',
  searchTerm: 'kittens',
}

describe('Feedback', () => {
  let capturedUrls: string[]

  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())

  beforeEach(() => {
    capturedUrls = []
    server.use(
      http.get(`/api/v1/courses/${props.courseId}/smartsearch/log`, ({request}) => {
        capturedUrls.push(request.url)
        return HttpResponse.json({})
      }),
    )
  })

  it('sends positive feedback', async () => {
    const {getByTestId} = render(<Feedback {...props} />)

    fireEvent.click(getByTestId('positive-feedback'))
    fireEvent.click(getByTestId('pf-close'))

    await waitFor(() => {
      expect(capturedUrls.length).toBeGreaterThan(0)
      const url = capturedUrls[capturedUrls.length - 1]
      const parsedUrl = new URL(url)
      const params = parsedUrl.searchParams
      expect(params.get('a')).toBe('LIKE')
      expect(params.get('q')).toBe('kittens')
      expect(params.get('c')).toBe('')
    })
  })

  it('sends negative feedback with no comments', async () => {
    const {getByTestId} = render(<Feedback {...props} />)

    fireEvent.click(getByTestId('negative-feedback'))
    fireEvent.click(getByTestId('nf-close'))

    await waitFor(() => {
      expect(capturedUrls.length).toBeGreaterThan(0)
      const url = capturedUrls[capturedUrls.length - 1]
      const parsedUrl = new URL(url)
      const params = parsedUrl.searchParams
      expect(params.get('a')).toBe('DISLIKE')
      expect(params.get('q')).toBe('kittens')
      expect(params.get('c')).toBe('')
    })
  })

  it('sends negative feedback with comments', async () => {
    const {getByLabelText, getByTestId} = render(<Feedback {...props} />)

    fireEvent.click(getByTestId('negative-feedback'))
    const textarea = getByLabelText('Additional Feedback')
    fireEvent.input(textarea, {target: {value: 'Not enough kittens'}})
    await waitFor(() => {
      expect(textarea).toHaveValue('Not enough kittens')
    })
    fireEvent.click(getByTestId('nf-submit'))

    await waitFor(() => {
      expect(capturedUrls.length).toBeGreaterThan(0)
      const url = capturedUrls[capturedUrls.length - 1]
      const parsedUrl = new URL(url)
      const params = parsedUrl.searchParams
      expect(params.get('a')).toBe('DISLIKE')
      expect(params.get('q')).toBe('kittens')
      expect(params.get('c')).toBe('Not enough kittens')
    })
  })
})
