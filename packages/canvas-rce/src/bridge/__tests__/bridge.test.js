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

  it('focusEditor sets the active editor', () => {
    const editor = {}
    Bridge.focusEditor(editor)
    expect(Bridge.activeEditor()).toBe(editor)
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
        insertLink: jest.fn(),
        insertVideo: jest.fn(),
        insertAudio: jest.fn(),
        insertEmbedCode: jest.fn(),
        props: {
          textareaId: 'fake_editor',
          tinymce: {
            get(_id) {
              return {
                selection: {
                  getRng: jest.fn(() => 'some-range'),
                  getNode: jest.fn(() => 'some-node')
                }
              }
            }
          }
        }
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
            range: 'some-range'
          }
        })
      })

      it('calls hideTray when necessary', () => {
        const hideTray = jest.fn()
        Bridge.attachController({hideTray})
        Bridge.focusEditor(editor)
        Bridge.insertLink({})
        expect(hideTray).toHaveBeenCalledTimes(1)
      })

      it("does not call hideTray when it shouldn't", () => {
        const hideTray = jest.fn()
        Bridge.attachController({hideTray})
        Bridge.focusEditor(editor)
        Bridge.insertLink({}, false)
        expect(hideTray).not.toHaveBeenCalled()
      })
    })

    describe('embedMedia', () => {
      let hideTray
      beforeEach(() => {
        hideTray = jest.fn()
        Bridge.attachController({hideTray})
        Bridge.focusEditor(editor)
      })

      it('inserts video when media is video', () => {
        jest.spyOn(Bridge, 'insertVideo')
        const theMedia = {type: 'video'}
        Bridge.embedMedia(theMedia)
        expect(Bridge.insertVideo).toHaveBeenCalledWith(theMedia)
        expect(editor.insertVideo).toHaveBeenCalledWith(theMedia)
        expect(hideTray).toHaveBeenCalled()
      })

      it('inserts audio when media is audio', () => {
        jest.spyOn(Bridge, 'insertAudio')
        const theMedia = {type: 'audio'}
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
  })
})
