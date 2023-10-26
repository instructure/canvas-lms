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
import LinkOptionsTrayController, {CONTAINER_ID} from '../LinkOptionsTrayController'
import FakeEditor from '../../../../../__tests__/FakeEditor'
import LinkOptionsTrayDriver from './LinkOptionsTrayDriver'
import * as contentSelection from '../../../../shared/ContentSelection'

describe('RCE "Links" Plugin > LinkOptionsTray > LinkOptionsTrayController', () => {
  let editors
  let trayController

  beforeEach(() => {
    contentSelection.getLinkContentFromEditor = jest.fn(_editor => ({}))
    editors = [new FakeEditor(), new FakeEditor()]
    editors.forEach(editor => {
      editor.initialize()
    })
    trayController = new LinkOptionsTrayController()
  })

  afterEach(() => {
    jest.restoreAllMocks()
    editors.forEach(editor => editor.uninitialize())
    const $container = document.getElementById(CONTAINER_ID)
    if ($container != null) {
      ReactDOM.unmountComponentAtNode($container)
    }
  })

  function getTray() {
    return LinkOptionsTrayDriver.find()
  }

  describe('#showTrayForEditor()', () => {
    describe('when the tray is not already open', () => {
      it('opens the tray', () => {
        trayController.showTrayForEditor(editors[0])
        expect(getTray()).not.toBeNull()
      })
    })

    describe('when the tray is open for a different editor', () => {
      beforeEach(() => {
        trayController.showTrayForEditor(editors[0])
        trayController.showTrayForEditor(editors[1])
      })

      it('keeps the tray open', () => {
        expect(getTray()).not.toBeNull()
      })
    })

    describe('when the tray is already open for the given editor', () => {
      beforeEach(() => {
        trayController.showTrayForEditor(editors[0])
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
      await waitFor(() => expect(getTray()).toBeNull()) // tray is closed after a transition
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
})
