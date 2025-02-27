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
  },
)

describe('RceLti11ContentItem LTI Link', () => {
  it("Handles LTI link with presentation target of 'embed' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_embed)
    expect(contentItem.text).toEqual('Arch Linux thumbnail embed')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Arch Linux thumbnail embed')
  })

  it("Handles LTI link with presentation target of 'frame' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_frame)
    expect(contentItem.text).toEqual('Arch Linux thumbnail frame')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" style="height: 128px; width: 128px;" alt="Arch Linux thumbnail frame"></a>',
    )
  })

  it("Handles LTI link with presentation target of 'iframe' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_iframe)
    expect(contentItem.text).toEqual('Arch Linux thumbnail iframe')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" target="{&quot;displayHeight&quot;:600,&quot;displayWidth&quot;:800,&quot;presentationDocumentTarget&quot;:&quot;iframe&quot;}" class="lti-thumbnail-launch"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" style="height: 128px; width: 128px;" alt="Arch Linux thumbnail iframe"></a>',
    )
  })

  it("Handles LTI link with presentation target of 'window' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_thumb_window)
    expect(contentItem.text).toEqual('Arch Linux thumbnail window')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" target="_blank"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" style="height: 128px; width: 128px;" alt="Arch Linux thumbnail window"></a>',
    )
  })

  it("Handles LTI link with presentation target of 'embed' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_embed)
    expect(contentItem.text).toEqual('Arch Linux plain embed')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Arch Linux plain embed')
  })

  it("Handles LTI link with presentation target of 'frame' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_frame)
    expect(contentItem.text).toEqual('Arch Linux plain frame')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer">Arch Linux plain frame</a>',
    )
  })

  it("Handles LTI link with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_iframe, iframeEnv)

    expect(contentItem.text).toEqual('Arch Linux plain iframe')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?display=borderless&url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="microphone; camera; midi" style="width: 800px; height: 600px;" width="800" height="600"></iframe>`,
    )
  })

  it("Handles LTI link with presentation target of 'window' and thumbnail is *NOT* set", () => {
    const iframe = document.querySelector('.mce-tinymce iframe')
    if (iframe instanceof HTMLIFrameElement) {
      const iframeBody = iframe.contentDocument?.body
      if (iframeBody) {
        const paragraph = document.createElement('p')
        paragraph.innerHTML = '&nbsp;'
        iframeBody.appendChild(paragraph)
        iframeBody.click()
      }
    }
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.lti_window)
    expect(contentItem.text).toEqual('Arch Linux plain window')
    expect(contentItem.url).toEqual(
      '/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti',
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="/courses/1/external_tools/retrieve?url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" target="_blank">Arch Linux plain window</a>',
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
        '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux file item thumbnail frame" style="height: 128px; width: 128px;"></a>',
      ),
    )
  })

  it("Handles File item with presentation target of 'iframe' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_thumb_iframe,
      iframeEnv,
    )
    expect(contentItem.text).toEqual('Arch Linux file item thumbnail iframe')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="microphone; camera; midi" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`,
    )
  })

  it("Handles File item with presentation target of 'window' and thumbnail is set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_thumb_window)
    expect(contentItem.text).toEqual('Arch Linux file item thumbnail window')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank"><img src="http://www.runeaudio.com/assets/img/banner-archlinux.png" alt="Arch Linux file item thumbnail window" style="height: 128px; width: 128px;"></a>',
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
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer">Arch Linux file item frame</a>',
    )
  })

  it("Handles File item with presentation target of 'iframe' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_iframe,
      iframeEnv,
    )
    expect(contentItem.text).toEqual('Arch Linux file item iframe')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe src="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="microphone; camera; midi" width="800" height="600" style="width: 800px; height: 600px;"></iframe>`,
    )
  })

  it("Handles File item with presentation target of 'window' and thumbnail is *NOT* set", () => {
    const contentItem = RceLti11ContentItem.fromJSON(exampleLti11ContentItems.text_window)
    expect(contentItem.text).toEqual('Arch Linux file item window')
    expect(contentItem.url).toEqual('http://lti-tool-provider-example.dev/test_file.txt')
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank">Arch Linux file item window</a>',
    )
  })

  it('Preserves formatting if a selection is present', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_window,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          editorSelection: '<em><strong>formatted selection</strong></em>',
        },
      ),
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank"><em><strong>formatted selection</strong></em></a>',
    )
  })

  it('Uses the content item text if no selection is present', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_window,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          editorSelection: '',
        },
      ),
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank">Arch Linux file item window</a>',
    )
  })

  it('Uses the content item title if no selection is present', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      exampleLti11ContentItems.text_window_no_text,
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {
          editorSelection: '',
        },
      ),
    )

    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://lti-tool-provider-example.dev/test_file.txt" title="Its like for your computer" target="_blank">Its like for your computer</a>',
    )
  })
})

