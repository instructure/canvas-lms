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
import FakeEditor from './FakeEditor'

describe('RCE "Images" Plugin > ImageOptionsTray > TrayController', () => {
  let $images
  let editors
  let trayController

  beforeEach(() => {
    $images = []
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach((editor, index) => {
      const $image = createImage(200 + index, 200 + index)
      $images.push($image)
      editor.setSelectedNode($image)
    })

    trayController = new TrayController()
  })

  afterEach(() => {
    const $container = document.getElementById(CONTAINER_ID)
    if ($container != null) {
      ReactDOM.unmountComponentAtNode($container)
    }
  })

  function createImage(height = 200, width = 200) {
    const $el = document.createElement('img')
    $el.src = `https://www.fillmurray.com/${height}/${width}`
    document.body.appendChild($el)
    return $el
  }

  function getTray() {
    return document.querySelector('[role="dialog"][aria-label="Image Options Tray"]')
  }

  // This is temporary until real content exists in the tray to assert on.
  function getImageAttributesFromTray() {
    return {
      src: getTray().querySelector('img').src
    }
  }

  describe('#showTrayForEditor()', () => {
    describe('when the tray is not already open', () => {
      it('opens the tray', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getTray()).toBeInTheDocument()
      })

      it('uses the selected image from the editor', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getImageAttributesFromTray().src).toEqual($images[0].src)
      })
    })

    describe('when the tray is open for a different editor', () => {
      beforeEach(async () => {
        trayController.showTrayForEditor(editors[0])
        trayController.showTrayForEditor(editors[1])
      })

      it('keeps the tray open', () => {
        expect(getTray()).toBeInTheDocument()
      })

      it('updates the tray for the given editor', () => {
        expect(getImageAttributesFromTray().src).toEqual($images[1].src)
      })
    })

    describe('when the tray is already open for the given editor', () => {
      let $otherImage

      beforeEach(async () => {
        trayController.showTrayForEditor(editors[0])

        $otherImage = createImage(210, 210)
        editors[0].setSelectedNode($otherImage)
        trayController.showTrayForEditor(editors[0])
      })

      it('keeps the tray open', () => {
        expect(getTray()).toBeInTheDocument()
      })

      it('updates the tray with the selected image from the editor', () => {
        expect(getImageAttributesFromTray().src).toEqual($otherImage.src)
      })
    })
  })

  describe('#hideTrayForEditor()', () => {
    it('closes the tray when open for the given editor', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).not.toBeInTheDocument()
    })

    it('does not close the tray when open for a different editor', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.showTrayForEditor(editors[1])
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).toBeInTheDocument()
    })

    it('does nothing when the tray was not open', () => {
      // In effect, it does not explode.
      trayController.hideTrayForEditor(editors[0])
      expect(getTray()).not.toBeInTheDocument()
    })
  })
})
