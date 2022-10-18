/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import ReactDOM from 'react-dom'

import TrayController, {CONTAINER_ID} from '../TrayController'
import FakeEditor from '../../../shared/__tests__/FakeEditor'
import AudioOptionsTrayDriver from './AudioOptionsTrayDriver'
import * as contentSelection from '../../../shared/ContentSelection'

beforeAll(() => {
  contentSelection.asAudioElement = jest.fn(elem => {
    const id = elem.parentElement.getAttribute('id')
    return id === 'audio_id'
  })
})

afterAll(() => {
  jest.restoreAllMocks()
})

describe('RCE "Audios" Plugin > AudioOptionsTray > TrayController', () => {
  let editors
  let trayController

  beforeEach(() => {
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach((editor, i) => {
      editor.initialize()
      const audioElement = createAudio(i)
      editor.appendElement(audioElement)
      editor.setSelectedNode(audioElement)
    })

    trayController = new TrayController()
  })

  afterEach(() => {
    editors.forEach(editor => editor.uninitialize())
    const $container = document.getElementById(CONTAINER_ID)
    if ($container != null) {
      ReactDOM.unmountComponentAtNode($container)
    }
  })

  function createAudio() {
    const velem = document.createElement('div')
    velem.setAttribute('id', 'audio_id')
    velem.setAttribute('data-mce-p-src', 'http://audio.is.here/')
    const ifr = document.createElement('iframe')
    velem.appendChild(ifr)
    return velem
  }

  function getTray() {
    return AudioOptionsTrayDriver.find()
  }

  describe('#showTrayForEditor()', () => {
    describe('when the tray is not already open', () => {
      it('opens the tray', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getTray()).not.toBeNull()
      })
    })

    describe('when the tray is open for a different editor', () => {
      beforeEach(async () => {
        trayController.showTrayForEditor(editors[0])
        trayController.showTrayForEditor(editors[1])
      })

      it('keeps the tray open', () => {
        expect(getTray()).not.toBeNull()
      })
    })
  })

  describe('#hideTrayForEditor()', () => {
    it('closes the tray when open for the given editor', () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).toBeNull()
    })

    it('does not close the tray when open for a different editor', () => {
      trayController.showTrayForEditor(editors[0])
      trayController.showTrayForEditor(editors[1])
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).not.toBeNull()
    })

    it('does nothing when the tray was not open', () => {
      // In effect, it does not explode.
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).toBeNull()
    })
  })

  describe('#_applyAudioOptions', () => {
    it('updates the audio', () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: 'audio_id',
        updateMediaObject,
      })
      expect(updateMediaObject).toHaveBeenCalled()
    })
  })

  describe('#_dismissTray', () => {
    it('closes the tray', () => {
      trayController.showTrayForEditor(editors[0])
      trayController._dismissTray()
      expect(getTray()).toBeNull() // the tray is closed
    })
  })
})
