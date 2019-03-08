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

import '@instructure/ui-themes/lib/canvas'
import React from 'react'
import GenericErrorPage from '../GenericErrorPage'
import {render, fireEvent} from 'react-testing-library'
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
  imageUrl: 'testurl'
})

describe('GenericErrorPage component', () => {
  test('renders component correctly', () => {
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    expect(getByText('Something broke unexpectedly.')).toBeInTheDocument()
  })

  test('show the comment box when feedback button is clicked', () => {
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    fireEvent.click(getByText('click here to tell us what happened'))
    expect(getByText('Email Address (Optional)')).toBeInTheDocument()
  })

  test('show the submitted text when comment is submitted', done => {
    const {getByText} = render(<GenericErrorPage {...defaultProps()} />)
    moxios.stubRequest('/error_reports', {
      status: 200,
      response: {
        logged: true,
        id: '7'
      }
    })
    fireEvent.click(getByText('click here to tell us what happened'))
    fireEvent.click(getByText('Submit'))
    moxios.wait(async () => {
      expect(getByText('Comment submitted!')).toBeInTheDocument()
      done()
    })
  })

  test('show the loading indicator when comment is submitted', () => {
    const {getByText, getByTitle} = render(<GenericErrorPage {...defaultProps()} />)
    fireEvent.click(getByText('click here to tell us what happened'))
    fireEvent.click(getByText('Submit'))
    expect(getByTitle('Loading')).toBeInTheDocument()
  })

  test('correct info posted to server', done => {
    moxios.stubRequest('/error_reports', {
      status: 200,
      response: {
        logged: true,
        id: '7'
      }
    })
    const modifiedProps = defaultProps()
    modifiedProps.errorSubject = 'Testing Stuff'
    const {getByText} = render(<GenericErrorPage {...modifiedProps} />)
    fireEvent.click(getByText('click here to tell us what happened'))
    fireEvent.click(getByText('Submit'))
    moxios.wait(async () => {
      const moxItem = await moxios.requests.mostRecent()
      const requestData = JSON.parse(moxItem.config.data)
      expect(requestData.error.subject).toEqual(modifiedProps.errorSubject)
      expect(getByText('Comment submitted!')).toBeInTheDocument()
      done()
    })
  })

  test('correctly handles error posted from server', done => {
    moxios.stubRequest('/error_reports', {
      status: 503,
      response: {
        logged: false,
        id: '7'
      }
    })
    const modifiedProps = defaultProps()
    modifiedProps.errorSubject = 'Testing Stuff'
    const {getByText} = render(<GenericErrorPage {...modifiedProps} />)
    fireEvent.click(getByText('click here to tell us what happened'))
    fireEvent.click(getByText('Submit'))
    moxios.wait(async () => {
      const moxItem = await moxios.requests.mostRecent()
      const requestData = JSON.parse(moxItem.config.data)
      expect(requestData.error.subject).toEqual(modifiedProps.errorSubject)
      expect(getByText('Comment failed to post! Please try again later.')).toBeInTheDocument()
      done()
    })
  })
})
