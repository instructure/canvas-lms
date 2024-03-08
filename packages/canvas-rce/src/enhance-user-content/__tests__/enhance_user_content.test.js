/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {enhanceUserContent} from '../enhance_user_content'
import {Mathml} from '../mathml'

jest.useFakeTimers()

const subject = bodyHTML => {
  document.body.querySelector('.user_content').innerHTML = `${bodyHTML}`
  return document.body
}

describe('enhanceUserContent()', () => {
  let elem

  beforeEach(() => {
    elem = document.createElement('div')
    elem.setAttribute('class', 'user_content')
    document.body.appendChild(elem)
  })

  afterEach(() => {
    document.body.removeChild(elem)
  })

  describe('when an img has a src that matches a canvas file path', () => {
    it('makes relative src absolute', () => {
      subject('<img id="relative_img" src="/files/1?download_frd=1" />')

      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})

      expect(document.getElementById('relative_img').getAttribute('src')).toEqual(
        'https://canvas.is.here:2000/files/1?download_frd=1'
      )
    })

    it('does not change absolute src', () => {
      subject(
        '<img id="relative_img" src="https://canvas.is.not.here:3000/files/1?download_frd=1" />'
      )

      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})

      expect(document.getElementById('relative_img').getAttribute('src')).toEqual(
        'https://canvas.is.not.here:3000/files/1?download_frd=1'
      )
    })

    it('sets the alt text on hidden images', () => {
      subject('<img id="relative_img" src="/files/1?download_frd=1&hidden=1" />')

      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})

      expect(document.getElementById('relative_img').getAttribute('alt')).toEqual(
        'This image is currently unavailable'
      )
    })
  })

  describe('when an iframe has a src that matches a canvas file path', () => {
    it('makes relative src absolute', () => {
      subject('<iframe id="relative_iframe" src="/media_object_iframe" />')

      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})

      expect(document.getElementById('relative_iframe').getAttribute('src')).toEqual(
        'https://canvas.is.here:2000/media_object_iframe'
      )
    })

    it('does not change absolute src', () => {
      subject(
        '<img id="relative_iframe" src="https://canvas.is.not.here:3000/files/1?download_frd=1" />'
      )

      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})

      expect(document.getElementById('relative_iframe').getAttribute('src')).toEqual(
        'https://canvas.is.not.here:3000/files/1?download_frd=1'
      )
    })
  })

  describe('when given a containingCanvasLtiToolId', () => {
    const opts = {
      canvasOrigin: 'https://canvas.is.here:2000/',
      containingCanvasLtiToolId: 'toolid',
    }

    it('adds parent_frame_context to relative canvas urls', () => {
      subject('<iframe id="iframe" src="/media_object_iframe" />')

      enhanceUserContent(document, opts)

      expect(document.getElementById('iframe').src).toEqual(
        'https://canvas.is.here:2000/media_object_iframe?parent_frame_context=toolid'
      )
    })

    it('adds parent_frame_context to absolute canvas urls', () => {
      subject('<iframe id="iframe" src="https://canvas.is.here:2000/files/1?download_frd=1" />')

      enhanceUserContent(document, opts)

      expect(document.getElementById('iframe').getAttribute('src')).toEqual(
        'https://canvas.is.here:2000/files/1?download_frd=1&parent_frame_context=toolid'
      )
    })

    it('does not add parent_frame_context to non-canvas urls', () => {
      subject('<iframe id="iframe" src="https://canvas.is.not.here:3000/files/1?download_frd=1" />')

      enhanceUserContent(document, opts)

      expect(document.getElementById('iframe').getAttribute('src')).toEqual(
        'https://canvas.is.not.here:3000/files/1?download_frd=1'
      )
    })
  })

  describe('when tool launch iframe has display=in_rce', () => {
    const canvasOrigin = 'https://canvas.is.here:2000/'

    it('replaces with display=borderless', () => {
      subject(
        `<iframe id="iframe" src="${canvasOrigin}courses/1/external_tools/retrieve?display=in_rce" />`
      )

      enhanceUserContent(document, {canvasOrigin})

      expect(document.getElementById('iframe').getAttribute('src')).toEqual(
        `${canvasOrigin}courses/1/external_tools/retrieve?display=borderless`
      )
    })
  })

  describe('when a link has an href that matches a canvas file path', () => {
    it('makes relative links absolute', () => {
      subject(
        '<a id="relative_link" class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1">file</a>'
      )
      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})
      expect(document.getElementById('relative_link').getAttribute('href')).toEqual(
        'https://canvas.is.here:2000/courses/1/files/1'
      )
    })

    it('does not make internal links absolute', () => {
      subject('<a id="internal_link" href="#tabs-1">this happens for jquery tags</a>')
      enhanceUserContent(document, {canvasOrigin: 'https://canvas.is.here:2000/'})
      expect(document.getElementById('internal_link').getAttribute('href')).toEqual('#tabs-1')
    })

    it('enhances the link', () => {
      subject(
        '<a class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1">file</a>'
      )
      enhanceUserContent()
      expect(document.querySelector('.instructure_file_holder')).toBeInTheDocument()
    })

    it('adds download icon button', () => {
      subject('<a class="instructure_file_link" href="/courses/1/files/27">file</a>')
      enhanceUserContent()
      expect(document.querySelector('a.file_download_btn')).toBeInTheDocument()
    })

    describe('when the link has no href attribute', () => {
      it('does not enhance the link', () => {
        subject('<a class="instructure_file_link instructure_scribd_file">file</a>')
        enhanceUserContent()
        expect(
          document.querySelector('.instructure_file_link.instructure_scribd_file')
        ).toBeInTheDocument()
        expect(document.querySelector('.instructure_file_holder')).not.toBeInTheDocument()
      })
    })

    describe('when the link has inline_disabled class', () => {
      it('has the preview_in_overlay class and the target attribute', () => {
        subject(
          '<a class="instructure_file_link instructure_scribd_file inline_disabled" href="/courses/1/files/1" target="_blank">file</a>'
        )
        enhanceUserContent()
        const aTag = document.querySelector('a')
        expect(aTag.classList.value).toEqual('inline_disabled preview_in_overlay')
        expect(aTag).toHaveAttribute('target')
      })
    })

    describe('when the link has no_preview class', () => {
      it('has href attribute as the download link and does not have the target atrribute.', () => {
        subject(
          '<a class="instructure_file_link instructure_scribd_file no_preview" href="/courses/1/files/1" target="_blank">file</a>'
        )
        enhanceUserContent()
        const aTag = document.querySelector('a')
        expect(aTag.classList.value).toEqual('no_preview')
        expect(aTag.getAttribute('href')).toEqual(
          'http://localhost/courses/1/files/1/download?download_frd=1'
        )
        expect(aTag).not.toHaveAttribute('target')
        // it still gets the download button
        expect(document.querySelector('a.file_download_btn')).toBeInTheDocument()
      })
    })

    describe('when the link has neither inline_disabled class or no_preview class', () => {
      it('has the file_preview_link class and the target attribute', () => {
        subject(
          '<a id="alink" class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1" target="_blank">file</a>'
        )
        enhanceUserContent()
        const aTag = document.querySelector('a')
        expect(aTag.classList.contains('file_preview_link')).toBeTruthy()
        expect(aTag).toHaveAttribute('target')
      })
    })
  })

  describe('internal links target attribute', () => {
    it('is set to the provided options', () => {
      // which is the case for img file links
      subject(
        `<a id="blank_target" title="Link" href="/courses/1/files/79?wrap=1" target="_blank">some file</a>
        <a id="no_target" title="Link" href="/courses/1/files/79?wrap=1">a file</a>
        <a id="a_target" title="Link" href="/courses/1/files/79?wrap=1" target="a_target">another file</a>`
      )
      enhanceUserContent(document, {
        canvasOrigin: 'https://canvas.here',
        canvasLinksTarget: 'open_here',
      })

      expect(document.getElementById('blank_target').getAttribute('target')).toEqual('open_here')
      expect(document.getElementById('no_target').getAttribute('target')).toEqual('open_here')
      expect(document.getElementById('a_target').getAttribute('target')).toEqual('a_target')
    })
  })

  describe('external links', () => {
    it('adds the exernal link icon', () => {
      subject('<a href="https://instructure.com/">external link</a>')
      enhanceUserContent()
      expect(document.querySelector('span.external_link_icon svg')).toBeInTheDocument()
    })

    it('adds target=_blank', () => {
      subject('<a href="https://instructure.com/">external link</a>')
      enhanceUserContent()
      expect(document.querySelector('a.external').getAttribute('target')).toEqual('_blank')
    })
  })

  describe('enhanceUserContent:media', () => {
    beforeAll(() => {
      window.INST = {kalturaSettings: {}}
    })
    describe('links to youtube videos', () => {
      it('youtube preview gets alt text from link data-preview-alt', () => {
        const alt = 'test alt string'
        subject(
          `<a href="https://youtu.be/xyzzy" class="instructure_video_link" data-preview-alt="${alt}">Link</a>`
        )
        enhanceUserContent()
        expect(document.querySelector('a.youtubed')).toBeInTheDocument()
        const thumbnail = document.querySelector('.media_comment_thumbnail')
        expect(thumbnail).toBeInTheDocument()
        expect(thumbnail.alt).toEqual(alt)
      })

      it('youtube preview ignores missing alt', () => {
        subject(
          '<a href="https://youtu.be/xyzzy" class="instructure_video_link" data-media_comment_id="27" >Link</a>'
        )
        enhanceUserContent()
        expect(document.querySelector('a.youtubed')).toBeInTheDocument()
        const thumbnail = document.querySelector('.media_comment_thumbnail')
        expect(thumbnail).toBeInTheDocument()
        expect(thumbnail.alt).toEqual('')
      })
    })
    describe('links to canvas media', () => {
      it("enhance '.instructure_inline_media_comment' in questions", () => {
        subject(`<div class="answers">
          <a href="#" class="instructure_inline_media_comment instructure_video_link" data-media_comment_id="27" >
            link
          </a> `)
        enhanceUserContent()
        jest.runAllTimers()
        expect(document.querySelector('.instructure_inline_media_comment')).toBeInTheDocument()
        expect(document.querySelector('.instructure_video_link')).toBeInTheDocument()
      })
    })
  })

  describe('customEnhanceFunc', () => {
    it('is called if provided', () => {
      subject('<p>hello world</p>')
      const customFunc = jest.fn()
      enhanceUserContent(document, {customEnhanceFunc: customFunc})
      expect(customFunc).toHaveBeenCalledTimes(1)
    })
  })

  describe('math rendering', () => {
    beforeEach(() => {
      jest.resetAllMocks()
    })

    it('processes math inside content when ELT is on', () => {
      const processSpy = jest.spyOn(Mathml.prototype, 'processNewMathInElem')
      subject('<p>anything</p>')
      enhanceUserContent(document, {explicit_latex_typesetting: true})
      expect(processSpy).toHaveBeenCalledWith(elem)
    })

    it('does not process math inside content when ELT is off', () => {
      const processSpy = jest.spyOn(Mathml.prototype, 'processNewMathInElem')
      subject('<p>anything</p>')
      enhanceUserContent(document, {explicit_latex_typesetting: false})
      expect(processSpy).not.toHaveBeenCalled()
    })
  })

  describe('addResourceIdentifiersToStudioContent', () => {
    beforeEach(() => {
      const userContent = document.querySelector('.user_content')
      userContent.dataset.resourceType = 'assignment.body'
      userContent.dataset.resourceId = '123'
    })

    it('adds resource identifiers to studio iframe', () => {
      subject(
        '<p><iframe class="lti-embed" title="small_video" src="http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D902318c4-cc8d-4c4d-95dd-5d955f6dc5af-8%26custom_arc_start_at%3D0"></iframe></p>'
      )
      enhanceUserContent()
      const iframe = document.querySelector('iframe')
      expect(iframe.src).toEqual(
        'http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D902318c4-cc8d-4c4d-95dd-5d955f6dc5af-8%26custom_arc_start_at%3D0&com_instructure_course_canvas_resource_type=assignment.body&com_instructure_course_canvas_resource_id=123'
      )
    })

    it('adds resource identifiers to multiple studio iframes', () => {
      subject(
        '<p><iframe class="lti-embed" title="small_video" src="http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D902318c4-cc8d-4c4d-95dd-5d955f6dc5af-8%26custom_arc_start_at%3D0"></iframe></p><p><iframe class="lti-embed" title="small_video" src="http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D902318c4-cc8d-4c4d-95dd-5d955f6dc5ae-8%26custom_arc_start_at%3D0"></iframe></p>'
      )
      enhanceUserContent()
      const iframes = document.querySelectorAll('iframe')
      expect(iframes[0].src).toEqual(
        'http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D902318c4-cc8d-4c4d-95dd-5d955f6dc5af-8%26custom_arc_start_at%3D0&com_instructure_course_canvas_resource_type=assignment.body&com_instructure_course_canvas_resource_id=123'
      )
      expect(iframes[1].src).toEqual(
        'http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D902318c4-cc8d-4c4d-95dd-5d955f6dc5ae-8%26custom_arc_start_at%3D0&com_instructure_course_canvas_resource_type=assignment.body&com_instructure_course_canvas_resource_id=123'
      )
    })

    it('ignores non-studio iframes', () => {
      subject(
        '<p><iframe class="lti-embed" title="something else" src="http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.somethingelse.com"></iframe></p>'
      )
      enhanceUserContent()
      const iframe = document.querySelector('iframe')
      expect(iframe.src).toEqual(
        'http://localhost/courses/1/external_tools/retrieve?display=in_rce&url=https%3A%2F%2Fbeta.somethingelse.com'
      )
    })
  })
})
