/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {screen, waitFor, fireEvent} from '@testing-library/dom'

import TrayController from '../TrayController'
import FakeEditor from '../../../../__tests__/FakeEditor'

describe('RCE "Images" Plugin > ImageOptionsTray > TrayController for Icon Maker Icons', () => {
  const isIconMaker = true

  function createEditorForIcon(iconForEditor) {
    const ed = new FakeEditor()
    ed.initialize()
    ed.appendElement(iconForEditor)
    ed.setSelectedNode(iconForEditor)
    return ed
  }
  function createIcon(altText) {
    const isDecorative = altText === ''
    const iconUrl = isDecorative
      ? 'https://www.fillmurray.com/200/201'
      : 'https://www.fillmurray.com/200/200'
    const $icon = document.createElement('img')
    $icon.src = iconUrl
    $icon.alt = altText
    $icon.setAttribute('data-inst-icon-maker-icon', true)
    if (isDecorative) {
      $icon.role = 'presentation'
    }
    return $icon
  }

  function setup() {
    const iconImage = createIcon('stripes')
    const editorForIcon = createEditorForIcon(iconImage)

    const iconDecorative = createIcon('')
    const editorForDecorative = createEditorForIcon(iconDecorative)

    const iconTrayController = new TrayController()

    return {iconImage, editorForIcon, iconTrayController, iconDecorative, editorForDecorative}
  }

  function getAltTextFromTrayInput() {
    return screen.getByPlaceholderText(/(describe the icon)/i)
  }

  function setAltTextInTray(newAltText) {
    fireEvent.change(screen.getByPlaceholderText(/(describe the icon)/i), {
      target: {value: `${newAltText}`},
    })
  }

  function changeIsDecorativeCheckbox() {
    fireEvent.click(screen.getByText(/decorative icon/i))
  }

  function clickDoneButton() {
    fireEvent.click(screen.getByText(/done/i))
  }

  function getIconAltTextFromEditor(targetEditor) {
    return targetEditor.$container
      .querySelector('img[data-inst-icon-maker-icon="true"]')
      .getAttribute('alt')
  }

  function getIconRoleFromEditor(targetEditor) {
    return targetEditor.$container
      .querySelector('img[data-inst-icon-maker-icon="true"]')
      .getAttribute('role')
  }

  let iconTrayController, editorForIcon, iconImage, editorForDecorative
  beforeEach(() => {
    ;({iconTrayController, editorForIcon, iconImage, editorForDecorative} = setup())
  })

  afterEach(() => {
    editorForIcon.uninitialize()
    editorForDecorative.uninitialize()
  })

  describe('#showTrayForEditor()', () => {
    it('opens the tray for icon options when the tray is not open', async () => {
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      await waitFor(() => expect(iconTrayController.isOpen).toBe(true))
    })

    it('uses the word "icon" instead of "image" in the tray', () => {
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      expect(screen.getByPlaceholderText(/describe the icon/i)).toBeInTheDocument()
      expect(screen.getByText(/decorative icon/i)).toBeInTheDocument()
    })

    it('opens the tray and uses the selected icon alt text from the editor when the tray is not open', () => {
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      const altTextInput = getAltTextFromTrayInput()
      expect(altTextInput).toHaveTextContent(iconImage.alt)
    })
  })

  describe('#hideTrayForEditor()', () => {
    it('closes the tray for the editor', async () => {
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      iconTrayController.hideTrayForEditor(editorForIcon)
      await waitFor(() => expect(iconTrayController.isOpen).toBe(false))
    })
  })

  describe('#_applyIconAltTextChanges', () => {
    it('uses the icon maker "apply" function', () => {
      const applyIconOptionsSpy = jest.spyOn(iconTrayController, '_applyIconAltTextChanges')
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      setAltTextInTray('and thats the fact jack')
      clickDoneButton()
      expect(applyIconOptionsSpy).toHaveBeenCalled()
    })

    it('updates the icon alt text', () => {
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      const newAltText = 'and thats the fact jack'
      setAltTextInTray(newAltText)
      clickDoneButton()
      expect(getIconAltTextFromEditor(editorForIcon)).toEqual(newAltText)
    })

    it('sets role="presentation" when the icon is marked as decorative', () => {
      iconTrayController.showTrayForEditor(editorForIcon, isIconMaker)
      changeIsDecorativeCheckbox() // checks "Is Decorative"
      clickDoneButton()
      expect(getIconRoleFromEditor(editorForIcon)).toEqual('presentation')
      expect(getIconAltTextFromEditor(editorForIcon)).toEqual('')
    })

    it('removes role="presentation" when the icon has the decorative option unset', () => {
      iconTrayController.showTrayForEditor(editorForDecorative, isIconMaker)
      changeIsDecorativeCheckbox() // unchecks "Is Decorative"
      const newAltText = 'groundhog day'
      setAltTextInTray(newAltText)
      clickDoneButton()
      expect(getIconRoleFromEditor(editorForDecorative)).toBeNull()
      expect(getIconAltTextFromEditor(editorForDecorative)).toEqual(newAltText)
    })
  })
})
