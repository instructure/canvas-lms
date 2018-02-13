/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import tinymce from 'tinymce/tinymce'
import TinyMCEContentItem from 'tinymce_plugins/instructure_external_tools/TinyMCEContentItem'
import contentItems from './ContentItems'

QUnit.module('TinyMCEContentItem LTI Link', {
  setup() {
    const textarea = $("<textarea id='a42' data-rich_text='true'></textarea>")
    $('#fixtures').append(textarea)
    return tinymce.init({selector: '#fixtures textarea#a42'})
  },
  teardown() {
    $('#fixtures').empty()
  }
})

test("Handles LTI link with presentation target of 'embed' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_thumb_embed)
  equal(contentItem.text, 'Arch Linux thumbnail embed')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(contentItem.codePayload, 'Arch Linux thumbnail embed')
})

test("Handles LTI link with presentation target of 'frame' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_thumb_frame)
  equal(contentItem.text, 'Arch Linux thumbnail frame')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(
    contentItem.codePayload,
    '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux thumbnail frame" style="height: 128px; width: 128px;"></a>'
  )
})

test("Handles LTI link with presentation target of 'iframe' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_thumb_iframe)
  equal(contentItem.text, 'Arch Linux thumbnail iframe')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(
    contentItem.codePayload,
    '<a href="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer" target="{&quot;displayHeight&quot;:600,&quot;displayWidth&quot;:800,&quot;presentationDocumentTarget&quot;:&quot;iframe&quot;}" class="lti-thumbnail-launch"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux thumbnail iframe" style="height: 128px; width: 128px;"></a>'
  )
})

test("Handles LTI link with presentation target of 'window' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_thumb_window)
  equal(contentItem.text, 'Arch Linux thumbnail window')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(
    contentItem.codePayload,
    '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer" target="_blank"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux thumbnail window" style="height: 128px; width: 128px;"></a>'
  )
})

test("Handles LTI link with presentation target of 'embed' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_embed)
  equal(contentItem.text, 'Arch Linux plain embed')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(contentItem.codePayload, 'Arch Linux plain embed')
})

test("Handles LTI link with presentation target of 'frame' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_frame)
  equal(contentItem.text, 'Arch Linux plain frame')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(
    contentItem.codePayload,
    '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer">Arch Linux plain frame</a>'
  )
})

test("Handles LTI link with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_iframe)
  equal(contentItem.text, 'Arch Linux plain iframe')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(
    contentItem.codePayload,
    '<iframe src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" width="800" height="600" style="width: 800px; height: 600px;"></iframe>'
  )
})

test("Handles LTI link with presentation target of 'window' and thumbnail is *NOT* set", () => {
  const iframe = $('.mce-tinymce').find('iframe')[0]
  const tinymce_element = $(iframe)
    .find('body')
    .append('<p>&nbsp;</p>')
  tinymce_element.click
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_window)
  equal(contentItem.text, 'Arch Linux plain window')
  equal(
    contentItem.url,
    '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
  )
  equal(
    contentItem.codePayload,
    '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer" target="_blank">Arch Linux plain window</a>'
  )
})

QUnit.module('TinyMCEContentItem File Item', {
  setup() {},
  teardown() {}
})

test("Handles File item with presentation target of 'embed' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_thumb_embed)
  equal(contentItem.text, 'Arch Linux file item thumbnail embed')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(contentItem.codePayload, 'Arch Linux file item thumbnail embed')
})

test("Handles File item with presentation target of 'frame' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_thumb_frame)
  equal(contentItem.text, 'Arch Linux file item thumbnail frame')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux file item thumbnail frame" style="height: 128px; width: 128px;"></a>'
  )
})

test("Handles File item with presentation target of 'iframe' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_thumb_iframe)
  equal(contentItem.text, 'Arch Linux file item thumbnail iframe')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    '<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" width="800" height="600" style="width: 800px; height: 600px;"></iframe>'
  )
})

test("Handles File item with presentation target of 'window' and thumbnail is set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_thumb_window)
  equal(contentItem.text, 'Arch Linux file item thumbnail window')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" target="_blank"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux file item thumbnail window" style="height: 128px; width: 128px;"></a>'
  )
})

test("Handles File item with presentation target of 'embed' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_embed)
  equal(contentItem.text, 'Arch Linux file item embed')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(contentItem.codePayload, 'Arch Linux file item embed')
})

test("Handles File item with presentation target of 'frame' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_frame)
  equal(contentItem.text, 'Arch Linux file item frame')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer">Arch Linux file item frame</a>'
  )
})

test("Handles File item with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_iframe)
  equal(contentItem.text, 'Arch Linux file item iframe')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    '<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" width="800" height="600" style="width: 800px; height: 600px;"></iframe>'
  )
})

test("Handles File item with presentation target of 'window' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_window)
  equal(contentItem.text, 'Arch Linux file item window')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" target="_blank">Arch Linux file item window</a>'
  )
})

test('Preserves formatting if a selection is present', () => {
  const originalTinyMCE = window.tinyMCE
  const getContentStub = sinon.stub()
  getContentStub.returns('<em><strong>formatted selection</strong></em>')
  const tinyMCEDouble = {activeEditor: {selection: {getContent: getContentStub}}}
  window.tinyMCE = tinyMCEDouble
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_window)
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" target="_blank"><em><strong>formatted selection</strong></em></a>'
  )
  window.tinyMCE = originalTinyMCE
})

test('Uses the content item text if no selection is present', () => {
  const originalTinyMCE = window.tinyMCE
  const getContentStub = sinon.stub()
  getContentStub.returns('')
  const tinyMCEDouble = {activeEditor: {selection: {getContent: getContentStub}}}
  window.tinyMCE = tinyMCEDouble
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_window)
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" target="_blank">Arch Linux file item window</a>'
  )
  window.tinyMCE = originalTinyMCE
})

test('Uses the content item title if no selection is present', () => {
  const originalTinyMCE = window.tinyMCE
  const getContentStub = sinon.stub()
  getContentStub.returns('')
  const tinyMCEDouble = {activeEditor: {selection: {getContent: getContentStub}}}
  window.tinyMCE = tinyMCEDouble
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_window_no_text)
  equal(
    contentItem.codePayload,
    '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" target="_blank">Its like sexy for your computer</a>'
  )
  window.tinyMCE = originalTinyMCE
})
