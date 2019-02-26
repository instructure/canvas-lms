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
import ReactDOM from 'react-dom'
import GenericErrorPage from '../GenericErrorPage'
import $ from 'jquery'
import moxios from 'moxios'

beforeAll(() => {
  const found = document.getElementById('fixtures')
  if (!found) {
    const fixtures = document.createElement('div')
    fixtures.setAttribute('id', 'fixtures')
    document.body.appendChild(fixtures)
  }
})

beforeEach(() => {
  moxios.install()
  moxios.stubRequest('/error_reports', {
    status: 200,
    response: {
      logged: true,
      id: '7'
    }
  })
})

afterEach(() => {
  moxios.uninstall()
  ReactDOM.unmountComponentAtNode(document.getElementById('fixtures'))
})

const defaultProps = () => ({
  errorSubject: 'Testing Stuff',
  errorCategory: 'Error Category'
})

describe('GenericErrorPage component', () => {
  test('renders component correctly', () => {
    ReactDOM.render(<GenericErrorPage {...defaultProps()} />, document.getElementById('fixtures'))
    const element = $("#fixtures:contains('Something broke unexpectedly')")
    expect(element.text()).toEqual(
      'Something broke unexpectedly.If you have a moment,click here to tell us what happened'
    )
  })

  test('show the comment box when feedback button is clicked', () => {
    ReactDOM.render(<GenericErrorPage {...defaultProps()} />, document.getElementById('fixtures'))
    const button = $('[data-test-id="generic-shared-error-page-button"]')
    button.click()
    const genericErrorBoxEmail = $('[data-test-id="generic-error-comment-box-email"] label')
    expect(genericErrorBoxEmail.text()).toEqual('Email Address (Optional)')
  })

  test('show the submitted text when comment is submitted', done => {
    ReactDOM.render(<GenericErrorPage {...defaultProps()} />, document.getElementById('fixtures'))
    const button = $('[data-test-id="generic-shared-error-page-button"]')
    button.click()
    const submitButton = $('[data-test-id="generic-error-comment-box-submit-button"]')
    submitButton.click()
    moxios.wait(async () => {
      const submittedText = $('[data-test-id="generic-error-comments-submitted"]')
      expect(submittedText.text()).toEqual('Comment submitted!')
      done()
    })
  })

  test('show the loading indicator when comment is submitted', () => {
    ReactDOM.render(<GenericErrorPage {...defaultProps()} />, document.getElementById('fixtures'))
    const button = $('[data-test-id="generic-shared-error-page-button"]')
    button.click()
    const submitButton = $('[data-test-id="generic-error-comment-box-submit-button"]')
    submitButton.click()
    const loadingIndicator = $('[data-test-id="generic-error=page-loading-indicator"]')
    expect(loadingIndicator).toHaveLength(1)
  })

  test('correct info posted to server', done => {
    const errorSubject = 'Testing Stuff'
    ReactDOM.render(
      <GenericErrorPage errorSubject={errorSubject} />,
      document.getElementById('fixtures')
    )
    const button = $('[data-test-id="generic-shared-error-page-button"]')
    button.click()
    const submitButton = $('[data-test-id="generic-error-comment-box-submit-button"]')
    submitButton.click()
    moxios.wait(async () => {
      const moxItem = await moxios.requests.mostRecent()
      const requestData = JSON.parse(moxItem.config.data)
      expect(requestData.error.subject).toEqual(errorSubject)
      const submittedText = $('[data-test-id="generic-error-comments-submitted"]')
      expect(submittedText.text()).toEqual('Comment submitted!')
      done()
    })
  })
})
