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
import LoginActionPrompt from '../LoginActionPrompt'
import {render, waitFor, fireEvent} from '@testing-library/react'

describe('LoginActionPrompt', () => {
  it('renders component locked and feedback text labels correctly', async () => {
    const {getByText} = render(<LoginActionPrompt />)
    expect(await waitFor(() => getByText('Submission Locked'))).toBeInTheDocument()
    expect(await waitFor(() => getByText('Log in to submit'))).toBeInTheDocument()
  })

  it('login button redirects towards login page', async () => {
    delete window.location
    window.location = {assign: jest.fn()}

    const {getByTestId} = render(<LoginActionPrompt />)
    fireEvent.click(getByTestId('login-action-button'))
    expect(window.location.assign).toHaveBeenCalledWith('/login')
  })

  it('displays a message if the course has not started', async () => {
    const {getByTestId} = render(<LoginActionPrompt enrollmentState="accepted" />)
    const text = await waitFor(() => getByTestId('login-action-text').textContent)
    expect(text).toEqual('Course has not started yet')
  })

  it('displays a message if the student has not accepted their enrollment', async () => {
    const {getByTestId} = render(<LoginActionPrompt nonAcceptedEnrollment={true} />)
    const text = await waitFor(() => getByTestId('login-action-text').textContent)
    expect(text).toEqual('Accept course invitation to participate in this assignment')
  })

  it('displays a message if the student is not logged in', async () => {
    const {getByTestId} = render(<LoginActionPrompt />)
    const text = await waitFor(() => getByTestId('login-action-text').textContent)
    expect(text).toEqual('Log in to submit')
  })

  it('does not display a button if the course has not started', async () => {
    const {queryByTestId} = render(<LoginActionPrompt enrollmentState="accepted" />)
    expect(queryByTestId('login-action-button')).not.toBeInTheDocument()
  })

  it('displays an invitation button if the student has not accepted their enrollment', async () => {
    const {getByTestId} = render(<LoginActionPrompt nonAcceptedEnrollment={true} />)
    const text = await waitFor(() => getByTestId('login-action-button').textContent)
    expect(text).toEqual('Accept course invitation')
  })

  it('displays a login button if the student is not logged in', async () => {
    const {getByTestId} = render(<LoginActionPrompt />)
    const text = await waitFor(() => getByTestId('login-action-button').textContent)
    expect(text).toEqual('Log in')
  })
})
