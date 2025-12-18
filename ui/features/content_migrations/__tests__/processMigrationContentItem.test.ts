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
import processMigrationContentItem from '../processMigrationContentItem'
import processSingleContentItem from '@canvas/deep-linking/processors/processSingleContentItem'
import fakeENV from '@canvas/test-utils/fakeENV'

vi.mock('@canvas/deep-linking/processors/processSingleContentItem')

interface ContentItem {
  type: string
  expiresAt: string
  url: string
  title: string
  text: string
}

interface EventData {
  subject: string
  msg: string
  content_items: ContentItem[]
  ltiEndpoint: string
}

interface EventOptions {
  origin?: string
  subject?: string
  type?: string
}

beforeAll(() => {
  fakeENV.setup({
    DEEP_LINKING_POST_MESSAGE_ORIGIN: 'http://www.test.com',
  })
})

beforeEach(() => {
  vi.spyOn($, 'flashMessage').mockImplementation(() => {})
  vi.spyOn($, 'flashError').mockImplementation(() => {})
  vi.mocked(processSingleContentItem).mockReturnValue({
    type: 'file' as any,
    url: 'http://example.com/file.txt',
    text: 'Test File',
  })
})

afterAll(() => {
  fakeENV.teardown()
})

function event(overrides: EventOptions = {}): MessageEvent {
  const opts = {
    origin: 'http://www.test.com',
    subject: 'LtiDeepLinkingResponse',
    type: 'file',
    ...overrides,
  }
  return {
    origin: opts.origin,
    data: {
      subject: opts.subject,
      msg: 'Deep Linking Message',
      content_items: [
        {
          type: opts.type,
          expiresAt: '2019-05-24T19:30:19Z',
          url: 'https://lti-tool-provider-example.herokuapp.com/test_file.txt',
          title: 'Lti 1.3 Tool Title',
          text: 'Lti 1.3 Tool Text',
        },
      ],
      ltiEndpoint: 'http://web.canvas-lms.docker/courses/11/external_tools/retrieve',
    } as EventData,
  } as MessageEvent
}

it.skip('process the content item', () => {
  processMigrationContentItem(event())
  expect($.flashMessage).toHaveBeenCalled()
  expect($.flashError).not.toHaveBeenCalled()
})

describe('when the origin is not trusted', () => {
  beforeEach(() => {
    processMigrationContentItem(event({origin: 'http://www.untrusted.com'}))
  })

  it('does not process the message', () => {
    expect($.flashMessage).not.toHaveBeenCalled()
  })
})

describe('when the message type is not "LtiDeepLinkingResponse"', () => {
  beforeEach(() => {
    processMigrationContentItem(event({subject: 'unkown message type'}))
  })

  it('does not process the message', () => {
    expect($.flashMessage).not.toHaveBeenCalled()
  })
})

describe('when the content item type is not "file"', () => {
  beforeEach(() => {
    vi.spyOn(console, 'error').mockImplementation(() => {})
    vi.mocked(processSingleContentItem).mockReturnValue({
      type: 'unknown_type' as any,
      url: 'http://example.com/file.txt',
      text: 'Test File',
    })
    processMigrationContentItem(event({type: 'unknown_type'}))
  })

  it('displays a warning to the user', () => {
    expect(console.error).toHaveBeenCalled()
    expect($.flashError).toHaveBeenCalledWith('Error retrieving content')
  })
})
