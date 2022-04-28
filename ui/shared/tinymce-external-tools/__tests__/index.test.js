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

import ExternalToolsPlugin from '@canvas/tinymce-external-tools'
import ExternalToolsHelper from '@canvas/tinymce-external-tools/ExternalToolsHelper'

describe('initializeExternalTools', () => {
  let fakeEditor
  beforeEach(() => {
    global.INST = {
      editorButtons: [
        {id: 'button_id'},
        {id: 'fav_id', favorite: true, name: 'fav tool', canvas_icon_class: 'fav-tool'}
      ]
    }

    ENV = {
      context_asset_string: 'course_1'
    }

    fakeEditor = {
      id: '1',
      focus: jest.fn(),
      getContent() {},
      selection: {
        getContent() {}
      },
      addCommand: jest.fn(),
      ui: {
        registry: {
          addButton: jest.fn(),
          addMenuButton: jest.fn(),
          addIcon: jest.fn(),
          addNestedMenuItem: jest.fn()
        }
      }
    }
  })

  it('adds MRU menu button to the toolbar', () => {
    ExternalToolsPlugin.init(fakeEditor, 'some.fake.url', INST)

    expect(fakeEditor.ui.registry.addMenuButton).toHaveBeenCalledWith('lti_mru_button', {
      tooltip: 'Apps',
      icon: 'lti',
      fetch: expect.any(Function),
      onSetup: expect.any(Function)
    })
  })

  it('adds favorite tool button to toolbar', () => {
    ExternalToolsPlugin.init(fakeEditor, 'some.fake.url', INST)
    const favButtonConfig = ExternalToolsHelper.buttonConfig(INST.editorButtons[1])

    expect(fakeEditor.ui.registry.addButton).toHaveBeenCalledWith(
      'instructure_external_button_fav_id',
      {
        onAction: expect.any(Function),
        tooltip: favButtonConfig.title,
        icon: favButtonConfig.icon,
        title: favButtonConfig.title
      }
    )
  })

  it('adds external tools item to the menu bar', () => {
    ExternalToolsPlugin.init(fakeEditor, 'some.fake.url', INST)

    expect(fakeEditor.ui.registry.addNestedMenuItem).toHaveBeenCalledWith('lti_tools_menuitem', {
      text: 'Apps',
      icon: 'lti',
      getSubmenuItems: expect.any(Function)
    })
  })

  it('adds the command to open each tool', () => {
    ExternalToolsPlugin.init(fakeEditor, 'some.fake.url', INST)

    expect(fakeEditor.addCommand).toHaveBeenCalledWith(
      `instructureExternalButton${INST.editorButtons[0].id}`,
      expect.any(Function)
    )
    expect(fakeEditor.addCommand).toHaveBeenCalledWith(
      `instructureExternalButton${INST.editorButtons[1].id}`,
      expect.any(Function)
    )
  })
})
