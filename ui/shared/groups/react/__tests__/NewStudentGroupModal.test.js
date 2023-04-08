// Copyright (C) 2021 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import stubEnv from '@canvas/stub-env'
import User from '@canvas/users/backbone/models/User'
import UserCollection from '@canvas/users/backbone/collections/UserCollection'
import NewStudentGroupModal from '../NewStudentGroupModal'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

describe('NewStudentGroupModal', () => {
  const loadMore = jest.fn()
  const onSave = jest.fn()
  const onDismiss = jest.fn()
  const open = true
  const user = new User({id: '1', name: 'Student'})
  const userCollection = new UserCollection([user])

  userCollection.toJSON = jest.fn(() => [{id: '1', name: 'Student'}])

  stubEnv({
    current_user_id: '2',
    course_id: '1',
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders form fields', () => {
    const {queryByLabelText, queryByPlaceholderText} = render(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={open}
        onDismiss={onDismiss}
      />
    )
    expect(queryByLabelText(/New Student Group/i)).toBeVisible()
    expect(queryByLabelText(/Group Name/i)).toBeVisible()
    expect(queryByLabelText(/Joining/i)).toBeVisible()
    expect(queryByLabelText(/Invite Students/i)).toBeVisible()
    expect(queryByPlaceholderText(/Search/i)).toBeVisible()
  })

  it('renders modular footer', () => {
    const {getByText} = render(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={open}
        onDismiss={onDismiss}
      />
    )
    expect(getByText(/Submit/i)).toBeVisible()
    expect(getByText(/Cancel/i)).toBeVisible()
  })

  it('clears prior state if modal is closed', () => {
    const {getByText, getByLabelText, rerender} = render(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={open}
        onDismiss={onDismiss}
      />
    )
    fireEvent.input(getByLabelText('Group Name'), {
      target: {value: 'Dat new new'},
    })
    expect(getByLabelText('Group Name')).toHaveValue('Dat new new')
    fireEvent.click(getByText('Cancel'))
    rerender(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={false}
        onDismiss={onDismiss}
      />
    )
    expect(getByLabelText('Group Name')).toHaveValue('')
  })

  it('disables the submit button if group name is not provided', () => {
    const {getByText} = render(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={open}
        onDismiss={onDismiss}
      />
    )
    expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeTruthy()
  })

  it('enables the submit button if group name is provided', () => {
    const {getByText, getByLabelText} = render(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={open}
        onDismiss={onDismiss}
      />
    )
    fireEvent.input(getByLabelText('Group Name'), {
      target: {value: 'name'},
    })
    expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeFalsy()
  })

  it('fetches and reports status', async () => {
    fetchMock.postOnce(`path:/courses/${ENV.course_id}/groups`, 200)
    const {getByText, getByRole, getAllByText, getByLabelText} = render(
      <NewStudentGroupModal
        userCollection={userCollection}
        loadMore={loadMore}
        onSave={onSave}
        open={open}
        onDismiss={onDismiss}
      />
    )
    fireEvent.input(getByLabelText('Group Name'), {
      target: {value: 'name'},
    })
    fireEvent.click(getByRole('combobox', {name: 'Invite Students'}))
    fireEvent.click(getByRole('option', {name: 'Student'}))
    fireEvent.click(getByText('Submit'))
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      group: {
        join_level: 'parent_context_auto_join',
        name: 'name',
      },
      invitees: ['1'],
    })
    expect(getAllByText(/Saving group/i)).toBeTruthy()
    await fetchMock.flush(true)
    expect(getAllByText(/Created group/i)).toBeTruthy()
    expect(onDismiss).toHaveBeenCalled()
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore() // eslint-disable-line no-console
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce(`path:/courses/${ENV.course_id}/groups`, 400)
      const {getByText, getAllByText, getByLabelText} = render(
        <NewStudentGroupModal
          userCollection={userCollection}
          loadMore={loadMore}
          onSave={onSave}
          open={open}
          onDismiss={onDismiss}
        />
      )
      fireEvent.input(getByLabelText('Group Name'), {
        target: {value: 'name'},
      })
      fireEvent.click(getByText('Submit'))
      await fetchMock.flush(true)
      expect(getAllByText(/error/i)).toBeTruthy()
    })
  })
})
