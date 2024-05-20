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

import type {DeepLinkResponse} from '../../DeepLinkResponse'
import $ from 'jquery'
import processSingleContentItem from '../processSingleContentItem'

jest.mock('jquery', () => ({
  flashError: jest.fn(),
  flashMessage: jest.fn(),
}))

const content_items = [
  {
    type: 'link',
    title: 'title',
    url: 'http://www.tool.com',
  } as const,
  {
    type: 'ltiResourceLink',
    title: 'LTI Link',
    url: 'http://www.tool.com/lti',
  } as const,
]

const data = (overrides: Partial<DeepLinkResponse>) => ({
  content_items,
  msg: 'message',
  log: 'log',
  errormsg: 'error message',
  errorlog: 'error log',
  ltiEndpoint: 'https://www.instructure.com/lti',
  subject: 'LtiDeepLinkingResponse',
  ...overrides,
})

describe('processSingleContentItem', () => {
  beforeEach(() => {
    ;($.flashError as unknown as {mockClear: () => void}).mockClear()
    ;($.flashMessage as unknown as {mockClear: () => void}).mockClear()
  })

  afterEach(() => {})

  it('extracts the first content item', () => {
    const result = processSingleContentItem({data: data({})})
    expect(result).toEqual(content_items[0])
  })

  describe('when no content items are provided', () => {
    it('returns "undefined"', () => {
      const result = processSingleContentItem({data: data({content_items: []})})
      expect(result).toBeUndefined()
    })
  })
})
