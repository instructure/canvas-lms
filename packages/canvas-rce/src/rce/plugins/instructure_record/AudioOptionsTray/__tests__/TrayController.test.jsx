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
import {act} from 'react-dom/test-utils'

import {waitFor, screen} from '@testing-library/dom'
import TrayController, {CONTAINER_ID} from '../TrayController'
import FakeEditor from '../../../../__tests__/FakeEditor'
import AudioOptionsTrayDriver from './AudioOptionsTrayDriver'
import * as contentSelection from '../../../shared/ContentSelection'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import bridge from '../../../../../bridge'
import RCEGlobals from '../../../../RCEGlobals'

import {findMediaPlayerIframe} from '../../../shared/iframeUtils'

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
    beforeEach(() => {
      // container?.contentWindow.location.reload() is not defined in jsdom
      const iframe = findMediaPlayerIframe(editors[0].selection.getNode())
      delete iframe.contentWindow.location
      iframe.contentWindow.location = {reload: jest.fn()}
    })

    it('updates the audio', () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: 'audio_id',
        updateMediaObject,
      })
      expect(updateMediaObject).toHaveBeenCalled()
    })

    it('does not update the audio w/o a media_object_id', async () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: undefined,
        updateMediaObject,
      })
      expect(updateMediaObject).not.toHaveBeenCalled()
    })

    it('does update audio w/o media_object_id if attachment_id present', async () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: undefined,
        attachment_id: '123',
        updateMediaObject,
      })
      expect(updateMediaObject).toHaveBeenCalledWith({
        attachment_id: '123',
        media_object_id: undefined,
        skipCaptionUpdate: false,
        subtitles: undefined,
      })
    })
  })

  describe('#_dismissTray', () => {
    it('closes the tray', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController._dismissTray()
      await waitFor(() => expect(getTray()).toBeNull()) // the tray is closed after a transition
    })
  })

  describe('#requestSubtitlesFromIframe', () => {
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
      const iframe = findMediaPlayerIframe(editors[0].selection.getNode())
      iframe.contentWindow.postMessage = postMessageMock
      trayController.showTrayForEditor(editors[0])
      expect(postMessageMock).toHaveBeenCalledTimes(1)
    })

    it('cleans up event listener on tray close', () => {
      const postMessageMock = jest.fn()
      const iframe = findMediaPlayerIframe(editors[0].selection.getNode())
      iframe.contentWindow.postMessage = postMessageMock
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

  describe('caption update behavior with feature flag', () => {
    it('calls updateMediaObject with skipCaptionUpdate=false when feature flag is OFF', () => {
      // Mock feature flag OFF (old flow)
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: false,
      })

      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: 'audio_id',
        attachment_id: '123',
        subtitles: [{locale: 'en'}],
        updateMediaObject,
      })

      expect(updateMediaObject).toHaveBeenCalledWith({
        media_object_id: 'audio_id',
        attachment_id: '123',
        subtitles: [{locale: 'en'}],
        skipCaptionUpdate: false, // Old flow - updates captions via API
      })

      // Cleanup
      getFeaturesSpy.mockRestore()
    })

    it('calls updateMediaObject with skipCaptionUpdate=true when feature flag is ON', () => {
      // Mock feature flag ON (new flow)
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: true,
      })

      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: 'audio_id',
        attachment_id: '123',
        subtitles: [{locale: 'en'}],
        updateMediaObject,
      })

      expect(updateMediaObject).toHaveBeenCalledWith({
        media_object_id: 'audio_id',
        attachment_id: '123',
        subtitles: [{locale: 'en'}],
        skipCaptionUpdate: true, // New flow - captions managed via upload/delete callbacks
      })

      // Cleanup
      getFeaturesSpy.mockRestore()
    })

    it('defaults to skipCaptionUpdate=false when feature flag is not defined', () => {
      // Mock feature flag undefined
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue(undefined)

      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyAudioOptions({
        media_object_id: 'audio_id',
        attachment_id: '123',
        subtitles: [{locale: 'en'}],
        updateMediaObject,
      })

      expect(updateMediaObject).toHaveBeenCalledWith({
        media_object_id: 'audio_id',
        attachment_id: '123',
        subtitles: [{locale: 'en'}],
        skipCaptionUpdate: false, // Defaults to old flow
      })

      // Cleanup
      getFeaturesSpy.mockRestore()
    })
  })

  describe('caption reload on tray dismiss', () => {
    it('does NOT reload iframe on dismiss when feature flag is OFF', async () => {
      // Mock feature flag OFF
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: false,
      })

      // Open tray
      trayController.showTrayForEditor(editors[0])

      // Spy on the _reloadAudioPlayer method
      const reloadSpy = jest.spyOn(trayController, '_reloadAudioPlayer')

      // Simulate caption modification
      trayController._captionsModified = true

      // Close tray
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})

      // Assert: reload should NOT be called (old behavior preserved)
      expect(reloadSpy).not.toHaveBeenCalled()

      // Cleanup
      reloadSpy.mockRestore()
      getFeaturesSpy.mockRestore()
    })

    it('reloads iframe on dismiss when feature flag is ON and captions were modified', async () => {
      // Mock feature flag ON
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: true,
      })

      // Open tray
      trayController.showTrayForEditor(editors[0])

      // Spy on the _reloadAudioPlayer method
      const reloadSpy = jest.spyOn(trayController, '_reloadAudioPlayer')

      // Simulate caption modification
      trayController._captionsModified = true

      // Close tray
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})

      // Assert: _reloadAudioPlayer SHOULD be called
      expect(reloadSpy).toHaveBeenCalledTimes(1)

      // Cleanup
      reloadSpy.mockRestore()
      getFeaturesSpy.mockRestore()
    })

    it('does NOT reload iframe on dismiss when feature flag is ON but captions were NOT modified', async () => {
      // Mock feature flag ON
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: true,
      })

      // Open tray
      trayController.showTrayForEditor(editors[0])

      // Spy on the _reloadAudioPlayer method
      const reloadSpy = jest.spyOn(trayController, '_reloadAudioPlayer')

      // Do NOT modify captions (trayController._captionsModified stays false)

      // Close tray
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})

      // Assert: reload should NOT be called (no changes made)
      expect(reloadSpy).not.toHaveBeenCalled()

      // Cleanup
      reloadSpy.mockRestore()
      getFeaturesSpy.mockRestore()
    })

    it('resets caption modified flag when opening tray again', () => {
      // Mock feature flag ON
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: true,
      })

      // Open tray
      trayController.showTrayForEditor(editors[0])

      // Simulate caption modification
      trayController._captionsModified = true
      expect(trayController._captionsModified).toBe(true)

      // Close and reopen
      trayController.hideTrayForEditor(editors[0])
      trayController.showTrayForEditor(editors[0])

      // Assert: flag should be reset to false
      expect(trayController._captionsModified).toBe(false)

      // Cleanup
      getFeaturesSpy.mockRestore()
    })
  })
})
