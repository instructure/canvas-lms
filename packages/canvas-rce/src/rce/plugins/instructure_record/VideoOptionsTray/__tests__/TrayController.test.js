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

import TrayController, {CONTAINER_ID} from '../TrayController'
import FakeEditor from '../../../shared/__tests__/FakeEditor'
import VideoOptionsTrayDriver from './VideoOptionsTrayDriver'
import {VIDEO_SIZE_OPTIONS} from '../TrayController'

describe('RCE "Videos" Plugin > VideoOptionsTray > TrayController', () => {
  let $videos
  let editors
  let trayController

  beforeEach(() => {
    $videos = []
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach((editor) => {
      editor.initialize()
      const $video = createVideo(320, 320)
      $videos.push($video)
      editor.appendElement($video)
      editor.setSelectedNode($video)
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

  function createVideo(height = 200, width = 200, id = "12345bseds") {
    const $el = document.createElement('div')
    $el.setAttribute("style",`height: ${height}; width:${width}`);
    $el.id = id
    return $el
  }

  function getTray() {
    return VideoOptionsTrayDriver.find()
  }

  function getVideoOptionsFromTray() {
    const driver = VideoOptionsTrayDriver.find()
    return {
      size: driver.size
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
        expect(getVideoOptionsFromTray().size).toEqual("Medium")
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

      it('updates the tray for the given editor', () => {
        expect(getVideoOptionsFromTray().altText).toEqual($videos[1].alt)
      })
    })

    describe('when the tray is already open for the given editor', () => {
      let $otherVideo

      beforeEach(async () => {
        trayController.showTrayForEditor(editors[0])

        $otherVideo = createVideo(210, 210)
        editors[0].setSelectedNode($otherVideo)
        trayController.showTrayForEditor(editors[0])
      })

      it('keeps the tray open', () => {
        expect(getTray()).not.toBeNull()
      })

      it('updates the tray with the selected image from the editor', () => {
        expect(getVideoOptionsFromTray().altText).toEqual($otherVideo.alt)
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

  describe('when saving video options', () => {
    let tray

    describe('when the video size is changing', () => {
      it('updates the video element size', async () => {
        trayController.showTrayForEditor(editors[0])
        tray = getTray()
        await tray.setSize('Large')
        tray.$doneButton.click()
        expect($videos[0].style.height).toEqual(VIDEO_SIZE_OPTIONS['large'].height)
        expect($videos[0].style.width).toEqual(VIDEO_SIZE_OPTIONS['large'].width)
      })
    })
  })
})
