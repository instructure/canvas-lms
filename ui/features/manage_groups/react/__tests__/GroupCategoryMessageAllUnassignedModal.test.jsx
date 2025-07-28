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
import {render, fireEvent, screen} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import stubEnv from '@canvas/stub-env'
import GroupCategoryMessageAllUnassignedModal from '../GroupCategoryMessageAllUnassignedModal'
import {userEvent} from '@testing-library/user-event'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'

// Mock the flash alert module
jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashSuccess: jest.fn(() => jest.fn()),
  showFlashError: jest.fn(() => jest.fn()),
}))

describe('GroupCategoryMessageAllUnassignedModal', () => {
  const onDismiss = jest.fn()
  const open = true
  const recipients = [{id: '1', short_name: 'name'}]
  const groupCategory = {
    name: 'Group Set',
  }

  stubEnv({
    context_asset_string: 'course_1',
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders form fields', () => {
    const {queryByText, queryAllByText, queryByLabelText, queryByPlaceholderText} = render(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={open}
        onDismiss={onDismiss}
      />,
    )
    expect(queryByLabelText(/Message students/i)).toBeVisible()
    expect(queryAllByText(/Recipients/i)).toBeTruthy()
    expect(queryByText('name')).toBeVisible()
    expect(queryByPlaceholderText(/type message/i)).toBeVisible()
  })

  it('renders modular footer', () => {
    const {getByText} = render(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={open}
        onDismiss={onDismiss}
      />,
    )
    expect(getByText(/Send Message/i)).toBeVisible()
    expect(getByText(/Cancel/i)).toBeVisible()
  })

  it('clears prior state if modal is closed', () => {
    const {getByText, getByLabelText, rerender} = render(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={open}
        onDismiss={onDismiss}
      />,
    )
    fireEvent.input(getByLabelText('Required input. Message all unassigned students.'), {
      target: {value: 'foo'},
    })
    expect(getByLabelText('Required input. Message all unassigned students.')).toHaveValue('foo')
    fireEvent.click(getByText('Cancel'))
    rerender(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={false}
        onDismiss={onDismiss}
      />,
    )
    expect(getByLabelText('Required input. Message all unassigned students.')).toHaveValue('')
  })

  it('disables the Send Message button if text input is empty', () => {
    const {getByText} = render(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={open}
        onDismiss={onDismiss}
      />,
    )
    expect(getByText('Send Message').closest('button').hasAttribute('disabled')).not.toBeTruthy()
  })

  it('enables the Send Message button if text input is provided', () => {
    const {getByText, getByLabelText} = render(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={open}
        onDismiss={onDismiss}
      />,
    )
    fireEvent.input(getByLabelText('Required input. Message all unassigned students.'), {
      target: {value: 't'},
    })
    expect(getByText('Send Message').closest('button').hasAttribute('disabled')).toBeFalsy()
  })

  it('fetches and reports status', async () => {
    fetchMock.postOnce(`path:/api/v1/conversations`, 200)
    const {getByText, getAllByText, getByLabelText} = render(
      <GroupCategoryMessageAllUnassignedModal
        groupCategory={groupCategory}
        recipients={recipients}
        open={open}
        onDismiss={onDismiss}
      />,
    )
    fireEvent.input(getByLabelText('Required input. Message all unassigned students.'), {
      target: {value: 'hi'},
    })
    fireEvent.click(getByText('Send Message'))
    const [, fetchOptions] = fetchMock.lastCall()
    expect(fetchOptions.method).toBe('POST')
    expect(JSON.parse(fetchOptions.body)).toMatchObject({
      body: 'hi',
      context_code: 'course_1',
      recipients: ['1'],
    })
    expect(getAllByText(/Sending Message/i)).toBeTruthy()
    await fetchMock.flush(true)
    expect(showFlashSuccess).toHaveBeenCalledWith('Message Sent!')
    expect(onDismiss).toHaveBeenCalled()
  })

  describe('errors', () => {
    beforeEach(() => {
      jest.spyOn(console, 'error').mockImplementation()
    })

    afterEach(() => {
      console.error.mockRestore()
    })

    it('reports an error if the fetch fails', async () => {
      fetchMock.postOnce(`path:/api/v1/conversations`, 500)
      const {getByText, getAllByText, getByLabelText} = render(
        <GroupCategoryMessageAllUnassignedModal
          groupCategory={groupCategory}
          recipients={recipients}
          open={open}
          onDismiss={onDismiss}
        />,
      )
      fireEvent.input(getByLabelText('Required input. Message all unassigned students.'), {
        target: {value: 'hi'},
      })
      fireEvent.click(getByText('Send Message'))
      await fetchMock.flush(true)
      expect(getAllByText(/Failed/i)).toBeTruthy()
    })

    it('shows error if user tries to submit an empty message', async () => {
      fetchMock.postOnce(`path:/api/v1/conversations`, 500)
      render(
        <GroupCategoryMessageAllUnassignedModal
          groupCategory={groupCategory}
          recipients={recipients}
          open={open}
          onDismiss={onDismiss}
        />,
      )
      const submitBtn = screen.getByTestId('message_submit')
      await userEvent.click(submitBtn)

      const errorMessages = await screen.findAllByText(/Message text is required/i)
      expect(errorMessages.length).toBeGreaterThan(0)
    })

    it('clears error message when user inputs text in the textarea', async () => {
      // Render the component
      render(
        <GroupCategoryMessageAllUnassignedModal
          groupCategory={groupCategory}
          recipients={recipients}
          open={open}
          onDismiss={onDismiss}
        />,
      )

      // First click without text should show error
      const submitBtn = screen.getByTestId('message_submit')
      await userEvent.click(submitBtn)

      // Verify error message is displayed
      const errorMessages = await screen.findAllByText(/Message text is required/i)
      expect(errorMessages.length).toBeGreaterThan(0)

      // Type text in the textarea
      const textarea = screen.getByTestId('message_all_unassigned_textarea')
      await userEvent.type(textarea, 'Hello')

      // Verify text was entered
      expect(textarea.value).toBe('Hello')

      // Verify error message is gone
      const clearedErrors = screen.queryAllByText('Message text is required')
      expect(clearedErrors).toHaveLength(0)
    })
  })
})
