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

import ReactDOM from 'react-dom'

import {waitFor} from '@testing-library/dom'
import TrayController, {CONTAINER_ID} from '../TrayController'
import FakeEditor from '../../../../__tests__/FakeEditor'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'
import * as contentSelection from '../../../shared/ContentSelection'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import bridge from '../../../../../bridge'
import RCEGlobals from '../../../../RCEGlobals'

import {findMediaPlayerIframe} from '../../../shared/iframeUtils'

const mockVideoPlayers = [
  {
    titleText: 'video title 0',
    appliedWidth: 400,
    appliedHeight: 300,
    naturalWidth: 800,
    naturalHeight: 600,
    source: '/path/to/video0.mp4',
    type: 'video-embed',
    id: 'm-video-id0',
  },
  {
    titleText: 'video title 1',
    appliedWidth: 400,
    appliedHeight: 300,
    naturalWidth: 800,
    naturalHeight: 600,
    source: '/path/to/video1.mp4',
    type: 'video-embed',
    id: 'm-video-id1',
  },
  {
    titleText: 'video title2',
    appliedWidth: 400,
    appliedHeight: 300,
    naturalWidth: 800,
    naturalHeight: 600,
    source: '/path/to/video2.mp4',
    type: 'video-embed',
    id: 'm-video-id2',
  },
]

beforeAll(() => {
  contentSelection.asVideoElement = jest.fn(elem => {
    const vid = elem.parentElement.getAttribute('id')
    return mockVideoPlayers.find(vp => vp.id === vid)
  })
})

afterAll(() => {
  jest.restoreAllMocks()
})

