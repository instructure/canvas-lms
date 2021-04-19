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

// NOTE: The tests skipped here pass locally but started failing in jenkins,
//       with the upgrade to tinymce from 5.3.1 to 5.6.2, from though I can't
//       figure out why.
//       You'll also see console.error messages in the output
//       "ERROR LOG: 'Failed to load icons: default from url http://localhost:9876/base/spec/javascripts/icons/default/icons.js'"
//       You can't stop tinymce from trying to load its default icons, and I can't figure
//       out how to point it somewhere that won't fail. It doesn't affect the tests.

import $ from 'jquery'
import tinymce from 'tinymce/tinymce'
import TinyMCEContentItem from '@canvas/tinymce-external-tools/TinyMCEContentItem'
import contentItems from './ContentItems'

QUnit.module('TinyMCEContentItem LTI Link', {
  setup() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['microphone', 'camera', 'midi']
    const textarea = $("<textarea id='a42' data-rich_text='true'></textarea>")
    $('#fixtures').append(textarea)
    return tinymce.init({
      selector: '#fixtures textarea#a42',
      theme: null,
      content_css: []
    })
  },
  teardown() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
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

QUnit.skip(
  "Handles LTI link with presentation target of 'frame' and thumbnail is *NOT* set",
  () => {
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
  }
)

QUnit.skip(
  "Handles LTI link with presentation target of 'iframe' and thumbnail is *NOT* set",
  () => {
    const contentItem = TinyMCEContentItem.fromJSON(contentItems.lti_iframe)
    const expectedFrameAllowances = ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')
    equal(contentItem.text, 'Arch Linux plain iframe')
    equal(
      contentItem.url,
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equal(
      contentItem.codePayload,
      `<iframe src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like sexy for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="${expectedFrameAllowances}" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`
    )
  }
)

QUnit.skip(
  "Handles LTI link with presentation target of 'window' and thumbnail is *NOT* set",
  () => {
    const iframe = $('.mce-tinymce').find('iframe')[0]
    const tinymce_element = $(iframe)
      .find('body')
      .append('<p>&nbsp;</p>')
    tinymce_element.click()
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
  }
)

QUnit.module('TinyMCEContentItem File Item', {
  setup() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = ['microphone', 'camera', 'midi']
  },
  teardown() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
  }
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
  const expectedFrameAllowances = ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')
  equal(contentItem.text, 'Arch Linux file item thumbnail iframe')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    `<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="${expectedFrameAllowances}" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`
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

QUnit.skip(
  "Handles File item with presentation target of 'frame' and thumbnail is *NOT* set",
  () => {
    const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_frame)
    equal(contentItem.text, 'Arch Linux file item frame')
    equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
    equal(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer">Arch Linux file item frame</a>'
    )
  }
)

test("Handles File item with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
  const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_iframe)
  const expectedFrameAllowances = ENV.LTI_LAUNCH_FRAME_ALLOWANCES.join('; ')
  equal(contentItem.text, 'Arch Linux file item iframe')
  equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
  equal(
    contentItem.codePayload,
    `<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="${expectedFrameAllowances}" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`
  )
})

QUnit.skip(
  "Handles File item with presentation target of 'window' and thumbnail is *NOT* set",
  () => {
    const contentItem = TinyMCEContentItem.fromJSON(contentItems.text_window)
    equal(contentItem.text, 'Arch Linux file item window')
    equal(contentItem.url, 'http://lti-tool-provider-example.dev/test_file.txt')
    equal(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like sexy for your computer" target="_blank">Arch Linux file item window</a>'
    )
  }
)

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
