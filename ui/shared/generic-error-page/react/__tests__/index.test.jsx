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
import userEvent from '@testing-library/user-event'
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

  test('show input fields when report issue button is clicked', () => {
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    userEvent.click(getByText('Report Issue'))
    expect(getByText('What happened?')).toBeInTheDocument()
    expect(getByText('Your Email Address')).toBeInTheDocument()
  })

  test('disables the submit button if email address is empty', () => {
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    userEvent.click(getByText('Report Issue'))
    expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeTruthy()
  })

  it('enables the submit button if email address is provided', () => {
    const {getByText, getByPlaceholderText} = render(<GenericErrorPage {...defaultProps()} />)
    userEvent.click(getByText('Report Issue'))
    userEvent.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    expect(getByText('Submit').closest('button').hasAttribute('disabled')).toBeFalsy()
  })

  test('show the submitted text when comment is submitted', done => {
    const {getByText, getByPlaceholderText} = render(<GenericErrorPage {...defaultProps()} />)
    moxios.stubRequest('/error_reports', {
      status: 200,
      response: {
        logged: true,
        id: '7',
      },
    })
    userEvent.click(getByText('Report Issue'))
    userEvent.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    userEvent.click(getByText('Submit'))
    moxios.wait(() => {
      expect(getByText('Comment submitted!')).toBeInTheDocument()
      done()
    })
  })

  test('show the loading indicator when comment is submitted', () => {
    const {getByText, getByTitle, getByPlaceholderText} = render(
      <GenericErrorPage {...defaultProps()} />
    )
    userEvent.click(getByText('Report Issue'))
    userEvent.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    userEvent.click(getByText('Submit'))
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  test('correct info posted to server', done => {
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
    const {getByText, getByPlaceholderText} = render(<GenericErrorPage {...modifiedProps} />)
    userEvent.click(getByText('Report Issue'))
    userEvent.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    userEvent.click(getByText('Submit'))
    moxios.wait(async () => {
      const moxItem = moxios.requests.mostRecent()
      const requestData = JSON.parse(moxItem.config.data)
      expect(requestData.error.subject).toEqual(modifiedProps.errorSubject)
      expect(requestData.error.message).toEqual(modifiedProps.errorMessage)
      expect(getByText('Comment submitted!')).toBeInTheDocument()
      done()
    })
  })

  test('correctly handles error posted from server', done => {
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
    const {getByText, getByPlaceholderText} = render(<GenericErrorPage {...modifiedProps} />)
    userEvent.click(getByText('Report Issue'))
    userEvent.type(getByPlaceholderText('email@example.com'), 'foo@bar.com')
    userEvent.click(getByText('Submit'))
    moxios.wait(async () => {
      const moxItem = moxios.requests.mostRecent()
      const requestData = JSON.parse(moxItem.config.data)
      expect(requestData.error.subject).toEqual(modifiedProps.errorSubject)
      expect(requestData.error.message).toEqual(modifiedProps.errorMessage)
      expect(getByText('Comment failed to post! Please try again later.')).toBeInTheDocument()
      done()
    })
  })
})