describe('RCE "Videos" Plugin > VideoOptionsTray > TrayController', () => {
  let $videos
  let editors
  let trayController

  beforeEach(() => {
    createLiveRegion()

    $videos = []
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach((editor, i) => {
      editor.initialize()
      const $video = createVideo(i)
      $videos.push($video)
      editor.appendElement($video)
      editor.setSelectedNode($video)
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

  function createVideo(i) {
    const velem = document.createElement('div')
    velem.setAttribute('id', mockVideoPlayers[i].id)
    velem.setAttribute('title', mockVideoPlayers[i].titleText)
    velem.setAttribute('data-mce-p-src', 'http://video.is.here/')
    const ifr = document.createElement('iframe')
    velem.appendChild(ifr)
    return velem
  }

  function getTray() {
    return VideoOptionsTrayDriver.find()
  }

  describe('#_applyVideoOptions', () => {
    it('updates the video', async () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        displayAs: 'embed',
        appliedHeight: '101',
        appliedWidth: '321',
        titleText: 'new title',
        media_object_id: 'm_somevideo',
        updateMediaObject,
      })
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000}) // the tray is closed after a transition
      const videoIframe = trayController.$videoContainer
      const videoContainer = videoIframe.parentElement
      expect(videoContainer.getAttribute('data-mce-p-title')).toBe('new title')
      expect(videoIframe.getAttribute('title')).toBe('new title')
      expect(videoContainer.style.height).toBe('101px')
      expect(videoContainer.style.width).toBe('321px')
      expect(updateMediaObject).toHaveBeenCalled()
    })

    it('calls updateMediaObject with correct params', () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        displayAs: 'embed',
        appliedHeight: '101',
        appliedWidth: '321',
        titleText: 'new title',
        media_object_id: 'm_somevideo',
        attachment_id: '123',
        updateMediaObject,
      })
      expect(updateMediaObject).toHaveBeenCalledWith({
        attachment_id: '123',
        media_object_id: 'm_somevideo',
        skipCaptionUpdate: false,
        subtitles: undefined,
        title: 'new title',
      })
    })

    it('sets skipCaptionUpdate to true when rce_asr_captioning_improvements flag is ON', () => {
      const RCEGlobals = require('../../../../RCEGlobals').default
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({rce_asr_captioning_improvements: true})

      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        displayAs: 'embed',
        appliedHeight: '101',
        appliedWidth: '321',
        titleText: 'new title',
        media_object_id: 'm_somevideo',
        attachment_id: '123',
        subtitles: [{locale: 'en', file: {name: 'test.vtt'}}],
        updateMediaObject,
      })

      // skipCaptionUpdate should be true to prevent duplicate caption updates
      expect(updateMediaObject).toHaveBeenCalledWith({
        attachment_id: '123',
        media_object_id: 'm_somevideo',
        subtitles: [{locale: 'en', file: {name: 'test.vtt'}}],
        skipCaptionUpdate: true,
        title: 'new title',
      })
    })

    it('sets skipCaptionUpdate to false when rce_asr_captioning_improvements flag is OFF', () => {
      const RCEGlobals = require('../../../../RCEGlobals').default
      jest
        .spyOn(RCEGlobals, 'getFeatures')
        .mockReturnValue({rce_asr_captioning_improvements: false})

      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        displayAs: 'embed',
        appliedHeight: '101',
        appliedWidth: '321',
        titleText: 'new title',
        media_object_id: 'm_somevideo',
        attachment_id: '123',
        subtitles: [{locale: 'en', file: {name: 'test.vtt'}}],
        updateMediaObject,
      })

      // skipCaptionUpdate should be false to allow caption updates
      expect(updateMediaObject).toHaveBeenCalledWith({
        attachment_id: '123',
        media_object_id: 'm_somevideo',
        subtitles: [{locale: 'en', file: {name: 'test.vtt'}}],
        skipCaptionUpdate: false,
        title: 'new title',
      })
    })

    it('does not update the video w/o a media_object_id', async () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        displayAs: 'embed',
        appliedHeight: '101',
        appliedWidth: '321',
        titleText: 'new title',
        media_object_id: undefined,
        updateMediaObject,
      })
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000}) // the tray is closed after a transition
      const videoIframe = trayController.$videoContainer
      const videoContainer = videoIframe.parentElement
      expect(videoContainer.getAttribute('data-mce-p-title')).toBe('new title')
      expect(videoIframe.getAttribute('title')).toBe('new title')
      expect(videoContainer.style.height).toBe('101px')
      expect(videoContainer.style.width).toBe('321px')
      expect(updateMediaObject).not.toHaveBeenCalled()
    })

    it('does update video w/o media_object_id if attachment_id present', async () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        displayAs: 'embed',
        appliedHeight: '101',
        appliedWidth: '321',
        titleText: 'new title',
        media_object_id: undefined,
        attachment_id: '123',
        updateMediaObject,
      })
      expect(updateMediaObject).toHaveBeenCalledWith({
        attachment_id: '123',
        media_object_id: undefined,
        skipCaptionUpdate: false,
        subtitles: undefined,
        title: 'new title',
      })
    })

    it('does not try to save data to the db on a locked media attachment', () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      trayController.showTrayForEditor(editors[0])
      trayController._applyVideoOptions({
        editLocked: true,
        media_object_id: 'm_somevideo',
        updateMediaObject,
      })
      expect(updateMediaObject).not.toHaveBeenCalled()
    })

    it('replaces the video with a link', async () => {
      const updateMediaObject = jest.fn().mockResolvedValue()
      const ed = editors[0]
      trayController.showTrayForEditor(ed)
      trayController._applyVideoOptions({
        displayAs: 'link',
        titleText: 'new <em>fancy</em> title',
        media_object_id: 'm_somevideo',
        updateMediaObject,
      })
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000}) // the tray is closed after a transition
      const videoContainer = trayController.$videoContainer
      expect(videoContainer).toBe(null)
      const sel = ed.selection.getNode()
      expect(sel.tagName).toBe('A')
      expect(sel.getAttribute('href')).toBe('http://video.is.here/')
      expect(sel.innerHTML).toBe('new &lt;em&gt;fancy&lt;/em&gt; title') // see, html is not evaluated
      expect(updateMediaObject).toHaveBeenCalled()
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

  describe('focus behavior on tray close', () => {
    beforeEach(() => {
      jest.spyOn(bridge, 'focusActiveEditor')
    })

    afterEach(() => {
      bridge.focusActiveEditor.mockRestore()
    })

    it('calls bridge.focusActiveEditor when closing normally', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})
      expect(bridge.focusActiveEditor).toHaveBeenCalledWith(false)
    })

    it('does not call bridge.focusActiveEditor when skipFocusOnExit is true', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0], true)
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})
      expect(bridge.focusActiveEditor).not.toHaveBeenCalled()
    })

    it('resets skipFocusOnExit flag after tray closes', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0], true)
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})
      expect(bridge.focusActiveEditor).not.toHaveBeenCalled()

      bridge.focusActiveEditor.mockClear()

      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})
      expect(bridge.focusActiveEditor).toHaveBeenCalledWith(false)
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

      // Spy on the _reloadVideoPlayer method
      const reloadSpy = jest.spyOn(trayController, '_reloadVideoPlayer')

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

      // Spy on the _reloadVideoPlayer method
      const reloadSpy = jest.spyOn(trayController, '_reloadVideoPlayer')

      // Simulate caption modification
      trayController._captionsModified = true

      // Close tray
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000})

      // Assert: reload SHOULD be called
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

      // Spy on the _reloadVideoPlayer method
      const reloadSpy = jest.spyOn(trayController, '_reloadVideoPlayer')

      // Do NOT modify captions (trayController._captionsModified stays false)

      // Close tray
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull())

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

    it('does not crash when video container is null on dismiss', async () => {
      // Mock feature flag ON
      const getFeaturesSpy = jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({
        rce_asr_captioning_improvements: true,
      })

      // Open tray
      trayController.showTrayForEditor(editors[0])

      // Simulate caption modification
      trayController._captionsModified = true

      // Clear video container (edge case)
      trayController.$videoContainer = null

      // Close tray - should not crash
      expect(() => {
        trayController.hideTrayForEditor(editors[0])
      }).not.toThrow()

      // Cleanup
      getFeaturesSpy.mockRestore()
    })
  })
})
