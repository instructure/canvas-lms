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

import $ from 'jquery'
import processSingleContentItem from '../processSingleContentItem'

const content_items = [
  {
    type: "link",
    title: 'title',
    url: 'http://www.tool.com'
  },
  {
    type: "ltiResourceLink",
    title: 'LTI Link',
    url: 'http://www.tool.com/lti'
  }
]

const data = (overrides) => ({
  content_items,
  msg: 'message',
  log: 'log',
  errormsg: 'error message',
  errorlog: 'error log',
  ltiEndpoint: 'https://www.instructure.com/lti',
  messageType: 'LtiDeepLinkingResponse',
  ...overrides
})

describe('processSingleContentItem', () => {
  const oldFlashError = $.flashError
  const oldFlashMessage = $.flashMessage

  const flashErrorMock = jest.fn()
  const flashMessageMock = jest.fn()

  beforeEach(() => {
    $.flashError = flashErrorMock
    $.flashMessage = flashMessageMock
  })

  afterEach(() => {
    $.flashError = oldFlashError
    $.flashMessage = oldFlashMessage
  })

  it('extracts the first content item', () => {
    processSingleContentItem({data: data()}).then((result) => {
      expect(result).toEqual(content_items[0])
    })
  })

  describe('when no content items are provided', () => {
    it('returns "undefined"', () => {
      processSingleContentItem({data: data({content_items: []})}).then((result) => {
        expect(result).toBeUndefined()
      })
    })
  })
})