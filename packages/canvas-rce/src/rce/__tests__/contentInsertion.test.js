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
import {audioFromTray, audioFromUpload, videoFromTray, videoFromUpload} from './contentHelpers'
import RCEGlobals from '../RCEGlobals'

describe('contentInsertion', () => {
  let editor, node
  const canvasOrigin = 'https://mycanvas.com:3000'

  beforeEach(() => {
    node = {
      content: '',
      className: '',
      id: '',
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
          return editor.selectionContent ? 'p' : null
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
        getRng: () => ({}),
        isCollapsed: () => editor.selectionContent.length === 0,
      },
      dom: {
        doc: window.document,
        getParent: () => {
          return null
        },
        decode: input => {
          return input
        },
        encode: input => encodeURIComponent(input),
        setAttribs: (elem, attrs) => {
          if (elem?.nodeType === 1) {
            // this is an HTMLElement
            Object.keys(attrs)
              .sort()
              .forEach(a => {
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
            },
          }
        },
        createHTML: (tag, attrs, text) => {
          const elem = document.createElement(tag)
          editor.dom.setAttribs(elem, attrs)
          elem.innerHTML = text
          return elem.outerHTML
        },
      },
      undoManager: {
        add: () => {},
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
        },
      },
      execCommand: jest.fn((cmd, ui, value, _args) => {
        if (cmd === 'mceInsertLink') {
          editor.content = editor.dom.createHTML('a', value, editor.selectionContent)
        } else if (cmd === 'mceInsertContent') {
          editor.content = value
        }
      }),
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
          range: undefined,
        },
      }
    })

    it('sets Canvas URLs to be relative', () => {
      link.href = 'https://mycanvas.com:3000/some/path'
      link.url = 'https://mycanvas.com:3000/some/path'
      contentInsertion.insertLink(editor, link, canvasOrigin)
      expect(editor.content).toEqual('<a href="/some/path" title="Here Be Links">Click On Me</a>')
    })

    it('leaves non-Canvas URLs as absolute', () => {
      link.href = 'https://yodawg.com:3001/some/path'
      link.url = 'https://yodawg.com:3001/some/path'
      contentInsertion.insertLink(editor, link, canvasOrigin)
      expect(editor.content).toEqual(
        '<a href="https://yodawg.com:3001/some/path" title="Here Be Links">Click On Me</a>'
      )
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

    describe('with anchor text', () => {
      let anchorElm

      beforeEach(() => {
        anchorElm = {
          innerText: 'anchor text',
        }

        editor.dom.getParent = () => anchorElm
      })

      it('uses the anchor text', () => {
        contentInsertion.insertLink(editor, link)
        expect(editor.content).toEqual('<a href="/some/path" title="Here Be Links">anchor text</a>')
      })

      describe('with "forceRename" set to "true"', () => {
        beforeEach(() => (link.forceRename = true))

        it('uses the link "text"', () => {
          contentInsertion.insertLink(editor, link)
          expect(editor.content).toEqual(
            '<a href="/some/path" title="Here Be Links">Click On Me</a>'
          )
        })
      })
    })

    it('uses link data to set no_preview class', () => {
      link.embed = {noPreview: true}
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="/some/path" title="Here Be Links" class="instructure_file_link no_preview">Click On Me</a>'
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

    it('includes attributes for course link when supplied', () => {
      link['data-published'] = true
      link['data-course-type'] = 'wikiPages'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="/some/path" title="Here Be Links" data-course-type="wikiPages" data-published="true">Click On Me</a>'
      )
    })

    it('respects the current selection building the link by delegating to tinymce', () => {
      editor.selection.setContent('link me')
      contentInsertion.insertLink(editor, link)
      expect(editor.execCommand).toHaveBeenCalledWith('mceInsertLink', false, expect.any(Object))
    })

    it('cleans a url with no protocol when linking the current selection', () => {
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

    it('encodes html entities once', () => {
      link.href = 'http://www.google.com'
      link.title = 'PB&J'
      link.text = '3 < 4'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="http://www.google.com" title="PB&amp;J">3 &lt; 4</a>'
      )
    })

    it('renders quotes correctly', () => {
      link.href = 'http://www.google.com'
      link.title = 'PB&J'
      link.text = '"quote test"'
      contentInsertion.insertLink(editor, link)
      expect(editor.content).toEqual(
        '<a href="http://www.google.com" title="PB&amp;J">&quot;quote test&quot;</a>'
      )
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
        title: 'Here Be Images',
      }
    })

    it('sets Canvas URLs to be relative', () => {
      image.href = 'https://mycanvas.com:3000/some/path'
      image.url = 'https://mycanvas.com:3000/some/path'
      contentInsertion.insertImage(editor, image, canvasOrigin)
      expect(editor.content).toEqual('<img alt="Here Be Images" src="/some/path/preview"/>')
    })

    it('leaves non-Canvas URLs as absolute', () => {
      image.href = 'https://yodawg.com:3001/some/path'
      image.url = 'https://yodawg.com:3001/some/path'
      contentInsertion.insertImage(editor, image, canvasOrigin)
      expect(editor.content).toEqual(
        '<img alt="Here Be Images" src="https://yodawg.com:3001/some/path"/>'
      )
    })

    it('it keeps the original image style when replaced', () => {
      const imageToReplace = document.createElement('img')
      imageToReplace.style.cssText = 'float: left;'
      editor.selection.getNode = () => {
        return {
          ...node,
          nodeName: 'IMG',
          style: imageToReplace.style,
          getAttribute: attr => {
            const imageAttributes = {
              width: '100px',
            }

            return imageAttributes[attr]
          },
        }
      }
      contentInsertion.insertImage(editor, image)
      expect(editor.content).toEqual(
        '<img alt="Here Be Images" src="/some/path/preview" width="100px" style="float:left"/>'
      )
    })

    it('builds image html from image data', () => {
      contentInsertion.insertImage(editor, image)
      expect(editor.content).toEqual('<img alt="Here Be Images" src="/some/path/preview"/>')
    })

    it('uses url if no href', () => {
      image.href = undefined
      contentInsertion.insertImage(editor, image)
      expect(editor.content).toEqual('<img alt="Here Be Images" src="/other/path"/>')
    })

    it('builds linked image html from linked image data', () => {
      const containerElem = {
        nodeName: 'A',
        getAttribute: () => {
          return 'http://bogus.edu'
        },
      }
      editor.selection.getNode = () => {
        return {...node, nodeName: 'IMG'}
      }
      editor.selection.getRng = () => ({
        startContainer: containerElem,
        endContainer: containerElem,
      })
      contentInsertion.insertImage(editor, image)
      expect(editor.content).toEqual(
        '<a href="http://bogus.edu" data-mce-href="http://bogus.edu"><img alt="Here Be Images" src="/some/path/preview"/></a>'
      )
    })
  })

  describe('insertEquation', () => {
    it('builds relative image html from LaTeX', () => {
      const tex = 'y = x^2'
      const dblEncodedTex = window.encodeURIComponent(window.encodeURIComponent(tex))
      const imgHtml = `<img alt="LaTeX: ${tex}" title="${tex}" class="equation_image" data-equation-content="${tex}" src="/equation_images/${dblEncodedTex}?scale=1" data-ignore-a11y-check="">`
      contentInsertion.insertEquation(editor, tex)
      expect(editor.content).toEqual(imgHtml)
    })
  })

  describe('existingContentToLink', () => {
    it('returns true if content selected', () => {
      editor.selection.getContent = () => {
        return 'content'
      }
      const link = {
        selectionDetails: {
          node: undefined,
        },
      }
      expect(contentInsertion.existingContentToLink(editor, link)).toBe(true)
    })
    it('returns false if content not selected', () => {
      const link = {
        selectionDetails: {
          node: false,
        },
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
    beforeEach(() => {
      editor.dom.$ = elem => {
        return {
          is: () => {
            const item = HTMLCollection.prototype.isPrototypeOf(elem) ? elem[0] : null
            return !!item && item.tagName === 'IMG'
          },
        }
      }
      editor.isHidden = () => false
    })
    it('returns false if editor is hidden', () => {
      editor.isHidden = () => true
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(false)
    })
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
        return '<img src="image.jpg" alt="Test image" />'
      }
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(true)
    })
    it('returns false if selected content contains a period', () => {
      editor.selection.getContent = () => {
        return 'a . period'
      }
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(false)
    })
    it('returns false if selected content contains a slash', () => {
      editor.selection.getContent = () => {
        return 'a / slash'
      }
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(false)
    })
    it('returns false if selected content contains a question mark', () => {
      editor.selection.getContent = () => {
        return 'a ? question'
      }
      expect(contentInsertion.existingContentToLinkIsImg(editor)).toBe(false)
    })
  })

  describe('insertVideo', () => {
    beforeEach(() => {
      // this is what's returned from editor.selection.getEnd()
      node = {
        querySelector: () => 'the inserted iframe',
      }
    })

    it('inserts video from upload into iframe', () => {
      jest.spyOn(editor, 'insertContent')
      const video = videoFromUpload()
      const result = contentInsertion.insertVideo(editor, video, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe allow="fullscreen" allowfullscreen data-media-id="m-media-id" data-media-type="video" src="/url/to/m-media-id?type=video" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('inserts video from the course content tray', () => {
      jest.spyOn(editor, 'insertContent')
      const video = videoFromTray()
      const result = contentInsertion.insertVideo(editor, video, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe allow="fullscreen" allowfullscreen data-media-id="17" data-media-type="video" src="/media_objects_iframe/17?type=video" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('links video if user has made a selection', () => {
      editor.selectionContent = 'link me'
      const video = videoFromTray()
      contentInsertion.insertVideo(editor, video, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith('mceInsertLink', false, {
        class: 'instructure_file_link',
        'data-canvas-previewable': undefined,
        href: '/media_objects_iframe/17?type=video',
        id: 17,
        rel: 'noopener noreferrer',
        target: '_blank',
        title: 'filename.mov',
      })
    })
  })

  describe('insertAudio', () => {
    beforeEach(() => {
      // this is what's returned from editor.seletion.getEnd()
      node = {
        querySelector: () => 'the inserted iframe',
      }
    })

    it('inserts audio from upload into iframe', () => {
      const audio = audioFromUpload()
      const result = contentInsertion.insertAudio(editor, audio, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe data-media-id="m-media-id" data-media-type="audio" src="/url/to/m-media-id?type=audio" style="width:320px;height:14.25rem;display:inline-block;" title="Audio player for filename.mp3"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('inserts audio from the course content tray', () => {
      const audio = audioFromTray()
      const result = contentInsertion.insertAudio(editor, audio, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe data-media-id="29" data-media-type="audio" src="/media_objects_iframe?mediahref=/url/to/course/file&type=audio" style="width:320px;height:14.25rem;display:inline-block;" title="Audio player for filename.mp3"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })
  })

  describe('insertVideo with attachment', () => {
    beforeEach(() => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: true})
      // this is what's returned from editor.selection.getEnd()
      node = {
        querySelector: () => 'the inserted iframe',
      }
    })

    afterAll(() => {
      RCEGlobals.getFeatures.mockRestore()
    })

    it('inserts video from the course content tray with attachmentId', () => {
      jest.spyOn(editor, 'insertContent')
      const video = videoFromTray()
      const result = contentInsertion.insertVideo(editor, video, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe allow="fullscreen" allowfullscreen data-media-id="17" data-media-type="video" src="/media_attachments_iframe/17?type=video&embedded=true" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('inserts video from upload into iframe with attachmentId', () => {
      jest.spyOn(editor, 'insertContent')
      const video = videoFromUpload()
      const result = contentInsertion.insertVideo(editor, video, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe allow="fullscreen" allowfullscreen data-media-id="m-media-id" data-media-type="video" src="/media_attachments_iframe/maybe?type=video&embedded=true" style="width:400px;height:225px;display:inline-block;" title="Video player for filename.mov"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })
  })
  describe('insertAudio with attachment', () => {
    beforeEach(() => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: true})
      // this is what's returned from editor.selection.getEnd()
      node = {
        querySelector: () => 'the inserted iframe',
      }
    })

    afterAll(() => {
      RCEGlobals.getFeatures.mockRestore()
    })

    it('inserts audio from upload into iframe with attachmentId', () => {
      const audio = audioFromUpload()
      const result = contentInsertion.insertAudio(editor, audio, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe data-media-id="m-media-id" data-media-type="audio" src="/media_attachments_iframe/maybe?type=audio&embedded=true" style="width:320px;height:14.25rem;display:inline-block;" title="Audio player for filename.mp3"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })

    it('inserts audio from the course content tray with attachmentId', () => {
      const audio = audioFromTray()
      const result = contentInsertion.insertAudio(editor, audio, canvasOrigin)
      expect(editor.execCommand).toHaveBeenCalledWith(
        'mceInsertContent',
        false,
        '<iframe data-media-id="29" data-media-type="audio" src="/media_attachments_iframe/29?type=audio&embedded=true" style="width:320px;height:14.25rem;display:inline-block;" title="Audio player for filename.mp3"></iframe>',
        {skip_focus: true}
      )
      expect(result).toEqual('the inserted iframe')
    })
  })
})
