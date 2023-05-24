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
import processEditorContentItems from '../processEditorContentItems'
import {send as rceSend} from '@canvas/rce/RceCommandShim'

const send = rceSend as unknown as {mockClear: () => void; mock: {calls: Array<Array<unknown>>}}

jest.mock('@canvas/rce/RceCommandShim', () => ({
  send: jest.fn(),
}))

describe('processEditorContentItems', () => {
  const linkContentItem = {
    type: 'link',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text',
  } as const
  const resourceLinkContentItem = {
    type: 'ltiResourceLink',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text',
  } as const
  const imageContentItem = {
    type: 'image',
    url: 'http://www.test.com/image',
    width: 100,
    height: 200,
  } as const
  const htmlFragmentItem = {
    type: 'html',
    html: '<a href="www.html.com">test</a>',
  } as const
  const contentItems = [
    linkContentItem,
    resourceLinkContentItem,
    imageContentItem,
    htmlFragmentItem,
  ]
  const editor = {id: 'editor_id'}
  const editorWithSelection = {
    ...editor,
    selection: {
      getContent: () => 'user selection',
    },
  }

  describe('static', () => {
    it('closes the dialog', () => {
      jest.spyOn(window, 'requestAnimationFrame').mockImplementation(cb => {
        cb(0)
        return 0
      })
      const ev = {data: {content_items: contentItems, subject: 'LtiDeepLinkingResponse'}}
      const dialog = {close: jest.fn()}
      processEditorContentItems(ev, editor, dialog)
      expect(dialog.close).toHaveBeenCalled()
    })
  })

  describe('when there is no editor selection', () => {
    const dialog = {close: jest.fn()}
    beforeEach(() => {
      const event = {data: {content_items: contentItems, ltiEndpoint: 'test'}}
      send.mockClear()
      processEditorContentItems(event, editor, dialog)
    })

    it('creates content for a link content item', () => {
      expect(send.mock.calls[0][2]).toEqual(
        '<a href="http://www.test.com" title="link title" target="_blank">link text</a>'
      )
    })

    it('creates content for an LTI ResourceLink content item', () => {
      expect(send.mock.calls[1][2]).toEqual(
        '<a href="test?display=borderless" title="link title" target="_blank">link text</a>'
      )
    })

    it('creates content for an image content item', () => {
      expect(send.mock.calls[2][2]).toEqual(
        '<img src="http://www.test.com/image" width="100" height="200">'
      )
    })

    it('creates content for an HTML fragment content item', () => {
      expect(send.mock.calls[3][2]).toEqual('<a href="www.html.com">test</a>')
    })
  })

  describe('when there is an editor selection', () => {
    const dialog = {close: jest.fn()}
    beforeEach(() => {
      const event = {data: {content_items: contentItems, ltiEndpoint: 'test'}}
      send.mockClear()
      processEditorContentItems(event, editorWithSelection, dialog)
    })

    it('creates content for a link content item', () => {
      expect(send.mock.calls[0][2]).toEqual(
        '<a href="http://www.test.com" title="link title" target="_blank">user selection</a>'
      )
    })

    it('creates content for an LTI ResourceLink content item', () => {
      expect(send.mock.calls[1][2]).toEqual(
        '<a href="test?display=borderless" title="link title" target="_blank">user selection</a>'
      )
    })
  })
})
