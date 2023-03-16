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
  UnknownContentItemJson,
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
  const fileContentItem: UnknownContentItemJson = {
    type: 'file',
    some: 'prop',
  }
  const unsupportedContentItem: UnknownContentItemJson = {
    type: 'unsupported',
    some: 'prop',
  }
  const htmlFragmentItem: HtmlFragmentContentItemJson = {
    type: 'html',
    html: '<a href="www.html.com">test</a>',
  }

  const contentItems: Lti13ContentItemJson[] = [
    linkContentItem, // 1
    unsupportedContentItem, // Testing bad data
    resourceLinkContentItem, // 2
    imageContentItem, // 3
    htmlFragmentItem, // 4
    resourceLinkContentItemWithUuid, // 5
  ]
  const validContentItems = [
    linkContentItem,
    resourceLinkContentItem,
    imageContentItem,
    htmlFragmentItem,
    resourceLinkContentItemWithUuid,
  ]
  const editor = createDeepMockProxy<ExternalToolsEditor>()
  const rceWrapper = createDeepMockProxy<RCEWrapper>()

  let showFlashAlertSpy: ReturnType<typeof jest.spyOn>

  beforeAll(() => {
    jest.spyOn(RCEWrapper, 'getByEditor').mockImplementation(e => {
      if (e === editor) return rceWrapper
      else {
        throw new Error('Wrong editor requested')
      }
    })

    showFlashAlertSpy = jest.spyOn(
      jest.requireActual('../../../../../common/FlashAlert'),
      'showFlashAlert'
    )
  })

  beforeEach(() => {
    editor.mockClear()
    rceWrapper.mockClear()
    showFlashAlertSpy.mockClear()
  })

  describe('static', () => {
    it('handles an event with all valid content items by closing the dialog', async () => {
      const ev = {data: {content_items: validContentItems, subject: 'LtiDeepLinkingResponse'}}
      const dialog = {close: jest.fn()}
      await processEditorContentItems(ev, externalToolsEnvFor(editor), dialog)
      expect(dialog.close).toHaveBeenCalled()
      expect(showFlashAlertSpy).not.toHaveBeenCalled()
    })

    it('ignores messages without content_items', async () => {
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

    it('handles an event with all unsupported items, showing a warning once and closing the dialog', async () => {
      const dialog = {close: jest.fn()}

      await processEditorContentItems(
        // Bypass type checking to ensure it can handle bad data from javascript
        {
          data: {
            content_items: [
              // Include two copies of the unsupported item to ensure that the warning is only shown once
              fileContentItem,
              unsupportedContentItem,
            ],
          },
        },
        externalToolsEnvFor(editor),
        dialog
      )
      expect(dialog.close).toHaveBeenCalled()

      expect(showFlashAlertSpy).toHaveBeenCalledTimes(1)
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message: 'Could not insert content: "file" items are not currently supported in Canvas.',
        type: 'warning',
        err: null,
      })
    })

    it('handles an event with some unsupported items, showing a warning once and closing the dialog', async () => {
      const dialog = {close: jest.fn()}

      await processEditorContentItems(
        // Bypass type checking to ensure it can handle bad data from javascript
        {
          data: {
            content_items: [
              // Include two copies of the unsupported item to ensure that the warning is only shown once
              unsupportedContentItem,
              fileContentItem,

              // Include a real content item, too
              htmlFragmentItem,
            ],
          },
        },
        externalToolsEnvFor(editor),
        dialog
      )
      expect(dialog.close).toHaveBeenCalled()

      expect(showFlashAlertSpy).toHaveBeenCalledTimes(1)
      expect(showFlashAlertSpy).toHaveBeenCalledWith({
        message:
          'Could not insert content: "unsupported" items are not currently supported in Canvas.',
        type: 'warning',
        err: null,
      })
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
