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

import {waitFor} from '@testing-library/dom'
import TrayController, {CONTAINER_ID} from '../TrayController'
import FakeEditor from '../../../../__tests__/FakeEditor'
import AudioOptionsTrayDriver from './AudioOptionsTrayDriver'
import * as contentSelection from '../../../shared/ContentSelection'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import bridge from '../../../../../bridge'

const MOCK_AUDIO_PLAYERS = [
  {
    id: 'audio_id',
    titleText: 'Audio Title for audio.mp3',
  },
]

beforeAll(() => {
  contentSelection.asAudioElement = jest.fn(elem => {
    const id = elem.parentElement.getAttribute('id')
    return MOCK_AUDIO_PLAYERS.find(ap => ap.id === id)
  })
})

afterAll(() => {
  jest.restoreAllMocks()
})

describe('RCE "Audios" Plugin > AudioOptionsTray > TrayController', () => {
  let editors
  let trayController

  beforeEach(() => {
    createLiveRegion()

    const trayProps = {
      host: 'http://canvas.docker',
      jwt: 'somevalue',
    }
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach((editor, i) => {
      editor.initialize()
      const audioElement = createAudio(i)
      editor.appendElement(audioElement)
      editor.setSelectedNode(audioElement)
      bridge.trayProps.set(editor, trayProps)
    })

    trayController = new TrayController()
  })

  afterEach(() => {
    removeLiveRegion()

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
    it('closes the tray when open for the given editor', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull()) // the tray is closed after a transition
    })

    it('does not close the tray when open for a different editor', () => {
      trayController.showTrayForEditor(editors[0])
      trayController.showTrayForEditor(editors[1])
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).not.toBeNull()
    })

    it('does nothing when the tray was not open', async () => {
      // In effect, it does not explode.
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull()) // the tray is closed after a transition
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
    it('closes the tray', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController._dismissTray()
      await waitFor(() => expect(getTray()).toBeNull()) // the tray is closed after a transition
    })
  })

  describe.only('#requestSubtitlesFromIframe', () => {
    let previousOrigin = ''

    beforeAll(() => {
      previousOrigin = bridge.canvasOrigin
      bridge.canvasOrigin = 'http://localhost'
    })

    afterAll(() => {
      bridge.canvasOrigin = previousOrigin
    })

    it('posts message to iframe onload', () => {
      const postMessageMock = jest.fn()
      const iframe = contentSelection.findMediaPlayerIframe(editors[0].selection.getNode())
      iframe.contentWindow.postMessage = postMessageMock;
      trayController.showTrayForEditor(editors[0])
      expect(postMessageMock).toHaveBeenCalledTimes(1)
    })

    it('cleans up event listener on tray close', () => {
      const postMessageMock = jest.fn()
      const iframe = contentSelection.findMediaPlayerIframe(editors[0].selection.getNode())
      iframe.contentWindow.postMessage = postMessageMock;
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      trayController.showTrayForEditor(editors[0])
      expect(postMessageMock).toHaveBeenCalledTimes(2)
    })

    it('adds an event listener with a callback', () => {
      const eventMock = jest.fn()
      trayController.requestSubtitlesFromIframe(eventMock)
      const msgEvent = new Event('message')
      msgEvent.data = {subject: 'media_tracks_response', payload: [{locale: 'en'}]}
      window.dispatchEvent(msgEvent)
      expect(eventMock).toHaveBeenCalledTimes(1)
      expect(eventMock).toHaveBeenCalledWith([{locale: 'en'}])
    })

    it('event listener ignores events with wrong subject', () => {
      const eventMock = jest.fn()
      trayController.requestSubtitlesFromIframe(eventMock)
      const msgEvent = new Event('message')
      msgEvent.data = {subject: 'wrong_response', payload: [{locale: 'en'}]}
      window.dispatchEvent(msgEvent)
      expect(eventMock).toHaveBeenCalledTimes(0)
    })
  })
})
