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
import RCEGlobals from '../../../../RCEGlobals'
import {createLiveRegion, removeLiveRegion} from '../../../../__tests__/liveRegionHelper'
import bridge from '../../../../../bridge'

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

  function getVideoOptionsFromTray() {
    const driver = VideoOptionsTrayDriver.find()
    return {
      titleText: driver.titleText,
      displayAs: driver.displayAs,
      size: driver.size,
    }
  }

  describe('#showTrayForEditor()', () => {
    describe('when the tray is not already open', () => {
      it('opens the tray', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getTray()).not.toBeNull()
      })

      it('uses the selected video from the editor', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getVideoOptionsFromTray().titleText).toEqual($videos[0].getAttribute('title'))
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

    describe('when the tray is already open for the given editor', () => {
      let $otherVideo

      beforeEach(async () => {
        trayController.showTrayForEditor(editors[0])

        $otherVideo = createVideo(0)
        editors[0].setSelectedNode($otherVideo)
        trayController.showTrayForEditor(editors[0])
      })

      it('keeps the tray open', () => {
        expect(getTray()).not.toBeNull()

        expect(trayController.$videoContainer).not.toBeNull()
      })
    })
  })

  describe('#hideTrayForEditor()', () => {
    it('closes the tray when open for the given editor', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000}) // the tray is closed after a transition
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

  describe('#_applyVideoOptions', () => {
    beforeEach(() => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: false})
    })

    afterEach(() => {
      jest.resetAllMocks()
    })

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
        updateMediaObject,
      })
      expect(updateMediaObject).toHaveBeenCalledWith({
        media_object_id: 'm_somevideo',
        subtitles: undefined,
        title: 'new title',
      })
    })

    it('calls updateMediaObject with correct params with media_links_use_attachment_id', () => {
      RCEGlobals.getFeatures = jest.fn().mockReturnValue({media_links_use_attachment_id: true})
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
        subtitles: undefined,
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
