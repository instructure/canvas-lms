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

import {
  LINK_TYPE,
  FILE_LINK_TYPE,
  IMAGE_EMBED_TYPE,
  NONE_TYPE,
  TEXT_TYPE,
  DISPLAY_AS_LINK,
  DISPLAY_AS_DOWNLOAD_LINK,
  getContentFromEditor,
  getContentFromElement,
  getLinkContentFromEditor,
  isFileLink,
  isImageEmbed,
  isVideoElement,
  isAudioElement,
  findMediaPlayerIframe,
} from '../ContentSelection'
import FakeEditor from '../../../__tests__/FakeEditor'

describe('RCE > Plugins > Shared > Content Selection', () => {
  let $container
  let editor

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
    editor = new FakeEditor()
    editor.initialize()
  })

  afterEach(() => {
    $container.remove()
  })

  describe('.getContentFromElement()', () => {
    let $element

    describe('when the given element is an anchor', () => {
      beforeEach(() => {
        $element = $container.appendChild(document.createElement('a'))
        $element.href = 'http://example.instructure.com/files/3201/download?download_frd=1'
        $element.textContent = 'Syllabus.doc'
      })

      it('includes the anchor element on the returned content', () => {
        expect(getContentFromElement($element, editor).$element).toEqual($element)
      })

      it('returns content of type "file link" when the anchor links to a user file', () => {
        expect(getContentFromElement($element, editor).type).toEqual(FILE_LINK_TYPE)
      })

      it('includes the text of the link', () => {
        expect(getContentFromElement($element, editor).text).toEqual('Syllabus.doc')
      })

      it('finds the selected text', () => {
        const content = getContentFromElement($element, editor)
        expect(content.text).toEqual('Syllabus.doc')
      })

      it('includes the url of the link', () => {
        expect(getContentFromElement($element, editor).url).toEqual(
          'http://example.instructure.com/files/3201/download?download_frd=1'
        )
      })

      it('returns content of type "file link" when the anchor links to a course file', () => {
        $element.href =
          'http://example.instructure.com/courses/1201/files/3201/download?download_frd=1'
        expect(getContentFromElement($element, editor).type).toEqual(FILE_LINK_TYPE)
      })

      it('ignores query parameters on the href', () => {
        $element.href = 'http://example.instructure.com/files/3201/download'
        expect(getContentFromElement($element, editor).type).toEqual(FILE_LINK_TYPE)
      })

      it('returns content of type "link" when linking to unhandled canvas content', () => {
        $element.href = 'http://example.instructure.com/courses/1201/grades'
        expect(getContentFromElement($element, editor).type).toEqual(LINK_TYPE)
      })

      it('returns content of type "link" when the anchor links to an unhandled location', () => {
        $element.href = 'http://www.example.com/foo/bar'
        expect(getContentFromElement($element, editor).type).toEqual(LINK_TYPE)
      })

      it('does not explode when the hostname has bad unicode', () => {
        $element.href = 'http://invalid%ffhostname.com/'
        expect(getContentFromElement($element, editor).type).toEqual(LINK_TYPE)
      })

      it('works with a relative path', () => {
        $element.href = '/courses/1201/files/8880/download'
        expect(getContentFromElement($element, editor).type).toEqual(FILE_LINK_TYPE)
      })

      it('returns content of type "none" when the anchor has no href attribute', () => {
        $element.removeAttribute('href')
        expect(getContentFromElement($element, editor).type).toEqual(NONE_TYPE)
      })

      it('indicates the link is previewable if it contains the "data-canvas-previewable" attribute', () => {
        expect(getContentFromElement($element, editor).isPreviewable).toEqual(false)
        $element.setAttribute('data-canvas-previewable', true)
        expect(getContentFromElement($element, editor).isPreviewable).toEqual(true)
      })

      it('indicates the link is previewable if it contains the "instructure_scribd_file" class name', () => {
        expect(getContentFromElement($element, editor).isPreviewable).toEqual(false)
        $element.classList.add('instructure_scribd_file')
        expect(getContentFromElement($element, editor).isPreviewable).toEqual(true)
      })

      it('indicates the link displays as download link if it contains the "no_preview" class name', () => {
        expect(getContentFromElement($element, editor).displayAs).toEqual(DISPLAY_AS_LINK)
        $element.classList.add('no_preview')
        expect(getContentFromElement($element, editor).displayAs).toEqual(DISPLAY_AS_DOWNLOAD_LINK)
      })

      it('includes the content type if the link contains the data course type', () => {
        $element.setAttribute('data-course-type', 'wikiPages')
        expect(getContentFromElement($element, editor).contentType).toEqual('wikiPages')
      })

      it('includes the filename if the link contains the title', () => {
        $element.title = 'Assignment 1'
        expect(getContentFromElement($element, editor).fileName).toEqual('Assignment 1')
      })

      it('includes published if the link contains data-published', () => {
        $element.setAttribute('data-published', true)
        expect(getContentFromElement($element, editor).published).toEqual(true)
      })
    })

    describe('when the given element is a video container element', () => {
      beforeEach(() => {
        $element = $container.appendChild(document.createElement('span'))
        $element.setAttribute('data-mce-p-data-media-id', '1234')
        $element.setAttribute('data-mce-p-data-media-type', 'video')
        $element.appendChild(document.createElement('iframe'))
      })

      it('returns None type if no id is present', () => {
        $element.removeAttribute('data-mce-p-data-media-id')
        expect(getContentFromElement($element, editor).type).toEqual(NONE_TYPE)
      })

      it('returns None type if there is no iframe child', () => {
        $element.innerHTML = ''
        expect(getContentFromElement($element, editor).type).toEqual(NONE_TYPE)
      })

      it('returns None type if children element is not an iframe', () => {
        $element.replaceChild(document.createElement('span'), $element.firstElementChild)
        expect(getContentFromElement($element, editor).type).toEqual(NONE_TYPE)
      })

      it('returns None if no type is present', () => {
        $element.removeAttribute('data-mce-p-data-media-type')
        expect(getContentFromElement($element, editor).type).toEqual(NONE_TYPE)
      })

      it('returns id if iframe and div are set', () => {
        $element.firstElementChild.setAttribute('src', 'data:text/html;charset=utf-8,<video/>')
        expect(getContentFromElement($element, editor).id).toEqual('1234')
      })
    })

    describe('when the given element is an image', () => {
      beforeEach(() => {
        $element = $container.appendChild(document.createElement('img'))
        $element.src = 'https://www.fillmurray.com/200/200'
        $element.alt = 'The ineffable Bill Murray'
      })

      it('includes the image element on the returned content', () => {
        expect(getContentFromElement($element, editor).$element).toEqual($element)
      })

      describe('.altText', () => {
        it('is the alt text of the image when present', () => {
          expect(getContentFromElement($element, editor).altText).toEqual(
            'The ineffable Bill Murray'
          )
        })

        it('is blank when absent on the image', () => {
          $element.removeAttribute('alt')
          expect(getContentFromElement($element, editor).altText).toEqual('')
        })
      })

      describe('.isDecorativeImage', () => {
        describe('when "role" is "presentation" on the image element', () => {
          beforeEach(() => {
            $element.setAttribute('role', 'presentation')
          })

          it('is true when the image has no alt text', () => {
            $element.alt = ''
            expect(getContentFromElement($element, editor).isDecorativeImage).toEqual(true)
          })
        })

        describe('when "role" is not "presentation" on the image element', () => {
          it('is false when the image has alt text', () => {
            expect(getContentFromElement($element, editor).isDecorativeImage).toEqual(false)
          })
        })

        it('is blank when absent on the image', () => {
          $element.alt = ''
          expect(getContentFromElement($element, editor).isDecorativeImage).toEqual(true)
        })
      })

      it('sets the url to the src of the image', () => {
        expect(getContentFromElement($element, editor).url).toEqual(
          'https://www.fillmurray.com/200/200'
        )
      })
    })

    it('returns content of type "none" when given an unhandled element', () => {
      $element = $container.appendChild(document.createElement('hr'))
      expect(getContentFromElement($element, editor).type).toEqual(NONE_TYPE)
    })

    it('returns content of type "none" when given a non-element', () => {
      expect(getContentFromElement('a', editor).type).toEqual(NONE_TYPE)
    })

    it('returns content of type "none" when not given a null', () => {
      expect(getContentFromElement(null, editor).type).toEqual(NONE_TYPE)
    })
  })

  describe('.getContentFromEditor()', () => {
    it('returns content of type "file link" when a file link is selected', () => {
      const $selectedNode = document.createElement('a')
      $selectedNode.href = 'http://example.instructure.com/files/3201/download'
      editor.setSelectedNode($selectedNode)
      expect(getContentFromEditor(editor).type).toEqual(FILE_LINK_TYPE)
    })

    it('returns content of type "image embed" when an image is selected', () => {
      const $selectedNode = document.createElement('img')
      $selectedNode.src = 'https://www.fillmurray.com/200/200'
      editor.setSelectedNode($selectedNode)
      expect(getContentFromEditor(editor).type).toEqual(IMAGE_EMBED_TYPE)
    })

    it('returns content of type "none" when the editor has no selection', () => {
      delete editor.selection
      expect(getContentFromEditor(editor).type).toEqual(NONE_TYPE)
    })

    it('returns content of type "none" when expandCollapsed is false and the selection is collapased', () => {
      const $selectedNode = document.createElement('p')
      $selectedNode.innerHTML = 'some text'
      editor.setSelectedNode($selectedNode)
      editor.selection.collapse()
      expect(getContentFromEditor(editor, false).type).toEqual(NONE_TYPE)
    })

    it('returns content of type "text" when expandCollapsed is true and the selection is collapased', () => {
      const $selectedNode = document.createElement('p')
      $selectedNode.innerHTML = 'some text'
      editor.setSelectedNode($selectedNode)
      editor.selection.collapse()
      expect(getContentFromEditor(editor, true).type).toEqual(TEXT_TYPE)
    })

    it('returns content of type "text" when expandCollapsed is false and the selection is not collapased', () => {
      const $selectedNode = document.createElement('p')
      $selectedNode.innerHTML = 'some text'
      editor.setSelectedNode($selectedNode)
      expect(getContentFromEditor(editor, false).type).toEqual(TEXT_TYPE)
    })
  })

  describe('.getLinkContentFromEditor', () => {
    it('returns content when a link is selected', () => {
      const $selectedNode = document.createElement('a')
      $selectedNode.href = 'http://example.com/'
      editor.setSelectedNode($selectedNode)
      expect(getLinkContentFromEditor(editor).type).toEqual(LINK_TYPE)
    })

    it('returns content when a child element of a link is selected', () => {
      const $link = document.createElement('a')
      $link.href = 'http://example.com/'
      $link.innerHTML = 'this is <strong>bold</strong> text'
      $container.appendChild($link)
      const $selectedNode = $link.querySelector('strong')
      editor.setSelectedNode($selectedNode)
      const content = getLinkContentFromEditor(editor)
      expect(content.type).toEqual(LINK_TYPE)
    })
  })

  describe('findMediaPlayerIframe', () => {
    let wrapper, mediaIframe, shim
    beforeEach(() => {
      wrapper = document.createElement('span')
      mediaIframe = document.createElement('iframe')
      shim = document.createElement('span')
      shim.setAttribute('class', 'mce-shim')
      wrapper.appendChild(mediaIframe)
      wrapper.appendChild(shim)
    })
    it('returns the iframe if given the video iframe', () => {
      const result = findMediaPlayerIframe(mediaIframe)
      expect(result).toEqual(mediaIframe)
    })
    it('returns the iframe if given the tinymce wrapper span', () => {
      const result = findMediaPlayerIframe(wrapper)
      expect(result).toEqual(mediaIframe)
    })
    it('returns the iframe if given the shim', () => {
      const result = findMediaPlayerIframe(shim)
      expect(result).toEqual(mediaIframe)
    })
    it('does not error if given null', () => {
      const result = findMediaPlayerIframe(null)
      expect(result).toEqual(null)
    })
  })

  describe('predicates', () => {
    it('detect a canvas file link', () => {
      const $selectedNode = document.createElement('a')
      $selectedNode.href = 'http://example.instructure.com/files/3201/download'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode, editor)).toBeTruthy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
      expect(isAudioElement($selectedNode)).toBeFalsy()
    })

    it('detect an embeded image', () => {
      const $selectedNode = document.createElement('img')
      $selectedNode.src = 'https://www.fillmurray.com/200/200'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode, editor)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeTruthy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
      expect(isAudioElement($selectedNode)).toBeFalsy()
    })

    it('detect a video element', () => {
      const $selectedNode = document.createElement('span')
      $selectedNode.setAttribute('data-mce-p-data-media-id', 'm-id')
      $selectedNode.setAttribute('data-mce-p-data-media-type', 'video')
      $selectedNode.innerHTML = '<iframe/>'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode, editor)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeTruthy()
      expect(isAudioElement($selectedNode)).toBeFalsy()
    })

    it('detect an audio element', () => {
      const $selectedNode = document.createElement('span')
      $selectedNode.setAttribute('data-mce-p-data-media-id', 'm-id')
      $selectedNode.setAttribute('data-mce-p-data-media-type', 'audio')
      $selectedNode.innerHTML = '<iframe/>'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode, editor)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
      expect(isAudioElement($selectedNode)).toBeTruthy()
    })

    it('ignore some random markup', () => {
      const $selectedNode = document.createElement('div')
      $selectedNode.innerHTML = 'hello world'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode, editor)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
      expect(isAudioElement($selectedNode)).toBeFalsy()
    })

    it('does not error on null', () => {
      const $selectedNode = null
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode, editor)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
      expect(isAudioElement($selectedNode)).toBeFalsy()
    })
  })
})
