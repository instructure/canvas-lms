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

import * as contentInsertion from '../contentInsertion'
import {videoFromTray, videoFromUpload, audioFromTray, audioFromUpload} from './contentHelpers'

describe('contentInsertion', () => {
  let editor, node

  beforeEach(() => {
    node = {
      content: '',
      className: '',
      id: ''
    }

    editor = {
      content: '',
      selectionContent: '',
      classes: '',
      isHidden: () => {
        return false
      },
      selection: {
        getNode: () => {
          return null
        },
        getContent: () => {
          return editor.selectionContent
        },
        setContent: content => {
          editor.selectionContent = content
          editor.content = content
        },
        getEnd: () => {
          return node
        },
        getRng: () => ({})
      },
      dom: {
        getParent: () => {
          return null
        },
        decode: input => {
          return input
        },
        encode: input => input,
        setAttribs: (elem, attrs) => {
          if (elem?.nodeType === 1) {
            // this is an HTMLElement
            Object.keys(attrs).forEach(a => {
              if (attrs[a]) {
                elem.setAttribute(a, attrs[a])
              }
            })
          }
          return elem
        },
        $: () => {
          return {
            is: () => {
              return false
            }
          }
        }
      },
      undoManager: {
        add: () => {}
      },
      focus: () => {},
      insertContent: content => {
        if (editor.selection.getContent()) {
          editor.content = editor.content.replace(editor.selection.getContent(), content)
        } else {
          editor.content += content
        }
      },
      iframeElement: {
        getBoundingClientRect: () => {
          return {left: 0, top: 0, bottom: 0, right: 0}
        }
      },
      execCommand: jest.fn()
    }
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  describe('insertLink', () => {
    let link

    beforeEach(() => {
      link = {
        href: '/some/path',
        url: '/other/path',
        title: 'Here Be Links',
        text: 'Click On Me',
        selectionDetails: {
          node: undefined,
          range: undefined
        }
      }
    })

    it('builds an anchor link with appropriate embed class', () => {
      link.embed = {type: 'image'}
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="/some/path" title="Here Be Links" class="instructure_file_link instructure_image_thumbnail">Click On Me</a>'
      )
    })

    it('uses link data to build html', () => {
      link.embed = {type: 'scribd'}
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="/some/path" title="Here Be Links" class="instructure_file_link instructure_scribd_file">Click On Me</a>'
      )
    })

    it('includes attributes', () => {
      link['data-canvas-previewable'] = true
      link.class = 'instructure_file_link foo'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="/some/path" title="Here Be Links" data-canvas-previewable="true" class="instructure_file_link foo">Click On Me</a>'
      )
    })

    it('respects the current selection building the link by delegating to tinymce', () => {
      editor.selection.setContent('link me')
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual('<a href="/some/path" title="Here Be Links">link me</a>')
    })

    it('cleans a url with no protocol when linking the current selection', () => {
      editor.execCommand = jest.fn()
      editor.selection.setContent('link me')
      link.href = 'www.google.com'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="http://www.google.com" title="Here Be Links">link me</a>'
      )
    })

    it('cleans a url with no protocol when editing an existing, selected link', () => {
      link.href = 'www.google.com'
      editor.selection.setContent('link me')
      const anchor = document.createElement('a')
      anchor.setAttribute('href', 'http://example.com')
      const textNode = document.createTextNode('link me')
      anchor.appendChild(textNode)
      editor.selection.getNode = () => textNode
      editor.dom.getParent = () => anchor
      editor.selection.select = () => {}
      contentInsertion.insertLink(editor, link, 'Click On Me')
      // insertLink edits the <a> in-place, so
      // check that the anchor has been updated as expected
      expect(anchor.getAttribute('href')).toEqual('http://www.google.com')
      expect(anchor.innerText).toEqual('Click On Me')
    })

    it('can use url if no href', () => {
      link.href = undefined
      link.url = '/other/path'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual('<a href="/other/path" title="Here Be Links">Click On Me</a>')
    })

    it('cleans a url with no protocol', () => {
      link.href = 'www.google.com'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="http://www.google.com" title="Here Be Links">Click On Me</a>'
      )
    })

    it('sets embed id with media entry id for videos', () => {
      link.embed = {type: 'video', id: '0_22h0jy7g'}
      contentInsertion.insertLink(editor, link)
      expect(editor.content.match(link.embed.id)).toBeTruthy()
    })

    it('sets embed id with media entry id for audio', () => {
      link.embed = {type: 'audio', id: '0_22h0jy7g'}
      contentInsertion.insertLink(editor, link)
      expect(editor.content.match(link.embed.id)).toBeTruthy()
    })
  })

  describe('insertContent', () => {
    it('accepts string content', () => {
      const content = 'Some Chunk Of Content'
      contentInsertion.insertContent(editor, content)
      expect(editor.content).toEqual('Some Chunk Of Content')
    })

    it('calls replaceTextareaSelection() when editor is hidden', () => {
      const content = 'blah'
      const elem = {selectionStart: 0, selectionEnd: 3, value: 'subcontent'}
      editor.isHidden = () => {
        return true
      }
      editor.getElement = () => {
        return elem
      }
      contentInsertion.insertContent(editor, content)
      expect('blahcontent').toEqual(elem.value)
    })
  })

  describe('insertImage', () => {
    let image
    beforeEach(() => {
      image = {
        href: '/some/path',
        url: '/other/path',
        title: 'Here Be Images'
      }
    })

    it('builds image html from image data', () => {
      contentInsertion.insertImage(editor, image)
      expect(editor.content).toEqual(
        '<img alt="Here Be Images" src="/some/path" style="max-width:320px;max-height:320px"/>'
      )
    })

    it('uses url if no href', () => {
      image.href = undefined
      contentInsertion.insertImage(editor, image)
      expect(editor.content).toEqual(
        '<img alt="Here Be Images" src="/other/path" style="max-width:320px;max-height:320px"/>'
      )
    })

    it('builds linked image html from linked image data', () => {
      const containerElem = {
        nodeName: 'A',
        getAttribute: () => {
          return 'http://bogus.edu'
        }
      }
      const ed = {...editor}
      ed.insertContent = content => {
        ed.content += content
      }
      ed.selection.getNode = () => {
        return {...node, nodeName: 'IMG'}
      }
      ed.selection.getRng = () => ({
        startContainer: containerElem,
        endContainer: containerElem
      })

      contentInsertion.insertImage(ed, image)
      expect(ed.content).toEqual(
        '<a href="http://bogus.edu" data-mce-href="http://bogus.edu"><img alt="Here Be Images" src="/some/path"/></a>'
      )
    })
  })

  describe('existingContentToLink', () => {
    it('returns true if content selected', () => {
      editor.selection.getContent = () => {
        return 'content'
      }
      const link = {
        selectionDetails: {
          node: undefined
        }
      }
      expect(contentInsertion.existingContentToLink(editor, link)).toBe(true)
    })
    it('returns false if content not selected', () => {
      const link = {
        selectionDetails: {
          node: false
        }
      }
      expect(contentInsertion.existingContentToLink(editor, link)).toBe(false)
    })

    it('returns true when only an editor is passed with a selection', () => {
      editor.selection.getContent = () => {
        return 'content'
      }
      expect(contentInsertion.existingContentToLink(editor)).toBe(true)
    })
  })

  describe('existingContentToLinkIsImg', () => {
    it('returns false if no content selected', () => {
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(false)
    })
    it('returns false if selected content is not img', () => {
      editor.selection.getContent = () => {
        return 'content'
      }
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(false)
    })
    it('returns true if selected content is img', () => {
      editor.selection.getContent = () => {
        return 'content'
      }
      editor.dom.$ = () => {
        return {
          is: () => {
            return true
          }
        }
      }
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(true)
    })
  })

  describe('insertVideo', () => {
    beforeEach(() => {
      // this is what's returned from editor.seletion.getEnd()
      node = {
        querySelector: () => 'the inserted iframe'
      }
    })

    it('inserts video from upload into iframe', () => {
      jest.spyOn(editor, 'insertContent')
      const video = videoFromUpload()
      const result = contentInsertion.insertVideo(editor, video)
      expect(editor.insertContent).toHaveBeenCalledWith(
        '<iframe allow="fullscreen" allowfullscreen="" data-media-id="m-media-id" data-media-type="video" src="/url/to/m-media-id?type=video" style="width:400px;height:225px;display:inline-block" title="Video player for filename.mov"></iframe>'
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('inserts video from the course content tray', () => {
      jest.spyOn(editor, 'insertContent')
      const video = videoFromTray()
      const result = contentInsertion.insertVideo(editor, video)
      expect(editor.insertContent).toHaveBeenCalledWith(
        '<iframe allow="fullscreen" allowfullscreen="" data-media-id="17" data-media-type="video" src="/media_objects_iframe?mediahref=%2Furl%2Fto%2Fcourse%2Ffile&amp;type=video" style="width:400px;height:225px;display:inline-block" title="Video player for filename.mov"></iframe>'
      )
      expect(result).toEqual('the inserted iframe')
    })
  })

  describe('insertAudio', () => {
    beforeEach(() => {
      // this is what's returned from editor.seletion.getEnd()
      node = {
        querySelector: () => 'the inserted iframe'
      }
    })

    it('inserts audio from upload into iframe', () => {
      jest.spyOn(editor, 'insertContent')
      const audio = audioFromUpload()
      const result = contentInsertion.insertAudio(editor, audio)
      expect(editor.insertContent).toHaveBeenCalledWith(
        '<iframe data-media-id="m-media-id" data-media-type="audio" src="/url/to/m-media-id?type=audio" style="width:300px;height:2.813rem;display:inline-block" title="Audio player for filename.mp3"></iframe>'
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('inserts audio from the course content tray', () => {
      jest.spyOn(editor, 'insertContent')
      const audio = audioFromTray()
      const result = contentInsertion.insertAudio(editor, audio)
      expect(editor.insertContent).toHaveBeenCalledWith(
        '<iframe data-media-id="29" data-media-type="audio" src="/media_objects_iframe?mediahref=url%2Fto%2Fcourse%2Ffile&amp;type=audio" style="width:300px;height:2.813rem;display:inline-block" title="Audio player for filename.mp3"></iframe>'
      )
      expect(result).toEqual('the inserted iframe')
    })
  })
})
