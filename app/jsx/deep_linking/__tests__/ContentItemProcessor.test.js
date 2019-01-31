/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import ContentItemProcessor, {processContentItemsForEditor} from '../ContentItemProcessor'
import {send} from 'jsx/shared/rce/RceCommandShim'

jest.mock('jsx/shared/rce/RceCommandShim', () => ({
  send: jest.fn()
}))

describe('processContentItemsForEditor', () => {
  const linkContentItem = {
    type: 'link',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text'
  }
  const resourceLinkContentItem = {
    type: 'ltiResourceLink',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text'
  }
  const imageContentItem = {
    type: 'image',
    url: 'http://www.test.com/image',
    width: 100,
    height: 200
  }
  const htmlFragmentItem = {
    type: 'html',
    html: '<a href="www.html.com">test</a>'
  }
  const invalidContentItem = {type: 'banana'}
  const contentItems = [
    linkContentItem,
    invalidContentItem,
    resourceLinkContentItem,
    imageContentItem,
    htmlFragmentItem
  ]
  const editor = {id: 'editor_id'}
  const editorWithSelection = {
    ...editor,
    selection: {
      getContent: () => 'user selection'
    }
  }

  describe('when there is no editor selection', () => {
    beforeEach(() => {
      send.mockClear()
      const processor = new ContentItemProcessor(contentItems, {}, {})
      processor.processContentItemsForEditor(editor)
    })

    it('creates content for a link content item', () => {
      expect(send.mock.calls[0][2]).toEqual(
        '<a href="http://www.test.com" title="link title">link text</a>'
      )
    })

    it('creates content for an LTI ResourceLink content item', () => {
      expect(send.mock.calls[1][2]).toEqual(
        '<a href="undefined?display=borderless&amp;url=http%3A%2F%2Fwww.test.com" title="link title">link text</a>'
      )
    })

    it('creates content for an image content item', () => {
      expect(send.mock.calls[2][2]).toEqual(
        '<img src="http://www.test.com/image" width="100" height="200">'
      )
    })

    it('creates content for an HTML fragment content item', () => {
      expect(send.mock.calls[3][2]).toEqual(
        '<a href=\"www.html.com\">test</a>'
      )
    })
  })

  describe('when there is an editor selection', () => {
    beforeEach(() => {
      send.mockClear()
      const processor = new ContentItemProcessor(contentItems, {}, {})
      processor.processContentItemsForEditor(editorWithSelection)
    })

    it('creates content for a link content item', () => {
      expect(send.mock.calls[0][2]).toEqual(
        '<a href="http://www.test.com" title="link title">user selection</a>'
      )
    })

    it('creates content for an LTI ResourceLink content item', () => {
      expect(send.mock.calls[1][2]).toEqual(
        '<a href="undefined?display=borderless&amp;url=http%3A%2F%2Fwww.test.com" title="link title">user selection</a>'
      )
    })
  })
})

const oldEnv = window.ENV
const env = {
  DEEP_LINKING_LOGGING: 'true'
}

beforeEach(() => {
  window.ENV = env
})

afterEach(() => {
  window.ENV = oldEnv
})

describe('message claims', () => {
  const oldFlashError = $.flashError
  const oldFlashMessage = $.flashMessage

  const flashErrorMock = jest.fn()
  const flashMessageMock = jest.fn()

  const messages = {
    msg: 'Message',
    errormsg: 'Error message'
  }

  beforeEach(() => {
    $.flashError = flashErrorMock
    $.flashMessage = flashMessageMock
    new ContentItemProcessor([], messages, {})
  })

  afterEach(() => {
    $.flashError = oldFlashError
    $.flashMessage = oldFlashMessage
  })

  it('shows the message', () => {
    expect(flashMessageMock).toHaveBeenCalledWith(messages.msg)
  })

  it('shows the error message', () => {
    expect(flashErrorMock).toHaveBeenCalledWith(messages.errormsg)
  })
})

describe('log claims', () => {
  const oldLog = console.log
  const oldError = console.error

  const logMock = jest.fn()
  const errorMock = jest.fn()

  const logs = {
    log: 'Log',
    errorlog: 'Error log'
  }

  beforeEach(() => {
    console.log = logMock
    console.error = errorMock
    new ContentItemProcessor([], {}, logs)
  })

  afterEach(() => {
    console.log = oldLog
    console.error = oldError
  })

  it('shows the log', () => {
    expect(logMock).toHaveBeenCalledWith(logs.log)
  })

  it('shows the error log', () => {
    expect(errorMock).toHaveBeenCalledWith(logs.errorlog)
  })
})
