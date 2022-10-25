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
          '<a class="instructure_file_link instructure_scribd_file" href="/courses/1/files/1" target="_blank">file</a>'
        )
        enhanceUserContent()
        const aTag = document.querySelector('a')
        expect(aTag.classList.contains('file_preview_link')).toBeTruthy()
        expect(aTag).toHaveAttribute('target')
      })
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
})
