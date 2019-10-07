/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import fetchMock from 'fetch-mock'
import useContentShareUserSearchApi from 'jsx/shared/effects/useContentShareUserSearchApi'
import DirectShareUserModal from '../DirectShareUserModal'

jest.mock('jsx/shared/effects/useContentShareUserSearchApi')

describe('DirectShareUserModal', () => {
  let ariaLive

  beforeAll(() => {
    window.ENV = {COURSE_ID: '42'}
    ariaLive = document.createElement('div')
    ariaLive.id = 'flash_screenreader_holder'
    ariaLive.setAttribute('role', 'alert')
    document.body.appendChild(ariaLive)
  })

  afterAll(() => {
    delete window.ENV
    if (ariaLive) ariaLive.remove()
  })

  beforeEach(() => {
    jest.useFakeTimers()

    useContentShareUserSearchApi.mockImplementationOnce(({success}) => {
      success([{id: 'abc', display_name: 'abc'}, {id: 'cde', display_name: 'cde'}])
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('disables the send button immediately', () => {
    const {getByText} = render(<DirectShareUserModal open courseId="1" />)
    expect(
      getByText('Send')
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('enables the copy button when a user is selected', () => {
    const {getByText, getAllByText, getByLabelText} = render(
      <DirectShareUserModal open courseId="1" />
    )
    fireEvent.change(getByLabelText(/send to:/i), {target: {value: 'abc'}})
    act(() => jest.runAllTimers()) // let the debounce happen
    fireEvent.click(getByText('abc'))
    expect(
      getByText('Send')
        .closest('button')
        .getAttribute('disabled')
    ).toBe(null)
    // remove the selected user from the list
    fireEvent.click(getAllByText('abc')[1]) // first one is SR alert
    expect(
      getByText('Send')
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('disables the send button when a search has started', () => {
    const {getByText, getByLabelText} = render(<DirectShareUserModal open courseId="1" />)
    fireEvent.change(getByLabelText(/send to:/i), {target: {value: 'abc'}})
    act(() => jest.runAllTimers()) // let the debounce happen
    fireEvent.click(getByText('Send'))
    expect(
      getByText('Send')
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('starts a share operation and reports status', async () => {
    fetchMock.postOnce('path:/api/v1/users/self/content_shares', 200)
    const {getByText, getByLabelText} = render(
      <DirectShareUserModal
        open
        courseId="1"
        contentShare={{content_type: 'discussion_topic', content_id: '42'}}
      />
    )
    fireEvent.change(getByLabelText(/send to:/i), {target: {value: 'abc'}})
    act(() => jest.runAllTimers()) // let the debounce happen
    fireEvent.click(getByText('abc'))
    fireEvent.click(getByText('Send'))
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      receiver_ids: ['abc'],
      content_type: 'discussion_topic',
      content_id: '42'
    })
    expect(getByText(/start/i)).toBeInTheDocument()
    await act(() => fetchMock.flush(true))
    expect(getByText(/success/i)).toBeInTheDocument()
  })

  it('clears user selection when the modal is closed', async () => {
    fetchMock.get('*', [{id: 'abc', display_name: 'abc'}])
    const {queryByText, getByText, findByLabelText, rerender} = render(
      <DirectShareUserModal open />
    )
    const input = await findByLabelText('Send to:') // allow lazy code to load
    fireEvent.focus(input)
    fireEvent.change(input, {target: {value: 'abc'}})
    act(() => jest.runAllTimers()) // let the debounce happen
    await act(() => fetchMock.flush(true))
    fireEvent.click(getByText('abc'))
    rerender(<DirectShareUserModal open={false} />)
    rerender(<DirectShareUserModal open />)
    expect(queryByText('abc')).toBeNull()
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore() // eslint-disable-line no-console
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce('path:/api/v1/users/self/content_shares', 400)
      const {getByText, getByLabelText} = render(
        <DirectShareUserModal
          open
          courseId="1"
          contentShare={{content_type: 'discussion_topic', content_id: '42'}}
        />
      )
      fireEvent.change(getByLabelText(/send to:/i), {target: {value: 'abc'}})
      act(() => jest.runAllTimers()) // let the debounce happen
      fireEvent.click(getByText('abc'))
      fireEvent.click(getByText('Send'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/error/i)).toBeInTheDocument()
    })
  })
})
