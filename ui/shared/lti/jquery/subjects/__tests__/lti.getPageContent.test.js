/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import getPageContent from '../lti.getPageContent'

describe('lti.getPageContent handler', () => {
  let responseMessages
  let originalDocument

  beforeEach(() => {
    responseMessages = {
      sendBadRequestError: jest.fn(),
      sendResponse: jest.fn(),
      sendError: jest.fn(),
    }
    originalDocument = window.document
  })

  afterEach(() => {
    window.document = originalDocument
  })

  function expectContent(expectedContent) {
    expect(getPageContent({responseMessages})).toEqual(true)
    expect(responseMessages.sendResponse).toHaveBeenCalledWith({content: expectedContent})
    expect(responseMessages.sendResponse).toHaveBeenCalledTimes(1)
    expect(responseMessages.sendError).not.toHaveBeenCalled()
  }

  describe('when lti-page-content elements are not present', () => {
    it('responds with an empty string message', () => {
      expectContent('')
    })
  })

  describe('when mixed data-lti-page-content elements are present', () => {
    beforeEach(() => {
      const testdiv = document.createElement('div')
      testdiv.innerHTML = `<div>
          <div data-lti-page-content="true">page content1</div>
          <div data-lti-page-content="true">
            <div>page content2a</div>
            <div>page content2b</div>
            <div data-lti-page-content="false">UNEPECTED</div>
            <div data-lti-page-content="false">UNEPECTED</div>
            <div>
              page content2c
              <div data-lti-page-content="false">UNEPECTED</div>
            </div>
          </div>
          <div>page content3-UNEXPECTED</div>
        </div>`
      window.document.body.appendChild(testdiv)
    })

    it('responds with a message containing the combined outerHTML of expected elements only', () => {
      expectContent(
        '<div data-lti-page-content="true">page content1</div>' +
          `<div data-lti-page-content="true">
            <div>page content2a</div>
            <div>page content2b</div>
            <div>
              page content2c
            </div>
          </div>`
      )
    })
  })
})
