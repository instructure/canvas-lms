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

import {initExternalToolsLocalPlugin} from '../plugin'
import {RceToolWrapper, storeMruToolIds} from '../RceToolWrapper'
import {createDeepMockProxy} from '../../../../util/__tests__/deepMockProxy'

import {ExternalToolsEditor, externalToolsEnvFor, RceLtiToolInfo} from '../ExternalToolsEnv'
import RCEWrapper from '../../../RCEWrapper'

describe('initExternalToolsLocalPlugin', () => {
  const editorButtons: RceLtiToolInfo[] = [
    {id: 'button_id', name: 'some tool'},
    {id: 'fav_id', favorite: true, name: 'fav tool', canvas_icon_class: 'fav-tool'},
  ]

  const editor = createDeepMockProxy<ExternalToolsEditor>()
  const rceWrapper = createDeepMockProxy<RCEWrapper>(
    {},
    {
      props: {
        ltiTools: editorButtons,
        trayProps: {
          contextType: 'course',
          contextId: '1',
        },
      },
    }
  )

  beforeAll(() => {
    jest
      .spyOn(RCEWrapper, 'getByEditor')
      .mockImplementation(e => (e === editor ? rceWrapper : null))
  })

  beforeEach(() => {
    window.localStorage?.clear()
    editor.mockClear()
  })

  it('adds MRU menu button to the toolbar', async () => {
    storeMruToolIds(['button_id'])

    initExternalToolsLocalPlugin(editor)

    expect(editor.ui.registry.addMenuButton).toHaveBeenCalledWith('lti_mru_button', {
      tooltip: 'Apps',
      icon: 'lti',
      fetch: expect.any(Function),
      onSetup: expect.any(Function),
    })

    const button = editor.ui.registry.addMenuButton.mock.calls[0][1]

    const mruItems: Parameters<Parameters<typeof button.fetch>[0]>[0] = await new Promise(resolve =>
      button.fetch(resolve)
    )

    expect(mruItems).toMatchObject([
      {
        text: 'some tool',
      },
      {
        text: 'View All',
      },
    ])
  })

  it('adds favorite tool button to toolbar', () => {
    initExternalToolsLocalPlugin(editor)
    const favButtonConfig = new RceToolWrapper(externalToolsEnvFor(editor), editorButtons[1], [])

    expect(editor.ui.registry.addButton).toHaveBeenCalledWith(
      'instructure_external_button_fav_id',
      {
        type: 'button',
        onAction: expect.any(Function),
        tooltip: favButtonConfig.title,
        icon: favButtonConfig.iconId,
      }
    )
  })

  it('adds external tools item to the menu bar', () => {
    initExternalToolsLocalPlugin(editor)

    expect(editor.ui.registry.addNestedMenuItem).toHaveBeenCalledWith('lti_tools_menuitem', {
      text: 'Apps',
      icon: 'lti',
      getSubmenuItems: expect.any(Function),
    })
  })

  it('updates the menu with new MRU tools', () => {
    initExternalToolsLocalPlugin(editor)

    const menuItemSpec = editor.ui.registry.addNestedMenuItem.mock.calls[0][1]

    expect(menuItemSpec.getSubmenuItems()).toHaveLength(1)

    storeMruToolIds(['button_id'])

    expect(menuItemSpec.getSubmenuItems()).toHaveLength(2)
  })

  it('updates the toolbar with new MRU tools', () => {
    initExternalToolsLocalPlugin(editor)

    const menuItemSpec = editor.ui.registry.addNestedMenuItem.mock.calls[0][1]

    expect(menuItemSpec.getSubmenuItems()).toHaveLength(1)

    storeMruToolIds(['button_id'])

    expect(menuItemSpec.getSubmenuItems()).toHaveLength(2)
  })
})
