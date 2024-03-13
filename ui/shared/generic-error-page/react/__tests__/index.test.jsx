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

import '@instructure/canvas-theme'
import React from 'react'
import GenericErrorPage from '../index'
import {render} from '@testing-library/react'
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import moxios from 'moxios'

beforeEach(() => {
  moxios.install()
})

afterEach(() => {
  moxios.uninstall()
})

const defaultProps = () => ({
  errorSubject: 'Testing Stuff',
  errorCategory: 'Error Category',
  errorMessage: 'Test Message',
  imageUrl: 'testurl',
})

describe('GenericErrorPage component', () => {
  test('renders component correctly', () => {
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    expect(getByText('Sorry, Something Broke')).toBeInTheDocument()
  })

  test('show input fields when report issue button is clicked', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    await user.click(getByText('Report Issue'))
    expect(getByText('What happened?')).toBeInTheDocument()
    expect(getByText('Your Email Address')).toBeInTheDocument()
  })

  test('disables the submit button if email address is empty', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    await user.click(getByText('Report Issue'))
    expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeTruthy()
  })

  it('enables the submit button if email address is provided', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText, getByPlaceholderText} = render(<GenericErrorPage {...defaultProps()} />)
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeFalsy()
  })

  test('show the submitted text when comment is submitted', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText, getByPlaceholderText, findByText} = render(<GenericErrorPage {...defaultProps()} />)
    moxios.stubRequest('/error_reports', {
      status: 200,
      response: {
        logged: true,
        id: '7',
      },
    })
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))
    expect(await findByText('Comment submitted!')).toBeInTheDocument()
  })

  test('show the loading indicator when comment is submitted', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText, getByTitle, getByPlaceholderText} = render(
      <GenericErrorPage {...defaultProps()} />
    )
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  test('correct info posted to server', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    moxios.stubRequest('/error_reports', {
      status: 200,
      response: {
        logged: true,
        id: '7',
      },
    })
    const modifiedProps = defaultProps()
    modifiedProps.errorSubject = 'Testing Stuff'
    modifiedProps.errorMessage = 'Test Message'
    const {getByText, getByPlaceholderText, findByText} = render(<GenericErrorPage {...modifiedProps} />)
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))
    const moxItem = moxios.requests.mostRecent()
    const requestData = JSON.parse(moxItem.config.data)
    expect(requestData.error.subject).toEqual(modifiedProps.errorSubject)
    expect(requestData.error.message).toEqual(modifiedProps.errorMessage)
    expect(await findByText('Comment submitted!')).toBeInTheDocument()
  })

  test('correctly handles error posted from server', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    moxios.stubRequest('/error_reports', {
      status: 503,
      response: {
        logged: false,
        id: '7',
      },
    })
    const modifiedProps = defaultProps()
    modifiedProps.errorSubject = 'Testing Stuff'
    modifiedProps.errorMessage = 'Test Message'
    const {getByText, getByPlaceholderText, findByText} = render(<GenericErrorPage {...modifiedProps} />)
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))
    const moxItem = moxios.requests.mostRecent()
    const requestData = JSON.parse(moxItem.config.data)
    expect(requestData.error.subject).toEqual(modifiedProps.errorSubject)
    expect(requestData.error.message).toEqual(modifiedProps.errorMessage)
    expect(await findByText('Comment failed to post! Please try again later.')).toBeInTheDocument()
  })
})
