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

import Bridge from '../Bridge'

describe('Bridge additional functionality', () => {
  let bridge
  let mockEditor
  let mockController

  beforeEach(() => {
    bridge = new Bridge()
    mockEditor = {
      id: 'editor1',
      mceInstance: jest.fn(),
      props: {
        textareaId: 'textarea1',
        tinymce: {
          get: jest.fn(),
        },
      },
    }
    mockController = {
      showTrayForPlugin: jest.fn(),
      hideTray: jest.fn(),
    }
  })

  describe('editor management', () => {
    it('sets and gets the focused editor', () => {
      bridge.focusEditor(mockEditor)
      expect(bridge.getEditor()).toBe(mockEditor)
    })

    it('blurs the editor', () => {
      bridge.focusEditor(mockEditor)
      bridge.blurEditor(mockEditor)
      expect(bridge.getEditor()).toBeNull()
    })

    it('only blurs if the current editor is being blurred', () => {
      const otherEditor = {id: 'other'}
      bridge.focusEditor(mockEditor)
      bridge.blurEditor(otherEditor)
      expect(bridge.getEditor()).toBe(mockEditor)
    })
  })

  describe('controller management', () => {
    it('attaches and retrieves a controller', () => {
      bridge.attachController(mockController, 'editor1')
      expect(bridge.controller('editor1')).toBe(mockController)
    })

    it('detaches a controller', () => {
      bridge.attachController(mockController, 'editor1')
      bridge.detachController('editor1')
      expect(bridge.controller('editor1')).toBeUndefined()
    })
  })

  describe('tray management', () => {
    beforeEach(() => {
      bridge.attachController(mockController, 'editor1')
    })

    it('shows tray for plugin', () => {
      bridge.showTrayForPlugin('plugin1', 'editor1')
      expect(mockController.showTrayForPlugin).toHaveBeenCalledWith('plugin1')
    })

    it('hides all trays', () => {
      const mockController2 = {hideTray: jest.fn()}
      bridge.attachController(mockController2, 'editor2')

      bridge.hideTrays()

      expect(mockController.hideTray).toHaveBeenCalledWith(true)
      expect(mockController2.hideTray).toHaveBeenCalledWith(true)
    })
  })

  describe('media server functionality', () => {
    it('sets and gets media server session', () => {
      const mockSession = {id: 'session1'}
      bridge.setMediaServerSession(mockSession)
      expect(bridge.mediaServerSession).toBe(mockSession)
    })

    it('creates a new uploader when setting session', () => {
      const mockSession = {id: 'session1'}
      bridge.setMediaServerSession(mockSession)
      expect(bridge.mediaServerUploader).toBeTruthy()
    })
  })

  describe('canvas origin', () => {
    it('sets and gets canvas origin', () => {
      const origin = 'https://canvas.test'
      bridge.canvasOrigin = origin
      expect(bridge.canvasOrigin).toBe(origin)
    })
  })

  describe('editor rendering', () => {
    it('resolves editorRendered promise when renderEditor is called', async () => {
      const promise = bridge.editorRendered
      bridge.renderEditor(mockEditor)
      await expect(promise).resolves.toBeUndefined()
    })

    it('focuses editor if no editor is focused', () => {
      bridge.renderEditor(mockEditor)
      expect(bridge.getEditor()).toBe(mockEditor)
    })

    it('does not change focused editor if one is already focused', () => {
      const otherEditor = {id: 'other'}
      bridge.focusEditor(otherEditor)
      bridge.renderEditor(mockEditor)
      expect(bridge.getEditor()).toBe(otherEditor)
    })
  })
})
