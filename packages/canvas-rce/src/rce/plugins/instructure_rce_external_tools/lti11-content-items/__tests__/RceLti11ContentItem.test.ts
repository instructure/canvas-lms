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
//       "ERROR LOG: 'Failed to load icons: default from url http://localhost:9876/base/spec/javascripts/icons/default/icons'"
//       You can't stop tinymce from trying to load its default icons, and I can't figure
//       out how to point it somewhere that won't fail. It doesn't affect the tests.

import {ExternalToolsEnv} from '../../ExternalToolsEnv'
import {RceLti11ContentItem} from '../RceLti11ContentItem'
import {exampleLti11ContentItems} from './exampleLti11ContentItems'
import {createDeepMockProxy} from '../../../../../util/__tests__/deepMockProxy'

const iframeEnv = createDeepMockProxy<ExternalToolsEnv>(
  {},
  {
    ltiIframeAllowPolicy: 'microphone; camera; midi',
  }
)

describe('RceLti11ContentItem LTI Link', () => {
  it("Handles LTI link with presentation target of 'embed' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_embed)
    expect(contentItem.text).toEqual('Arch Linux thumbnail embed')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Arch Linux thumbnail embed')
  })

  it("Handles LTI link with presentation target of 'frame' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_frame)
    expect(contentItem.text).toEqual('Arch Linux thumbnail frame')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" style="height: 128px; width: 128px;" alt="Arch Linux thumbnail frame"></a>'
    )
  })

  it("Handles LTI link with presentation target of 'iframe' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_iframe)
    expect(contentItem.text).toEqual('Arch Linux thumbnail iframe')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" target="{&quot;displayHeight&quot;:600,&quot;displayWidth&quot;:800,&quot;presentationDocumentTarget&quot;:&quot;iframe&quot;}" class="lti-thumbnail-launch"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" style="height: 128px; width: 128px;" alt="Arch Linux thumbnail iframe"></a>'
    )
  })

  it("Handles LTI link with presentation target of 'window' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_window)
    expect(contentItem.text).toEqual('Arch Linux thumbnail window')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" target="_blank"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" style="height: 128px; width: 128px;" alt="Arch Linux thumbnail window"></a>'
    )
  })

  it("Handles LTI link with presentation target of 'embed' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_embed)
    expect(contentItem.text).toEqual('Arch Linux plain embed')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Arch Linux plain embed')
  })

  it("Handles LTI link with presentation target of 'frame' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_frame)
    expect(contentItem.text).toEqual('Arch Linux plain frame')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer">Arch Linux plain frame</a>'
    )
  })

  it("Handles LTI link with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_iframe, iframeEnv)

    expect(contentItem.text).toEqual('Arch Linux plain iframe')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="microphone; camera; midi" style="width: 800px; height: 600px;" width="800" height="600"></iframe>`
    )
  })

  it("Handles LTI link with presentation target of 'window' and thumbnail is *NOT* set", () => {
    const iframe = $('.mce-tinymce').find('iframe')[0]
    const tinymce_element = $(iframe).find('body').append('<p>&nbsp;</p>')
    tinymce_element.click()
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_window)
    expect(contentItem.text).toEqual('Arch Linux plain window')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti'
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" target="_blank">Arch Linux plain window</a>'
    )
  })
})

describe('RceLti11ContentItem File Item', () => {
  it("Handles File item with presentation target of 'embed' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_thumb_embed)
    expect(contentItem.text).toEqual('Arch Linux file item thumbnail embed')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Arch Linux file item thumbnail embed')
  })

  it("Handles File item with presentation target of 'frame' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_thumb_frame)
    expect(contentItem.text).toEqual('Arch Linux file item thumbnail frame')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      normalizeAttributeOrder(
        '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux file item thumbnail frame" style="height: 128px; width: 128px;"></a>'
      )
    )
  })

  it("Handles File item with presentation target of 'iframe' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_thumb_iframe,
      iframeEnv
    )
    expect(contentItem.text).toEqual('Arch Linux file item thumbnail iframe')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="microphone; camera; midi" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`
    )
  })

  it("Handles File item with presentation target of 'window' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_thumb_window)
    expect(contentItem.text).toEqual('Arch Linux file item thumbnail window')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux file item thumbnail window" style="height: 128px; width: 128px;"></a>'
    )
  })

  it("Handles File item with presentation target of 'embed' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_embed)
    expect(contentItem.text).toEqual('Arch Linux file item embed')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Arch Linux file item embed')
  })

  it("Handles File item with presentation target of 'frame' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_frame)
    expect(contentItem.text).toEqual('Arch Linux file item frame')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer">Arch Linux file item frame</a>'
    )
  })

  it("Handles File item with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_iframe,
      iframeEnv
    )
    expect(contentItem.text).toEqual('Arch Linux file item iframe')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="microphone; camera; midi" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`
    )
  })

  it("Handles File item with presentation target of 'window' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_window)
    expect(contentItem.text).toEqual('Arch Linux file item window')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank">Arch Linux file item window</a>'
    )
  })

  it('Preserves formatting if a selection is present', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_window,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          editorSelection: '<em><strong>formatted selection</strong></em>',
        }
      )
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank"><em><strong>formatted selection</strong></em></a>'
    )
  })

  it('Uses the content item text if no selection is present', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_window,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          editorSelection: '',
        }
      )
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank">Arch Linux file item window</a>'
    )
  })

  it('Uses the content item title if no selection is present', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_window_no_text,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          editorSelection: '',
        }
      )
    )

    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank">Its like for your computer</a>'
    )
  })
})

describe('Studio LTI content items', () => {
  it('with custom params set to false', () => {
    const itemData = {
      ...exampleLti11ContentItems.lti_iframe,
      ...{custom: {source: 'studio', resizable: false, enableMediaOptions: false}},
    }
    const contentItem = RceLti11ContentItem.fromJSON(
      itemData,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          ltiIframeAllowPolicy: 'undefined',
        }
      )
    )

    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe data-studio-convertible-to-link="true" data-studio-resizable="false" data-studio-tray-enabled="false" src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="undefined" style="width: 800px; height: 600px;" width="800" height="600"></iframe>`
    )
  })

  it('with custom params set to true', () => {
    const itemData = {
      ...exampleLti11ContentItems.lti_iframe,
      ...{custom: {source: 'studio', resizable: true, enableMediaOptions: true}},
    }
    const contentItem = RceLti11ContentItem.fromJSON(
      itemData,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          ltiIframeAllowPolicy: 'undefined',
        }
      )
    )

    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe data-studio-convertible-to-link="true" data-studio-resizable="true" data-studio-tray-enabled="true" src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="undefined" style="width: 800px; height: 600px; display: inline-block;" width="800" height="600"></iframe>`
    )
  })
})

function normalizeAttributeOrder(html: string) {
  const container = document.createElement('div')
  container.innerHTML = html
  container.querySelectorAll('*').forEach(elem => {
    const attributes = Array.from(elem.attributes)
      .map(it => [it.name, it.value])
      .sort(([a], [b]) => a.localeCompare(b))

    attributes.forEach(([name]) => elem.removeAttribute(name))
    attributes.forEach(([name, value]) => elem.setAttribute(name, value))
  })
  return container.innerHTML
}

function equalHtmlIgnoringAttributeOrder(actual: string, expected: string) {
  expect(normalizeAttributeOrder(actual)).toEqual(normalizeAttributeOrder(expected))
}