describe('RceLti11ContentItem image content', () => {
  it('handles missing dimensions gracefully', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      text: 'Test Image',
      url: 'http://example.com/test.jpg',
      mediaType: 'image/jpeg',
      placementAdvice: {
        presentationDocumentTarget: 'embed',
      },
    })

    const payload = contentItem.codePayload
    expect(payload).toContain('<img')
    expect(payload).toContain('src="http://example.com/test.jpg"')
    expect(payload).not.toContain('style=')
  })

  it('handles empty text gracefully', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      url: 'http://example.com/test.jpg',
      mediaType: 'image/jpeg',
      placementAdvice: {
        presentationDocumentTarget: 'embed',
      },
    })

    const payload = contentItem.codePayload
    expect(payload).toContain('<img')
    expect(payload).toContain('src="http://example.com/test.jpg"')
    expect(payload).not.toContain('alt=')
  })

  it('handles non-image media types with embed target', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      text: 'PDF Document',
      url: 'http://example.com/document.pdf',
      mediaType: 'application/pdf',
      placementAdvice: {
        presentationDocumentTarget: 'embed',
        displayWidth: '800',
        displayHeight: '600',
      },
    })

    const payload = contentItem.codePayload
    expect(payload).toBe('PDF Document')
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
        },
      ),
    )

    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe data-studio-convertible-to-link="true" data-studio-resizable="false" data-studio-tray-enabled="false" src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="undefined" style="width: 800px; height: 600px;" width="800" height="600"></iframe>`,
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
        },
      ),
    )

    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      `<iframe data-studio-convertible-to-link="true" data-studio-resizable="true" data-studio-tray-enabled="true" src="/courses/1/external_tools/retrieve?display=borderless&amp;url=http%3A%2F%2Flti-tool-provider-example.dev%2Fmessages%2Fblti" title="Its like for your computer" allowfullscreen="true" webkitallowfullscreen="true" mozallowfullscreen="true" allow="undefined" style="width: 800px; height: 600px; display: inline-block;" width="800" height="600"></iframe>`,
    )
  })
})

describe('Additional RceLti11ContentItem Tests', () => {
  it('Handles missing url gracefully', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      text: 'No URL item',
      mediaType: 'application/pdf',
      placementAdvice: {presentationDocumentTarget: 'embed'},
    })
    expect(contentItem.url).toBeUndefined()
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'No URL item')
  })

  it('Handles null properties gracefully', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      text: null,
      url: null,
      mediaType: null,
      placementAdvice: {presentationDocumentTarget: 'embed'},
    })
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, '')
  })

  it('Handles no mediaType gracefully', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      text: 'No Media',
      url: 'http://example.com/',
      placementAdvice: {presentationDocumentTarget: 'frame'},
    })
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://example.com/">No Media</a>',
    )
  })

  it('Handles custom attributes without Studio (no custom property)', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'application/vnd.ims.lti.v1.launch+json',
      url: 'http://example.com/lti',
      text: 'No Custom',
      placementAdvice: {presentationDocumentTarget: 'iframe'},
    })
    // Should still produce an iframe without studio attributes
    const payload = contentItem.codePayload
    expect(payload).toContain('<iframe')
    expect(payload).not.toContain('data-studio-')
  })

  it('Falls back gracefully for unknown docTarget', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      text: 'Unknown Target',
      url: 'http://example.com/',
      mediaType: 'text/html',
      placementAdvice: {presentationDocumentTarget: 'unknown'},
    })
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://example.com/">Unknown Target</a>',
    )
  })

  it('Handles undefined ltiIframeAllowPolicy', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      {
        mediaType: 'application/vnd.ims.lti.v1.launch+json',
        url: 'http://example.com/lti',
        text: 'No Policy',
        placementAdvice: {presentationDocumentTarget: 'iframe'},
      },
      createDeepMockProxy<ExternalToolsEnv>({}, {ltiIframeAllowPolicy: undefined}),
    )
    expect(contentItem.codePayload).toContain('allowfullscreen="true"')
    expect(contentItem.codePayload).not.toContain('allow="undefined"')
  })

  it('Sanitizes javascript: URLs', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'application/pdf',
       
      url: 'javascript:alert(1)',
      text: 'Injected',
      placementAdvice: {presentationDocumentTarget: 'frame'},
    })
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="#javascript:alert(1)">Injected</a>',
    )
  })

  it('Preserves complex selection HTML', () => {
    const contentItem = RceLti11ContentItem.fromJSON(
      {
        mediaType: 'application/pdf',
        url: 'http://example.com/doc.pdf',
        title: 'Complex Selection',
        placementAdvice: {presentationDocumentTarget: 'frame'},
      },
      createDeepMockProxy<ExternalToolsEnv>(
        {},
        {editorSelection: '<strong><em>BoldItalic</em></strong>'},
      ),
    )
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://example.com/doc.pdf" title="Complex Selection"><strong><em>BoldItalic</em></strong></a>',
    )
  })

  it('Handles thumbnail missing @id', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'application/pdf',
      url: 'http://example.com/doc.pdf',
      text: 'No Thumbnail ID',
      thumbnail: {height: 128, width: 128},
      placementAdvice: {presentationDocumentTarget: 'frame'},
    })
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://example.com/doc.pdf">No Thumbnail ID</a>',
    )
  })

  it('Handles invalid displayWidth/Height', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'image/jpeg',
      url: 'http://example.com/image.jpg',
      text: 'Invalid Dimensions',
      placementAdvice: {
        presentationDocumentTarget: 'embed',
        displayWidth: 'abc',
        displayHeight: 'xyz',
      },
    })
    const payload = contentItem.codePayload
    expect(payload).toContain('<img')
    expect(payload).not.toContain('width="abc"')
    expect(payload).not.toContain('height="xyz"')
  })

  it('Handles numeric width/height for images correctly', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'image/png',
      url: 'http://example.com/image.png',
      text: 'Numeric Dimensions',
      placementAdvice: {
        presentationDocumentTarget: 'embed',
        displayWidth: 200,
        displayHeight: 300,
      },
    })
    const payload = contentItem.codePayload
    expect(payload).toContain('style="width: 200px; height: 300px;"')
  })

  it('Non-image embed target falls back to text', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'application/pdf',
      url: 'http://example.com/doc.pdf',
      text: 'Non-image embed',
      placementAdvice: {presentationDocumentTarget: 'embed'},
    })
    equalHtmlIgnoringAttributeOrder(contentItem.codePayload, 'Non-image embed')
  })

  it('Correctly identifies non-LTI content', () => {
    const contentItem = RceLti11ContentItem.fromJSON({
      mediaType: 'text/html',
      url: 'http://example.com',
      text: 'Not LTI',
      placementAdvice: {presentationDocumentTarget: 'frame'},
    })
    expect(contentItem.isLTI).toBe(false)
    equalHtmlIgnoringAttributeOrder(
      contentItem.codePayload,
      '<a href="http://example.com">Not LTI</a>',
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
