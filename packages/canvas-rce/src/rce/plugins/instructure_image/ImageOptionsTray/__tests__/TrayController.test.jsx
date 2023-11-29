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
import ImageOptionsTrayDriver from './ImageOptionsTrayDriver'

describe('RCE "Images" Plugin > ImageOptionsTray > TrayController', () => {
  let $images
  let editors
  let trayController

  beforeEach(() => {
    $images = []
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach((editor, index) => {
      editor.initialize()
      const $image = createImage(200 + index, 200 + index)
      $images.push($image)
      editor.appendElement($image)
      editor.setSelectedNode($image)
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

  function createImage(height = 200, width = 200) {
    const $el = document.createElement('img')
    $el.src = `https://www.fillmurray.com/${height}/${width}`
    $el.alt = `Bill Murray, ${width} by ${height}`
    $el.setAttribute('height', height)
    $el.setAttribute('width', width)
    return $el
  }

  function getTray() {
    return ImageOptionsTrayDriver.find()
  }

  function getImageOptionsFromTray() {
    const driver = ImageOptionsTrayDriver.find()
    return {
      altText: driver.altText,
      displayAs: driver.displayAs,
      isDecorativeImage: driver.isDecorativeImage,
      size: driver.size,
    }
  }

  describe('#showTrayForEditor()', () => {
    describe('when the tray is not already open', () => {
      it('opens the tray', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getTray()).not.toBeNull()
      })

      it('uses the selected image from the editor', async () => {
        trayController.showTrayForEditor(editors[0])
        expect(getImageOptionsFromTray().altText).toEqual($images[0].alt)
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
        expect(getImageOptionsFromTray().altText).toEqual($images[1].alt)
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
        expect(getTray()).not.toBeNull()
      })

      it('updates the tray with the selected image from the editor', () => {
        expect(getImageOptionsFromTray().altText).toEqual($otherImage.alt)
      })
    })
  })

  describe('#hideTrayForEditor()', () => {
    it('closes the tray when open for the given editor', async () => {
      trayController.showTrayForEditor(editors[0])
      trayController.hideTrayForEditor(editors[0])
      await waitFor(() => expect(getTray()).toBeNull(), {timeout: 2000}) // tray is closed after a transition
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

  describe('when saving image options', () => {
    let tray

    describe('when the image url text is changing', () => {
      it('updates the image element url', () => {
        trayController.showTrayForEditor(editors[0])
        tray = getTray()
        tray.setUrl('https://www.fillmurray.com/140/100')
        tray.$doneButton.click()
        expect(editors[0].$container.querySelector('img').getAttribute('src')).toEqual(
          'https://www.fillmurray.com/140/100'
        )
      })
    })

    describe('when the image alt text is changing', () => {
      it('updates the image element alt text', () => {
        trayController.showTrayForEditor(editors[0])
        tray = getTray()
        tray.setAltText('Bill Murray, always amazing')
        tray.$doneButton.click()
        expect(editors[0].$container.querySelector('img').getAttribute('alt')).toEqual(
          'Bill Murray, always amazing'
        )
      })
    })

    describe('when the image is set as decorative', () => {
      beforeEach(() => {
        trayController.showTrayForEditor(editors[0])
        tray = getTray()
        tray.setIsDecorativeImage(true)
        tray.$doneButton.click()
      })

      it('sets a role to persist the option', () => {
        expect(editors[0].$container.querySelector('img').getAttribute('role')).toEqual(
          'presentation'
        )
      })
    })

    describe('when the image is unset as decorative', () => {
      beforeEach(() => {
        $images[0].alt = ''
        $images[0].setAttribute('role', 'presentation')
        trayController.showTrayForEditor(editors[0])
        tray = getTray()
        tray.setIsDecorativeImage(false)
        tray.setAltText('Bill Murray, always amazing')
        tray.$doneButton.click()
      })

      it('updates the image element alt text', () => {
        expect(editors[0].$container.querySelector('img').getAttribute('alt')).toEqual(
          'Bill Murray, always amazing'
        )
      })

      it('sets a role attribute to persist the option', () => {
        expect(editors[0].$container.querySelector('img').getAttribute('role')).toBeNull()
      })
    })

    describe('when the image will be displayed as a link', () => {
      beforeEach(() => {
        trayController.showTrayForEditor(editors[0])
        tray = getTray()
        tray.setDisplayAs('link')
        tray.$doneButton.click()
      })

      it('removes the image', () => {
        expect(editors[0].$container.querySelector('img')).toBeNull()
      })

      it('replaces the image with a link', () => {
        const $link = editors[0].selection.getNode()
        expect($link.tagName.toLowerCase()).toEqual('a')
      })

      it('uses the image src for the link href', () => {
        const $link = editors[0].selection.getNode()
        expect($link.href).toEqual($images[0].src)
      })

      it('uses the image alt text for the link label', () => {
        const $link = editors[0].selection.getNode()
        expect($link.textContent.trim()).toEqual($images[0].alt)
      })

      it('sets focus on the editor', () => {
        // Focus otherwise goes to the document body at this time.
        expect(document.activeElement).toBe(editors[0].$iframe)
      })
    })
  })
})
