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

import {
  HtmlFragmentContentItemJson,
  ImageContentItemJson,
  LinkContentItemJson,
  Lti13ContentItemJson,
  ResourceLinkContentItemJson,
} from '../Lti13ContentItemJson'
import {createDeepMockProxy} from '../../../../../util/__tests__/deepMockProxy'
import {ExternalToolsEditor, externalToolsEnvFor} from '../../ExternalToolsEnv'
import RCEWrapper from '../../../../RCEWrapper'

describe('processEditorContentItems', () => {
  const linkContentItem: LinkContentItemJson = {
    type: 'link',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text',
  }
  const resourceLinkContentItem: ResourceLinkContentItemJson = {
    type: 'ltiResourceLink',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text',
  }
  const resourceLinkContentItemWithUuid: ResourceLinkContentItemJson = {
    type: 'ltiResourceLink',
    url: 'http://www.test.com',
    title: 'link title',
    text: 'link text',
    lookup_uuid: 'somerandomuuid',
  }
  const imageContentItem: ImageContentItemJson = {
    type: 'image',
    url: 'http://www.test.com/image',
    width: 100,
    height: 200,
  }
  const htmlFragmentItem: HtmlFragmentContentItemJson = {
    type: 'html',
    html: '<a href="www.html.com">test</a>',
  }
  const invalidContentItem = {type: 'banana'}
  const contentItems: Lti13ContentItemJson[] = [
    linkContentItem, // 1
    invalidContentItem as Lti13ContentItemJson, // Testing bad data
    resourceLinkContentItem, // 2
    imageContentItem, // 3
    htmlFragmentItem, // 4
    resourceLinkContentItemWithUuid, // 5
  ]
  const editor = createDeepMockProxy<ExternalToolsEditor>()
  const rceWrapper = createDeepMockProxy<RCEWrapper>()

  beforeAll(() => {
    jest.spyOn(RCEWrapper, 'getByEditor').mockImplementation(e => {
      if (e === editor) return rceWrapper
      else {
        throw new Error('Wrong editor requested')
      }
    })
  })

  beforeEach(() => {
    editor.mockClear()
    rceWrapper.mockClear()
  })

  describe('static', () => {
    it('closes the dialog', async () => {
      const ev = {data: {content_items: contentItems, subject: 'LtiDeepLinkingResponse'}}
      const dialog = {close: jest.fn()}
      await processEditorContentItems(ev, externalToolsEnvFor(editor), dialog)
      expect(dialog.close).toHaveBeenCalled()
    })

    it('ignores non deep linking event types', async () => {
      const ev = {data: {subject: 'OtherMessage'}}
      const dialog = {close: jest.fn()}
      await processEditorContentItems(
        // Bypass type checking to ensure it can handle bad data from javascript
        ev as any,
        externalToolsEnvFor(editor),
        dialog
      )
      expect(dialog.close).not.toHaveBeenCalled()
    })
  })

  describe('when there is no editor selection', () => {
    beforeEach(() => {
      processEditorContentItems(
        {
          data: {
            content_items: contentItems,
            ltiEndpoint: 'test',
          },
        },
        externalToolsEnvFor(editor),
        null
      )
    })

    it('creates content for a link content item', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(
        1,
        '<a href="http://www.test.com" title="link title" target="_blank">link text</a>'
      )
    })

    it('creates content for an LTI ResourceLink content item', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(
        2,
        '<a href="test?display=borderless" title="link title" target="_blank">link text</a>'
      )
    })

    it('creates content for an image content item', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(
        3,
        '<img src="http://www.test.com/image" width="100" height="200">'
      )
    })

    it('creates content for an HTML fragment content item', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(4, '<a href="www.html.com">test</a>')
    })

    it('inserts an ltiEndpoint link for content items with a lookup_uuid', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(
        5,
        '<a href="test?display=borderless&amp;resource_link_lookup_uuid=somerandomuuid" title="link title" target="_blank">link text</a>'
      )
    })
  })

  describe('when there is an editor selection', () => {
    beforeEach(() => {
      editor.selection?.getContent.mockImplementation(() => 'user selection')

      processEditorContentItems(
        {
          data: {
            content_items: contentItems,
            ltiEndpoint: 'test',
          },
        },
        externalToolsEnvFor(editor),
        null
      )
    })

    it('creates content for a link content item', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(
        1,
        '<a href="http://www.test.com" title="link title" target="_blank">user selection</a>'
      )
    })

    it('creates content for an LTI ResourceLink content item', () => {
      expect(rceWrapper.insertCode).toHaveBeenNthCalledWith(
        2,
        '<a href="test?display=borderless" title="link title" target="_blank">user selection</a>'
      )
    })
  })
})
