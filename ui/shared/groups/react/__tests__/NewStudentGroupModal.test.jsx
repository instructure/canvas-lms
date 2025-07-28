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
import {render, fireEvent, waitFor, screen} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import stubEnv from '@canvas/stub-env'
import User from '@canvas/users/backbone/models/User'
import NewStudentGroupModal from '../NewStudentGroupModal'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

const defaultProps = {
  open: true,
  onSave: jest.fn(),
  onDismiss: jest.fn(),
}

const renderComponent = (props = {}) => {
  return render(<NewStudentGroupModal {...defaultProps} {...props} />)
}

describe('NewStudentGroupModal', () => {
  stubEnv({
    current_user_id: '2',
    course_id: '1',
  })

  beforeEach(() => {
    fetchMock.get(
      `/api/v1/courses/${ENV.course_id}/users?search_term=&enrollment_type=student&per_page=100&sort=username`,
      [new User({id: '1', name: 'Student'})],
    )
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders form fields', () => {
    const {queryByLabelText, queryByPlaceholderText} = renderComponent()
    expect(queryByLabelText(/New Student Group/i)).toBeVisible()
    expect(queryByLabelText(/Group Name/i)).toBeVisible()
    expect(queryByLabelText(/Joining/i)).toBeVisible()
    expect(queryByLabelText(/Invite Students/i)).toBeVisible()
    expect(queryByPlaceholderText(/Search/i)).toBeVisible()
  })

  it('renders modular footer', () => {
    const {getByText} = renderComponent()
    expect(getByText(/Submit/i)).toBeVisible()
    expect(getByText(/Cancel/i)).toBeVisible()
  })

  it('clears prior state if modal is closed', () => {
    const {getByText, getByLabelText, rerender} = renderComponent()
    fireEvent.input(getByLabelText('Group Name *'), {
      target: {value: 'Dat new new'},
    })
    expect(getByLabelText('Group Name *')).toHaveValue('Dat new new')
    fireEvent.click(getByText('Cancel'))
    rerender(<NewStudentGroupModal {...defaultProps} open={false} />)
    expect(getByLabelText('Group Name *')).toHaveValue('')
  })

  describe('group name validations', () => {
    it('validates empty group name reminder', () => {
      const {getByText, queryByText} = renderComponent()
      expect(queryByText('A group name is required.')).not.toBeInTheDocument()
      getByText('Submit').closest('button').click()
      expect(queryByText('A group name is required.')).toBeInTheDocument()
    })

    it('validates empty group name reminder with leading spaces', () => {
      const {getByText, getByLabelText, queryByText} = renderComponent()
      expect(queryByText('A group name is required.')).not.toBeInTheDocument()
      fireEvent.input(getByLabelText('Group Name *'), {
        target: {value: '  '},
      })
      getByText('Submit').closest('button').click()
      expect(queryByText('A group name is required.')).toBeInTheDocument()
    })

    it('shows too-long group name reminder.', () => {
      const {getByText, getByLabelText, queryByText} = renderComponent()
      expect(queryByText('Group name must be less than 255 characters.')).not.toBeInTheDocument()
      fireEvent.input(getByLabelText('Group Name *'), {
        target: {value: 'A'.repeat(260)},
      })
      getByText('Submit').closest('button').click()
      expect(queryByText('Group name must be less than 255 characters.')).toBeInTheDocument()
    })

    it('enables the submit button if group name is provided', () => {
      const {getByText, getByLabelText} = renderComponent()
      fireEvent.input(getByLabelText('Group Name *'), {
        target: {value: 'name'},
      })
      expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeFalsy()
    })
  })

  it('fetches and reports status', async () => {
    fetchMock.postOnce(`path:/courses/${ENV.course_id}/groups`, 200)
    const onDismissMock = jest.fn()
    const {getByText, getByRole, getAllByText, getByLabelText} = renderComponent({
      onDismiss: onDismissMock,
    })
    fireEvent.input(getByLabelText('Group Name *'), {
      target: {value: 'name'},
    })
    fireEvent.click(getByRole('combobox', {name: 'Invite Students'}))
    // Wait for loading state to finish
    await waitFor(() => {
      expect(screen.queryByRole('option', {name: 'Loading'})).not.toBeInTheDocument()
    })
    // Now click the student option
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
    expect(onDismissMock).toHaveBeenCalled()
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore()
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce(`path:/courses/${ENV.course_id}/groups`, 400)
      const {getByText, getAllByText, getByLabelText} = renderComponent()
      fireEvent.input(getByLabelText('Group Name *'), {
        target: {value: 'name'},
      })
      fireEvent.click(getByText('Submit'))
      await fetchMock.flush(true)
      expect(getAllByText(/error/i)).toBeTruthy()
    })
  })
})
