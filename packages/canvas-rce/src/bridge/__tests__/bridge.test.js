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

import Bridge from '..'

describe('Editor/Sidebar bridge', () => {
  afterEach(() => {
    Bridge.focusEditor(null)
    jest.restoreAllMocks()
  })

  describe('focusEditor', () => {
    it('sets the active editor', () => {
      const editor = {}
      Bridge.focusEditor(editor)
      expect(Bridge.activeEditor()).toBe(editor)
    })

    it('calls hideTrays if focus is changing', () => {
      jest.spyOn(Bridge, 'hideTrays')
      Bridge.focusEditor({id: 'editor_id'})
      expect(Bridge.hideTrays).toHaveBeenCalledTimes(1)
      Bridge.focusEditor({id: 'another_editor'})
      expect(Bridge.hideTrays).toHaveBeenCalledTimes(2)
    })

    it('does not call hideTrays if focus is not changing', () => {
      const editor = {id: 'editor_id'}
      jest.spyOn(Bridge, 'hideTrays')
      Bridge.focusEditor(editor)
      Bridge.focusEditor(editor)
      expect(Bridge.hideTrays).toHaveBeenCalledTimes(1)
    })
  })

  describe('blurEditor', () => {
    it('sets active editor to null if bluring the active editor', () => {
      const editor = {id: 'editor_id'}
      Bridge.focusedEditor = editor
      Bridge.blurEditor(editor)
      expect(Bridge.activeEditor()).toBe(null)
    })

    it('does not set the active editor to null if not bluring the active editor', () => {
      const editor = {id: 'editor_id'}
      Bridge.focusedEditor = editor
      Bridge.blurEditor({id: 'another_editor'})
      expect(Bridge.activeEditor()).toBe(editor)
    })

    it('calls hideTrays if bluring the active editor', () => {
      jest.spyOn(Bridge, 'hideTrays')
      const editor = {id: 'editor_id'}
      Bridge.focusedEditor = editor
      Bridge.blurEditor(editor)
      expect(Bridge.hideTrays).toHaveBeenCalledTimes(1)
    })

    it('does not set call hideTrays if not bluring the active editor', () => {
      jest.spyOn(Bridge, 'hideTrays')
      const editor = {id: 'editor_id'}
      Bridge.focusedEditor = editor
      Bridge.blurEditor({id: 'another_editor'})
      expect(Bridge.hideTrays).not.toHaveBeenCalled()
    })
  })

  describe('hideTrays', () => {
    it('calls hideTray on each of the registered controllers', () => {
      const controller1 = {hideTray: jest.fn()}
      const controller2 = {hideTray: jest.fn()}
      Bridge.attachController(controller1, 'an_editor')
      Bridge.attachController(controller2, 'another_editor')
      Bridge.hideTrays()
      expect(controller1.hideTray).toHaveBeenCalled()
      expect(controller2.hideTray).toHaveBeenCalled()
    })
  })

  describe('detachEditor', () => {
    const activeEditor = {}
    const otherEditor = {}

    beforeEach(() => {
      Bridge.focusEditor(activeEditor)
    })

    it('given active editor clears the active editor', () => {
      Bridge.detachEditor(activeEditor)
      expect(Bridge.activeEditor()).toBe(null)
    })

    it('given some other editor leaves the active editor alone', () => {
      Bridge.detachEditor(otherEditor)
      expect(Bridge.activeEditor()).toBe(activeEditor)
    })
  })

  describe('renderEditor', () => {
    it('sets the active editor', () => {
      const editor = {}
      Bridge.renderEditor(editor)
      expect(Bridge.activeEditor()).toBe(editor)
    })

    it('accepts the first editor rendered when many rendered in a row', () => {
      const editor1 = {1: 1}
      const editor2 = {2: 2}
      const editor3 = {3: 3}
      Bridge.renderEditor(editor1)
      Bridge.renderEditor(editor2)
      Bridge.renderEditor(editor3)
      expect(Bridge.activeEditor()).toBe(editor1)
    })
  })

  describe('content insertion', () => {
    const link = {}
    let editor = {}

    beforeEach(() => {
      jest.spyOn(console, 'warn')
      editor = {
        id: 'editor_id',
        addAlert: jest.fn(),
        insertLink: jest.fn(),
        insertVideo: jest.fn(),
        insertAudio: jest.fn(),
        insertEmbedCode: jest.fn(),
        removePlaceholders: jest.fn(),
        insertImagePlaceholder: jest.fn(),
        existingContentToLink: () => false,
        props: {
          textareaId: 'fake_editor',
          tinymce: {
            get(_id) {
              return {
                selection: {
                  getRng: jest.fn(() => 'some-range'),
                  getNode: jest.fn(() => 'some-node'),
                },
              }
            },
          },
        },
      }
    })

    describe('insertLink', () => {
      it('insertLink with an active editor forwards the link to createLink', () => {
        Bridge.focusEditor(editor)
        Bridge.insertLink(link)
        expect(editor.insertLink).toHaveBeenCalledWith(link)
      })

      it('insertLink with no active editor is a no-op, but warns', () => {
        Bridge.focusEditor(undefined)
        Bridge.insertLink(link)
        expect(console.warn).toHaveBeenCalled() // eslint-disable-line no-console
      })

      it('adds selectionDetails to links', () => {
        Bridge.focusEditor(editor)
        Bridge.insertLink({})
        expect(editor.insertLink).toHaveBeenCalledWith({
          selectionDetails: {
            node: 'some-node',
            range: 'some-range',
          },
        })
      })

      it('calls hideTray after inserting a link', () => {
        const hideTray = jest.fn()
        Bridge.focusEditor(editor)
        Bridge.attachController({hideTray}, 'editor_id')
        Bridge.insertLink({})
        expect(hideTray).toHaveBeenCalledTimes(1)
      })

      it('inserts the placeholder when asked', () => {
        Bridge.focusEditor(editor)
        Bridge.insertImagePlaceholder({})
        expect(Bridge.getEditor().insertImagePlaceholder).toHaveBeenCalled()
      })

      it('does not insert the placeholder if the user has selected text', () => {
        editor.existingContentToLink = () => true
        Bridge.focusEditor(editor)
        Bridge.insertImagePlaceholder({})
        expect(Bridge.getEditor().insertImagePlaceholder).not.toHaveBeenCalled()
      })

      it('defaults to link title if no text is given', () => {
        Bridge.focusEditor(editor)
        Bridge.insertLink({
          text: '',
          title: 'some link',
        })
        expect(editor.insertLink).toHaveBeenCalledWith({
          selectionDetails: {
            node: 'some-node',
            range: 'some-range',
          },
          text: 'some link',
          title: 'some link',
        })
      })

      it('defaults to link title if only spaces are given', () => {
        Bridge.focusEditor(editor)
        Bridge.insertLink({
          text: '   ',
          title: 'some link',
        })
        expect(editor.insertLink).toHaveBeenCalledWith({
          selectionDetails: {
            node: 'some-node',
            range: 'some-range',
          },
          text: 'some link',
          title: 'some link',
        })
      })
    })

    describe('insertFileLink', () => {
      it('inserts a link', () => {
        const insertLinkSpy = jest.spyOn(Bridge, 'insertLink')
        Bridge.insertFileLink({content_type: 'plain/text'})
        expect(insertLinkSpy).toHaveBeenCalled()
      })

      it('embeds an image if it is browser supported', () => {
        const insertLinkSpy = jest.spyOn(Bridge, 'insertLink')
        const insertImageSpy = jest.spyOn(Bridge, 'insertImage')
        Bridge.insertFileLink({content_type: 'image/png'})
        expect(insertLinkSpy).not.toHaveBeenCalled()
        expect(insertImageSpy).toHaveBeenCalled()
      })

      it('inserts link if the file is not browser supported', () => {
        const insertLinkSpy = jest.spyOn(Bridge, 'insertLink')
        const insertImageSpy = jest.spyOn(Bridge, 'insertImage')
        Bridge.insertFileLink({content_type: 'image/vnd.dxf'})
        expect(insertLinkSpy).toHaveBeenCalled()
        expect(insertImageSpy).not.toHaveBeenCalled()
      })

      it('embeds media', () => {
        const insertLinkSpy = jest.spyOn(Bridge, 'insertLink')
        const embedMediaSpy = jest.spyOn(Bridge, 'embedMedia')
        Bridge.insertFileLink({content_type: 'video/mp4', href: 'here/i/am'})
        expect(insertLinkSpy).not.toHaveBeenCalled()
        expect(embedMediaSpy).toHaveBeenCalledWith({
          content_type: 'video/mp4',
          href: 'here/i/am',
          embedded_iframe_url: 'here/i/am',
        })
      })
    })

    describe('embedMedia', () => {
      let hideTray
      beforeEach(() => {
        hideTray = jest.fn()
        Bridge.attachController({hideTray}, 'editor_id')
        Bridge.focusEditor(editor)
      })

      it('inserts video when media is video', () => {
        jest.spyOn(Bridge, 'insertVideo')
        const theMedia = {type: 'video', content_type: 'video/mp4'}
        Bridge.embedMedia(theMedia)
        expect(Bridge.insertVideo).toHaveBeenCalledWith(theMedia)
        expect(editor.insertVideo).toHaveBeenCalledWith(theMedia)
        expect(hideTray).toHaveBeenCalled()
      })

      it('inserts audio when media is audio', () => {
        jest.spyOn(Bridge, 'insertAudio')
        const theMedia = {type: 'audio', content_type: 'audio/mpeg'}
        Bridge.embedMedia(theMedia)
        expect(Bridge.insertAudio).toHaveBeenCalledWith(theMedia)
        expect(editor.insertAudio).toHaveBeenCalledWith(theMedia)
        expect(hideTray).toHaveBeenCalled()
      })
    })

    describe('insertEmbedCode', () => {
      it('inserts embed code', () => {
        Bridge.focusEditor(editor)
        const theCode = 'insert me'
        Bridge.insertEmbedCode(theCode)
        expect(editor.insertEmbedCode).toHaveBeenCalledWith(theCode)
      })
    })

    describe('upload support', () => {
      it('removes the placeholder', () => {
        Bridge.focusEditor(editor)
        Bridge.removePlaceholders('forfilename')
        expect(editor.removePlaceholders).toHaveBeenCalledWith('forfilename')
      })

      it('shows an error message', () => {
        Bridge.focusEditor(editor)
        Bridge.showError('whoops')
        expect(editor.addAlert).toHaveBeenCalledWith({
          text: 'whoops',
          type: 'error',
        })
      })
    })

    describe('get uploadMediaTranslations', () => {
      it('requires mediaTranslations if it needs to', () => {
        Bridge._uploadMediaTranslations = null
        const umt = Bridge.uploadMediaTranslations
        expect(umt).toBeDefined()
      })

      it('uses the cached value if available', () => {
        Bridge._uploadMediaTranslations = {foo: 1}
        const umt = Bridge.uploadMediaTranslations
        expect(umt).toEqual({foo: 1})
      })
    })
  })
})
