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
import useContentShareUserSearchApi from '../../effects/useContentShareUserSearchApi'
import DirectShareUserModal from '../DirectShareUserModal'

jest.mock('../../effects/useContentShareUserSearchApi')

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
      success([
        {id: 'abc', name: 'abc'},
        {id: 'cde', name: 'cde'}
      ])
    })
  })

  afterEach(() => {
    fetchMock.restore()
  })

  function selectUser(getByText, getByLabelText, name = 'abc') {
    fireEvent.change(getByLabelText(/send to:/i), {target: {value: name}})
    act(() => jest.runAllTimers()) // let the debounce happen
    fireEvent.click(getByText(name))
  }

  it('disables the send button immediately', () => {
    const {getByText} = render(<DirectShareUserModal open courseId="1" />)
    expect(
      getByText('Send')
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('enables the send button only when a user is selected', () => {
    const {getByText, getAllByText, getByLabelText} = render(
      <DirectShareUserModal open courseId="1" />
    )
    selectUser(getByText, getByLabelText)
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
    selectUser(getByText, getByLabelText)
    fireEvent.click(getByText('Send'))
    expect(
      getByText('Send')
        .closest('button')
        .getAttribute('disabled')
    ).toBe('')
  })

  it('starts a share operation and reports status', async () => {
    fetchMock.postOnce('path:/api/v1/users/self/content_shares', 200)
    const onDismiss = jest.fn()
    const {getByText, getAllByText, getByLabelText} = render(
      <DirectShareUserModal
        open
        courseId="1"
        contentShare={{content_type: 'discussion_topic', content_id: '42'}}
        onDismiss={onDismiss}
      />
    )
    selectUser(getByText, getByLabelText)
    fireEvent.click(getByText('Send'))
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      receiver_ids: ['abc'],
      content_type: 'discussion_topic',
      content_id: '42'
    })
    expect(getAllByText(/start/i)).not.toHaveLength(0)
    await act(() => fetchMock.flush(true))
    expect(getAllByText(/success/i)).toHaveLength(2) // visible and sr alert
    expect(onDismiss).toHaveBeenCalled()
  })

  it('clears user selection when the modal is closed', async () => {
    fetchMock.get('*', [{id: 'abc', name: 'abc'}])
    const {queryByText, getByText, getByLabelText, rerender} = render(
      <DirectShareUserModal open courseId="1" />
    )
    selectUser(getByText, getByLabelText)
    rerender(<DirectShareUserModal open={false} courseId="1" />)
    rerender(<DirectShareUserModal open courseId="1" />)
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
      selectUser(getByText, getByLabelText)
      fireEvent.click(getByText('Send'))
      await act(() => fetchMock.flush(true))
      expect(getByText(/error/i)).toBeInTheDocument()
      expect(
        getByText('Send')
          .closest('button')
          .getAttribute('disabled')
      ).toBeNull()
    })
  })
})
