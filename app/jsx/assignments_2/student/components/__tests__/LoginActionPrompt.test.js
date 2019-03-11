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
import {mockAssignment} from '../../test-utils'
import {render, waitForElement, fireEvent} from 'react-testing-library'

describe('LoginActionPrompt', () => {
  it('renders component locked and feedback text labels correctly', async () => {
    const {getByText} = render(<LoginActionPrompt assignment={mockAssignment()} />)
    expect(await waitForElement(() => getByText('Submission Locked'))).toBeInTheDocument()
    expect(await waitForElement(() => getByText('Log in to submit'))).toBeInTheDocument()
  })

  it('login button redirects towards login page', () => {
    window.location.assign = jest.fn()
    const {getByText} = render(<LoginActionPrompt assignment={mockAssignment()} />)
    fireEvent.click(getByText('Log in'))
    expect(window.location.assign).toBeCalledWith('/login')
  })
})
