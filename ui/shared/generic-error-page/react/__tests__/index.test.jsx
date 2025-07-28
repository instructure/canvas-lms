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
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'

const server = setupServer()

beforeAll(() => server.listen())
beforeEach(() => {
  fakeENV.setup()
})
afterEach(() => {
  server.resetHandlers()
  fakeENV.teardown()
})
afterAll(() => server.close())

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
    const {getByText, getByPlaceholderText, findByText} = render(
      <GenericErrorPage {...defaultProps()} />,
    )

    server.use(http.post('/error_reports', () => HttpResponse.json({logged: true, id: '7'})))

    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))
    expect(await findByText('Comment submitted!')).toBeInTheDocument()
  })

  test('show the loading indicator when comment is submitted', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})
    const {getByText, getByPlaceholderText, findByTitle} = render(
      <GenericErrorPage {...defaultProps()} />,
    )

    let resolveRequest
    const requestPromise = new Promise(resolve => {
      resolveRequest = resolve
    })

    server.use(
      http.post('/error_reports', async () => {
        await requestPromise
        return HttpResponse.json({logged: true, id: '7'})
      }),
    )

    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    const submitPromise = user.click(getByText('Submit'))

    expect(await findByTitle('Loading')).toBeInTheDocument()

    resolveRequest()
    await submitPromise
  })

  test('correct info posted to server', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})

    let capturedRequest
    server.use(
      http.post('/error_reports', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({logged: true, id: '7'})
      }),
    )

    const modifiedProps = defaultProps()
    modifiedProps.errorSubject = 'Testing Stuff'
    modifiedProps.errorMessage = 'Test Message'
    const {getByText, getByPlaceholderText, findByText} = render(
      <GenericErrorPage {...modifiedProps} />,
    )
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))

    expect(await findByText('Comment submitted!')).toBeInTheDocument()
    expect(capturedRequest.error.subject).toEqual(modifiedProps.errorSubject)
    expect(capturedRequest.error.message).toEqual(modifiedProps.errorMessage)
  })

  test('correctly handles error posted from server', async () => {
    const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})

    let capturedRequest
    server.use(
      http.post('/error_reports', async ({request}) => {
        capturedRequest = await request.json()
        return HttpResponse.json({logged: false, id: '7'}, {status: 503})
      }),
    )

    const modifiedProps = defaultProps()
    modifiedProps.errorSubject = 'Testing Stuff'
    modifiedProps.errorMessage = 'Test Message'
    const {getByText, getByPlaceholderText, findByText} = render(
      <GenericErrorPage {...modifiedProps} />,
    )
    await user.click(getByText('Report Issue'))
    await user.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    await user.click(getByText('Submit'))

    expect(await findByText('Comment failed to post! Please try again later.')).toBeInTheDocument()
    expect(capturedRequest.error.subject).toEqual(modifiedProps.errorSubject)
    expect(capturedRequest.error.message).toEqual(modifiedProps.errorMessage)
  })
})
