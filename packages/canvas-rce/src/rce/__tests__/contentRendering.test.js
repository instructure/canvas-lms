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

import * as contentRendering from '../contentRendering'
import {videoFromTray, videoFromUpload, audioFromTray, audioFromUpload} from './contentHelpers'

describe('contentRendering', () => {
  describe('renderLink', () => {
    let link
    beforeEach(() => {
      link = {
        href: '/users/2/files/17/download?verifier=xyzzy',
        title: 'Here Be Links',
        text: 'Click On Me'
      }
    })

    it('uses link data to build html', () => {
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="/users/2/files/17/download?verifier=xyzzy" title="Here Be Links">Click On Me</a>'
      )
    })

    it('can use url if no href', () => {
      link.url = link.href
      link.href = undefined
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="/users/2/files/17/download?verifier=xyzzy" title="Here Be Links">Click On Me</a>'
      )
    })

    it("defaults title to 'Link'", () => {
      link.title = undefined
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="/users/2/files/17/download?verifier=xyzzy" title="Link">Click On Me</a>'
      )
    })

    it('defaults contents to title', () => {
      link.text = undefined
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="/users/2/files/17/download?verifier=xyzzy" title="Here Be Links">Here Be Links</a>'
      )
    })

    it("defaults contents to 'Link' if no title either", () => {
      link.text = undefined
      link.title = undefined
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="/users/2/files/17/download?verifier=xyzzy" title="Link">Link</a>'
      )
    })

    it('renders the link with all attributes', () => {
      const doc = {
        class: 'instructure_file_link instructure_scribd_file',
        href: '/users/2/files/17/download?verifier=xyzzy',
        target: '_blank',
        rel: 'noopener',
        text: 'somefile.pdf'
      }
      const rendered = contentRendering.renderLink(doc, doc.text)
      expect(rendered).toEqual(
        '<a ' +
          'href="/users/2/files/17/download?verifier=xyzzy" target="_blank" rel="noopener" title="Link" ' +
          'class="instructure_file_link instructure_scribd_file">' +
          'somefile.pdf</a>'
      )
    })

    it('does not swizzle the url if not our host', () => {
      link.href = 'http://example.com/users/2/files/17/download?verifier=xyzzy'
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="http://example.com/users/2/files/17/download?verifier=xyzzy" title="Here Be Links">Click On Me</a>'
      )
    })

    it('replaces a preview link with download', () => {
      link.href = '/users/2/files/17/preview?verifier=xyzzy'
      const rendered = contentRendering.renderLink(link)
      expect(rendered).toEqual(
        '<a href="/users/2/files/17/download?verifier=xyzzy" title="Here Be Links">Click On Me</a>'
      )
    })
  })

  describe('renderImage', () => {
    let image
    beforeEach(() => {
      image = {
        href: '/users/2/files/17/download?verifier=xyzzy',
        url: '/other/path',
        title: 'Here Be Images'
      }
    })

    it('builds image html from image data', () => {
      const rendered = contentRendering.renderImage(image)
      expect(rendered).toEqual(
        '<img alt="Here Be Images" src="/users/2/files/17/preview?verifier=xyzzy"/>'
      )
    })

    it('uses url if no href', () => {
      image.href = undefined
      const rendered = contentRendering.renderImage(image)
      expect(rendered).toEqual('<img alt="Here Be Images" src="/other/path"/>')
    })

    it('defaults alt text to image display_name', () => {
      image.title = undefined
      image.display_name = 'foo'
      const rendered = contentRendering.renderImage(image)
      expect(rendered).toEqual('<img alt="foo" src="/users/2/files/17/preview?verifier=xyzzy"/>')
    })

    it('includes optional other attributes', () => {
      image.foo = 'bar'
      image.style = {
        maxWidth: '100px',
        maxHeight: '17rem'
      }
      const rendered = contentRendering.renderImage(image)
      expect(rendered).toEqual(
        '<img alt="Here Be Images" src="/users/2/files/17/preview?verifier=xyzzy" foo="bar" style="max-width:100px;max-height:17rem"/>'
      )
    })

    it('builds linked image html from linked image data', () => {
      const linkElem = {
        getAttribute: () => {
          return 'http://example.com'
        }
      }

      const rendered = contentRendering.renderLinkedImage(linkElem, image)
      expect(rendered).toEqual(
        '<a href="http://example.com" data-mce-href="http://example.com"><img alt="Here Be Images" src="/users/2/files/17/preview?verifier=xyzzy"/></a>'
      )
    })
    it('renders a linked image if object has link property', () => {
      image.link = 'http://someurl'
      const rendered = contentRendering.renderImage(image)
      expect(rendered).toEqual(
        '<a href="http://someurl" target="_blank" rel="noopener noreferrer"><img alt="Here Be Images" src="/users/2/files/17/preview?verifier=xyzzy"/></a>'
      )
    })
  })

  describe('renderVideo', () => {
    it('builds iframe src from tray video data', () => {
      const video = videoFromTray()
      const src = contentRendering.mediaIframeSrcFromFile(video)
      expect(src).toEqual('/media_objects_iframe?mediahref=%2Furl%2Fto%2Fcourse%2Ffile&type=video')
    })

    it('builds iframe src from uploaded video data', () => {
      const video = videoFromUpload()
      const src = contentRendering.mediaIframeSrcFromFile(video)
      expect(src).toEqual('/url/to/m-media-id?type=video')
    })

    it('builds the html from tray video data', () => {
      const video = videoFromTray()
      const rendered = contentRendering.renderVideo(video)
      expect(rendered).toEqual(
        '<iframe allow="fullscreen" allowfullscreen="" data-media-id="17" data-media-type="video" src="/media_objects_iframe?mediahref=%2Furl%2Fto%2Fcourse%2Ffile&amp;type=video" style="width:400px;height:225px;display:inline-block" title="Video player for filename.mov"></iframe>'
      )
    })

    it('builds the html from uploaded video data', () => {
      const video = videoFromUpload()
      const rendered = contentRendering.renderVideo(video)
      expect(rendered).toEqual(
        '<iframe allow="fullscreen" allowfullscreen="" data-media-id="m-media-id" data-media-type="video" src="/url/to/m-media-id?type=video" style="width:400px;height:225px;display:inline-block" title="Video player for filename.mov"></iframe>'
      )
    })
  })

  describe('renderAudio', () => {
    it('builds iframe src from tray audio data', () => {
      const audio = audioFromTray()
      const src = contentRendering.mediaIframeSrcFromFile(audio)
      expect(src).toEqual('/media_objects_iframe?mediahref=url%2Fto%2Fcourse%2Ffile&type=audio')
    })

    it('builds iframe src from uploaded audio data', () => {
      const audio = audioFromUpload()
      const src = contentRendering.mediaIframeSrcFromFile(audio)
      expect(src).toEqual('/url/to/m-media-id?type=audio')
    })

    it('builds the html from tray audio data', () => {
      const audio = audioFromTray()
      const rendered = contentRendering.renderAudio(audio)
      expect(rendered).toEqual(
        '<iframe data-media-id="29" data-media-type="audio" src="/media_objects_iframe?mediahref=url%2Fto%2Fcourse%2Ffile&amp;type=audio" style="width:320px;height:14.25rem;display:inline-block" title="Audio player for filename.mp3"></iframe>'
      )
    })

    it('builds the html from uploaded audio data', () => {
      const audio = audioFromUpload()
      const rendered = contentRendering.renderAudio(audio)
      expect(rendered).toEqual(
        '<iframe data-media-id="m-media-id" data-media-type="audio" src="/url/to/m-media-id?type=audio" style="width:320px;height:14.25rem;display:inline-block" title="Audio player for filename.mp3"></iframe>'
      )
    })
  })
})
