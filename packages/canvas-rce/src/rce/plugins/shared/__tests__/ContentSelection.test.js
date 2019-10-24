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
  getContentFromEditor,
  getContentFromElement,
  isFileLink,
  isImageEmbed,
  isVideoElement
} from '../ContentSelection'
import FakeEditor from './FakeEditor'

describe('RCE > Plugins > Shared > Content Selection', () => {
  let $container

  beforeEach(() => {
    $container = document.body.appendChild(document.createElement('div'))
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
        expect(getContentFromElement($element).$element).toEqual($element)
      })

      it('returns content of type "file link" when the anchor links to a user file', () => {
        expect(getContentFromElement($element).type).toEqual(FILE_LINK_TYPE)
      })

      it('includes the text of the link', () => {
        expect(getContentFromElement($element).text).toEqual('Syllabus.doc')
      })

      it('includes the url of the link', () => {
        expect(getContentFromElement($element).url).toEqual(
          'http://example.instructure.com/files/3201/download?download_frd=1'
        )
      })

      it('returns content of type "file link" when the anchor links to a course file', () => {
        $element.href =
          'http://example.instructure.com/courses/1201/files/3201/download?download_frd=1'
        expect(getContentFromElement($element).type).toEqual(FILE_LINK_TYPE)
      })

      it('ignores query parameters on the href', () => {
        $element.href = 'http://example.instructure.com/files/3201/download'
        expect(getContentFromElement($element).type).toEqual(FILE_LINK_TYPE)
      })

      it('returns content of type "link" when linking to unhandled canvas content', () => {
        $element.href = 'http://example.instructure.com/courses/1201/grades'
        expect(getContentFromElement($element).type).toEqual(LINK_TYPE)
      })

      it('returns content of type "link" when the anchor links to an unhandled location', () => {
        $element.href = 'http://www.example.com/foo/bar'
        expect(getContentFromElement($element).type).toEqual(LINK_TYPE)
      })

      it('returns content of type "none" when the anchor has no href attribute', () => {
        $element.removeAttribute('href')
        expect(getContentFromElement($element).type).toEqual(NONE_TYPE)
      })
    })

    describe('when the given element is a video container element', () => {
      beforeEach(() => {
        $element = $container.appendChild(document.createElement('div'))
      })

      it('returns None type if no id is present', () => {
        expect(getContentFromElement($element).type).toEqual(NONE_TYPE)
      })

      it('returns None type if there are no children', () => {
        $element.id = 'media_object_1234'
        expect(getContentFromElement($element).type).toEqual(NONE_TYPE)
      })

      it('returns None type if there are more than one children', () => {
        $element.id = 'media_object_1234'
        $element.appendChild(document.createElement('iframe'))
        $element.appendChild(document.createElement('span'))
        $element.appendChild(document.createElement('span'))
        expect(getContentFromElement($element).type).toEqual(NONE_TYPE)
      })

      it('returns None type if children element is not an iframe', () => {
        $element.id = 'media_object_1234'
        $element.appendChild(document.createElement('span'))
        expect(getContentFromElement($element).type).toEqual(NONE_TYPE)
      })

      it('returns id if iframe and div are set', () => {
        $element.id = 'media_object_1234'
        $element.appendChild(document.createElement('iframe'))
        expect(getContentFromElement($element).id).toEqual('1234')
      })
    })

    describe('when the given element is an image', () => {
      beforeEach(() => {
        $element = $container.appendChild(document.createElement('img'))
        $element.src = 'https://www.fillmurray.com/200/200'
        $element.alt = 'The ineffable Bill Murray'
      })

      it('includes the image element on the returned content', () => {
        expect(getContentFromElement($element).$element).toEqual($element)
      })

      describe('.altText', () => {
        it('is the alt text of the image when present', () => {
          expect(getContentFromElement($element).altText).toEqual('The ineffable Bill Murray')
        })

        it('is blank when absent on the image', () => {
          $element.removeAttribute('alt')
          expect(getContentFromElement($element).altText).toEqual('')
        })
      })

      describe('.isDecorativeImage', () => {
        describe('when "data-is-decorative" is "true" on the image element', () => {
          beforeEach(() => {
            $element.setAttribute('data-is-decorative', true)
          })

          it('is true when the image has no alt text', () => {
            $element.alt = ''
            expect(getContentFromElement($element).isDecorativeImage).toEqual(true)
          })

          it('is false when the image still has alt text', () => {
            expect(getContentFromElement($element).isDecorativeImage).toEqual(false)
          })
        })

        describe('when "data-is-decorative" is "false" on the image element', () => {
          beforeEach(() => {
            $element.setAttribute('data-is-decorative', false)
          })

          it('is false when the image has no alt text', () => {
            $element.alt = ''
            expect(getContentFromElement($element).isDecorativeImage).toEqual(false)
          })

          it('is false when the image has alt text', () => {
            expect(getContentFromElement($element).isDecorativeImage).toEqual(false)
          })
        })

        it('is blank when absent on the image', () => {
          $element.alt = ''
          expect(getContentFromElement($element).isDecorativeImage).toEqual(false)
        })
      })

      it('sets the url to the src of the image', () => {
        expect(getContentFromElement($element).url).toEqual('https://www.fillmurray.com/200/200')
      })
    })

    it('returns content of type "none" when given an unhandled element', () => {
      $element = $container.appendChild(document.createElement('hr'))
      expect(getContentFromElement($element).type).toEqual(NONE_TYPE)
    })

    it('returns content of type "none" when given a non-element', () => {
      expect(getContentFromElement('a').type).toEqual(NONE_TYPE)
    })

    it('returns content of type "none" when not given a null', () => {
      expect(getContentFromElement(null).type).toEqual(NONE_TYPE)
    })
  })

  describe('.getContentFromEditor()', () => {
    let editor

    beforeEach(() => {
      editor = new FakeEditor()
      editor.initialize()
    })

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

  describe('predicates', () => {
    let editor

    beforeEach(() => {
      editor = new FakeEditor()
      editor.initialize()
    })

    it('detect a canvas file link', () => {
      const $selectedNode = document.createElement('a')
      $selectedNode.href = 'http://example.instructure.com/files/3201/download'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode)).toBeTruthy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
    })

    it('detect an embeded image', () => {
      const $selectedNode = document.createElement('img')
      $selectedNode.src = 'https://www.fillmurray.com/200/200'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeTruthy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
    })

    it('detect a video element', () => {
      const $selectedNode = document.createElement('div')
      $selectedNode.id = 'foo_media_object'
      $selectedNode.innerHTML = '<iframe/>'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeTruthy()
    })

    it('ignore some random markup', () => {
      const $selectedNode = document.createElement('div')
      $selectedNode.innerHTML = 'hello world'
      editor.setSelectedNode($selectedNode)
      expect(isFileLink($selectedNode)).toBeFalsy()
      expect(isImageEmbed($selectedNode)).toBeFalsy()
      expect(isVideoElement($selectedNode)).toBeFalsy()
    })
  })
})
