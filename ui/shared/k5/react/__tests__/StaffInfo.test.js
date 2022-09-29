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
import {render, fireEvent, waitFor} from '@testing-library/react'
import StaffInfo from '../StaffInfo'
import fetchMock from 'fetch-mock'

const CONVERSATIONS_URL = '/api/v1/conversations'

describe('StaffInfo', () => {
  const getProps = (overrides = {}) => ({
    id: '1',
    name: 'Mrs. Thompson',
    bio: 'Office Hours: 9-10am MWF',
    avatarUrl: '/avatar1.png',
    role: 'TeacherEnrollment',
    ...overrides,
  })

  it('renders the name, role, and bio of staff member', () => {
    const {getByText} = render(<StaffInfo {...getProps()} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
    expect(getByText('Office Hours: 9-10am MWF')).toBeInTheDocument()
    expect(getByText('Teacher')).toBeInTheDocument()
  })

  it('renders avatar with alt text', () => {
    const {getByAltText} = render(<StaffInfo {...getProps()} />)
    const image = getByAltText('Avatar for Mrs. Thompson')
    expect(image).toBeInTheDocument()
    expect(image.src).toContain('/avatar1.png')
  })

  it('renders custom role names', () => {
    const {getByText} = render(<StaffInfo {...getProps({role: 'Head TA'})} />)
    expect(getByText('Head TA')).toBeInTheDocument()
  })

  it('renders default avatar if avatarUrl is null', () => {
    const {getByAltText} = render(<StaffInfo {...getProps({avatarUrl: undefined})} />)
    const image = getByAltText('Avatar for Mrs. Thompson')
    expect(image).toBeInTheDocument()
    expect(image.src).toContain('/images/messages/avatar-50.png')
  })

  it('still renders name and role if bio is missing', () => {
    const {getByText} = render(<StaffInfo {...getProps({bio: null})} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
    expect(getByText('Teacher')).toBeInTheDocument()
  })

  it('still renders name if bio is missing', () => {
    const {getByText} = render(<StaffInfo {...getProps({bio: null})} />)
    expect(getByText('Mrs. Thompson')).toBeInTheDocument()
  })

  describe('instructor messaging', () => {
    const openModal = async () => {
      const wrapper = render(<StaffInfo {...getProps()} />)
      const button = wrapper.getByText('Send a message to Mrs. Thompson')
      fireEvent.click(button)
      await waitFor(() => expect(wrapper.getByText('Message Mrs. Thompson')).toBeInTheDocument())
      return wrapper
    }

    it('does not render messaging button for own user', () => {
      global.ENV = {current_user_id: '1'}
      const {queryByText} = render(<StaffInfo {...getProps()} />)
      expect(queryByText('Send a message to Mrs. Thompson')).not.toBeInTheDocument()
      global.ENV = {}
    })

    it('opens a modal when clicking the button', async () => {
      const wrapper = await openModal()
      expect(wrapper.getByLabelText('Message')).toBeInTheDocument()
    })

    it('closes modal on cancel', async () => {
      const wrapper = await openModal()
      const cancel = wrapper.getByText('Cancel')
      fireEvent.click(cancel)
      await waitFor(() =>
        expect(wrapper.queryByText('Message Mrs. Thompson')).not.toBeInTheDocument()
      )
    })

    it('disables the send button when no text in message', async () => {
      const wrapper = await openModal()
      const messageField = wrapper.getByLabelText('Message')
      const button = wrapper.getByText('Send').closest('button')
      expect(button).toBeDisabled()
      fireEvent.change(messageField, {target: {value: 'hello'}})
      expect(button).toBeEnabled()
      fireEvent.change(messageField, {target: {value: ''}})
      expect(button).toBeDisabled()
    })

    describe('sending', () => {
      afterEach(() => {
        fetchMock.restore()
      })

      it('shows spinner and disables buttons while sending', async () => {
        fetchMock.post(
          CONVERSATIONS_URL,
          () => new Promise(resolve => setTimeout(() => resolve(200), 1000))
        )
        const wrapper = await openModal()
        fireEvent.change(wrapper.getByLabelText('Message'), {target: {value: 'hello'}})
        fireEvent.click(wrapper.getByText('Send'))
        await waitFor(() => {
          expect(wrapper.getByText('Sending message')).toBeInTheDocument()
          expect(wrapper.getByText('Send').closest('button')).toBeDisabled()
          expect(wrapper.getByText('Cancel').closest('button')).toBeDisabled()
        })
      })

      it('shows success message if successful', async () => {
        fetchMock.post(CONVERSATIONS_URL, 200)
        const wrapper = await openModal()
        fireEvent.change(wrapper.getByLabelText('Message'), {target: {value: 'hello'}})
        fireEvent.click(wrapper.getByText('Send'))
        await waitFor(() =>
          expect(wrapper.getAllByText('Message to Mrs. Thompson sent.')[0]).toBeInTheDocument()
        )
      })

      it('shows failure message if failed', async () => {
        fetchMock.post(CONVERSATIONS_URL, 400)
        const wrapper = await openModal()
        fireEvent.change(wrapper.getByLabelText('Message'), {target: {value: 'hello'}})
        fireEvent.click(wrapper.getByText('Send'))
        await waitFor(() =>
          expect(wrapper.getAllByText('Failed sending message.')[0]).toBeInTheDocument()
        )
      })

      it('clears inputs after a successful send', async () => {
        fetchMock.post(CONVERSATIONS_URL, 200)
        const wrapper = await openModal()
        fireEvent.change(wrapper.getByLabelText('Message'), {target: {value: 'hello'}})
        fireEvent.click(wrapper.getByText('Send'))
        fireEvent.click(wrapper.getByText('Send a message to Mrs. Thompson'))
        await waitFor(() => {
          expect(wrapper.getByLabelText('Message').closest('textarea').value).toBe('')
          expect(wrapper.getByLabelText('Subject').closest('input').value).toBe('')
        })
      })
    })
  })
})
