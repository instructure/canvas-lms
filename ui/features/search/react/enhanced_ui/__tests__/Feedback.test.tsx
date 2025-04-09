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
import Feedback from '../Feedback'
import fetchMock from 'fetch-mock'

const props = {
  courseId: '1',
  searchTerm: 'kittens',
}

describe('Feedback', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('sends positive feedback', async () => {
    fetchMock.get(`begin:/api/v1/courses/${props.courseId}/smartsearch/log`, {})
    const {getByTestId} = render(<Feedback {...props} />)

    fireEvent.click(getByTestId('positive-feedback'))
    fireEvent.click(getByTestId('pf-close'))

    await waitFor(() => {
      expect(
        fetchMock.called(url => {
          const parsedUrl = new URL(url, window.location.href)
          const params = parsedUrl.searchParams
          return (
            params.get('a') === 'LIKE' && params.get('q') === 'kittens' && params.get('c') === ''
          )
        }),
      ).toBe(true)
    })
  })

  it('sends negative feedback with no comments', async () => {
    fetchMock.get(`begin:/api/v1/courses/${props.courseId}/smartsearch/log`, {})
    const {getByTestId} = render(<Feedback {...props} />)

    fireEvent.click(getByTestId('negative-feedback'))
    fireEvent.click(getByTestId('nf-close'))

    await waitFor(() => {
      expect(
        fetchMock.called(url => {
          const parsedUrl = new URL(url, window.location.href)
          const params = parsedUrl.searchParams
          return (
            params.get('a') === 'DISLIKE' && params.get('q') === 'kittens' && params.get('c') === ''
          )
        }),
      ).toBe(true)
    })
  })

  it('sends negative feedback with comments', async () => {
    fetchMock.get(`begin:/api/v1/courses/${props.courseId}/smartsearch/log`, {})
    const {getByLabelText, getByTestId} = render(<Feedback {...props} />)

    fireEvent.click(getByTestId('negative-feedback'))
    const textarea = getByLabelText('Additional Feedback')
    fireEvent.input(textarea, {target: {value: 'Not enough kittens'}})
    await waitFor(() => {
      expect(textarea).toHaveValue('Not enough kittens')
    })
    fireEvent.click(getByTestId('nf-submit'))

    await waitFor(() => {
      expect(
        fetchMock.called(url => {
          const parsedUrl = new URL(url, window.location.href)
          const params = parsedUrl.searchParams
          return (
            params.get('a') === 'DISLIKE' &&
            params.get('q') === 'kittens' &&
            params.get('c') === 'Not enough kittens'
          )
        }),
      ).toBe(true)
    })
  })
})
