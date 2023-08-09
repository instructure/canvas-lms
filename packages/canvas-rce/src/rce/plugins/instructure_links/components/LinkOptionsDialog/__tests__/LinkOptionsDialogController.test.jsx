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

import LinkOptionsDialogController, {CONTAINER_ID} from '../LinkOptionsDialogController'
import FakeEditor from '../../../../../__tests__/FakeEditor'
import bridge from '../../../../../../bridge'
import LinkOptionsDialogDriver from './LinkOptionsDialogDriver'

jest.mock('../../../../../../bridge')

describe('RCE "Links" Plugin > LinkOptionsDialog > LinkOptionsDialogController', () => {
  let dialogController
  let editor

  beforeEach(() => {
    editor = new FakeEditor()
    editor.initialize()

    dialogController = new LinkOptionsDialogController()
  })

  afterEach(() => {
    editor.uninitialize()
    const $container = document.getElementById(CONTAINER_ID)
    if ($container != null) {
      ReactDOM.unmountComponentAtNode($container)
    }
  })

  function getDialog(op) {
    return LinkOptionsDialogDriver.find(op)
  }

  describe('#showDialogForEditor()', () => {
    describe('when creating a new link', () => {
      it('opens the dialog', () => {
        dialogController.showDialogForEditor(editor, 'create')
        expect(getDialog('create')).not.toBeNull()
      })
    })

    describe('when editing an existing link', () => {
      it('opens the dialog', () => {
        dialogController.showDialogForEditor(editor, 'edit')
        expect(getDialog('edit')).not.toBeNull()
      })
    })
  })

  describe('#hideDialogForEditor()', () => {
    it('closes the dialog when open', () => {
      dialogController.showDialogForEditor(editor, 'create')
      dialogController.hideDialog()
      expect(getDialog()).toBeNull()
    })

    it('does nothing when the dialog was not open', () => {
      // In effect, it does not explode.
      dialogController.hideDialog()
      expect(getDialog()).toBeNull()
    })
  })

  describe('#_applyLinkOptions', () => {
    it('dismisses the dialog', () => {
      dialogController.showDialogForEditor(editor, 'create')
      dialogController._applyLinkOptions({})
      expect(getDialog()).toBeNull()
    })

    it('inserts the link', () => {
      dialogController.showDialogForEditor(editor, 'create')
      dialogController._applyLinkOptions({})
      expect(bridge.insertLink).toHaveBeenCalledWith({})
    })
  })

  describe('Done', () => {
    it('focuses the editor on saving the new link', () => {
      dialogController.showDialogForEditor(editor, 'create')
      const lodd = getDialog('create')
      lodd.setText('link text')
      lodd.setLink('http://example.com')
      lodd.$doneButton.click()
      expect(bridge.focusEditor).toHaveBeenCalledWith(editor.rceWrapper)
    })
  })
})
