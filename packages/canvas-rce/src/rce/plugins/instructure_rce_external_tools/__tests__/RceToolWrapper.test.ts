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

import {addMruToolId, RceToolWrapper} from '../RceToolWrapper'
import {createDeepMockProxy} from '../../../../util/__tests__/deepMockProxy'
import {ExternalToolsEditor, externalToolsEnvFor} from '../ExternalToolsEnv'
import {IconLtiLine, IconLtiSolid} from '@instructure/ui-icons/es/svg'

describe('RceExternalToolHelper', () => {
  describe('buttonConfig', () => {
    let fakeEditor = createDeepMockProxy<ExternalToolsEditor>()

    beforeEach(() => {
      fakeEditor = createDeepMockProxy<ExternalToolsEditor>()
    })

    it('transforms button data for tinymce', () => {
      const button = {
        id: 'b0',
        name: 'some tool',
        description: 'this is a cool tool',
        favorite: true,
        icon_url: '/path/to/cool_icon',
      } as const

      const result = new RceToolWrapper(externalToolsEnvFor(fakeEditor), button, [])

      expect(fakeEditor.ui.registry.addIcon).toHaveBeenCalled()

      expect(result).toEqual(
        expect.objectContaining({
          id: button.id,
          description: button.description,
          title: button.name,
          image: expect.stringContaining(button.icon_url),
        }),
      )
    })

    describe('instui icon resolution', () => {
      it('handles icons prefixed with icon-', () => {
        const result = new RceToolWrapper(
          externalToolsEnvFor(fakeEditor),
          {
            id: 'b0',
            name: 'some tool',
            description: 'this is a cool tool',
            favorite: true,
            canvas_icon_class: 'icon-lti',
          },
          [],
        )
        expect(fakeEditor.ui.registry.addIcon).toHaveBeenCalledWith('lti_tool_b0', IconLtiLine.src)
        expect(result.iconId).toEqual('lti_tool_b0')
      })

      it('handles icons prefixed with icon_', () => {
        const result = new RceToolWrapper(
          externalToolsEnvFor(fakeEditor),
          {
            id: 'b0',
            name: 'some tool',
            description: 'this is a cool tool',
            favorite: true,
            canvas_icon_class: 'icon_lti',
          },
          [],
        )
        expect(fakeEditor.ui.registry.addIcon).toHaveBeenCalledWith('lti_tool_b0', IconLtiLine.src)
        expect(result.iconId).toEqual('lti_tool_b0')
      })

      it('handles icons without prefixes', () => {
        const result = new RceToolWrapper(
          externalToolsEnvFor(fakeEditor),
          {
            id: 'b0',
            name: 'some tool',
            description: 'this is a cool tool',
            favorite: true,
            canvas_icon_class: 'lti',
          },
          [],
        )
        expect(fakeEditor.ui.registry.addIcon).toHaveBeenCalledWith('lti_tool_b0', IconLtiLine.src)
        expect(result.iconId).toEqual('lti_tool_b0')
      })
    })

    it('uses a default icon when nothing else is provided', () => {
      const button = {
        id: 'b0',
        name: 'some tool',
        description: 'this is a cool tool',
        favorite: true,
        canvas_icon_class: 'invalid-icon',
      }

      const result = new RceToolWrapper(externalToolsEnvFor(fakeEditor), button, [])
      expect(fakeEditor.ui.registry.addIcon).toHaveBeenCalledWith('lti_tool_b0', IconLtiSolid.src)
      expect(result.iconId).toEqual('lti_tool_b0')
    })

    it('uses button icon_url if there is no icon_class', () => {
      const button = {
        id: 'b0',
        name: 'some tool',
        description: 'this is a cool tool',
        favorite: true,
        icon_url: 'path/to/icon',
      }

      const result = new RceToolWrapper(externalToolsEnvFor(fakeEditor), button, [])

      expect(result).toEqual(
        expect.objectContaining({
          id: button.id,
          description: button.description,
          title: button.name,
          image: button.icon_url,
        }),
      )

      expect(result).toEqual(
        expect.not.objectContaining({
          icon: expect.anything(),
        }),
      )
    })

    it('makes a config as expected', function () {
      const config = new RceToolWrapper(
        externalToolsEnvFor(fakeEditor),
        {
          name: 'SomeName',
          id: '_SomeId',
        },
        [],
      )
      expect(config.title).toEqual('SomeName')
    })

    it('uses image if provided, overriding icon class', function () {
      const config = new RceToolWrapper(
        externalToolsEnvFor(fakeEditor),
        {
          name: 'SomeName',
          id: '_SomeId',
          icon_url: 'example.com',
          canvas_icon_class: 'some_icon',
        },
        [],
      )
      expect(config.iconId).toEqual('lti_tool__SomeId')
      expect(config.image).toEqual('example.com')
    })

    it('handles number and string ids', function () {
      expect(
        RceToolWrapper.forEditorEnv(
          externalToolsEnvFor(fakeEditor),
          [
            {
              name: 'Tool',
              id: 12,
              icon_url: 'example.com',
            },
          ],
          ['12'],
        ).find(it => it.isMruTool)?.id,
      ).toBe('12')

      expect(
        RceToolWrapper.forEditorEnv(
          externalToolsEnvFor(fakeEditor),
          [
            {
              name: 'Tool',
              id: '12',
              icon_url: 'example.com',
            },
          ],
          ['12'],
        ).find(it => it.isMruTool)?.id,
      ).toBe('12')
    })
  })

  describe('updateMRUList', () => {
    const env = externalToolsEnvFor(null)

    it('deals with malformed saved data', () => {
      window.localStorage.setItem('ltimru', 'not what is expected')
      expect(() => {
        addMruToolId('1', env)
      }).not.toThrow()
    })

    it('creates the MRU list', () => {
      addMruToolId('1', env)

      expect(window.localStorage.getItem('ltimru')).toEqual('["1"]')
    })

    it('adds to the MRU list', () => {
      window.localStorage.setItem('ltimru', '[1]')
      addMruToolId('2', env)

      expect(JSON.parse(window.localStorage.getItem('ltimru')!)).toEqual(['2', '1'])
    })

    it('does not add a duplicate to the MRU list', () => {
      window.localStorage.setItem('ltimru', '[2, 1]')
      addMruToolId('1', env)

      expect(JSON.parse(window.localStorage.getItem('ltimru')!)).toEqual([2, 1])
    })

    it('limits the MRU list to the max length', () => {
      window.localStorage.setItem('ltimru', '[1,2,3,4,5]')
      addMruToolId('6', env)

      expect(JSON.parse(window.localStorage.getItem('ltimru')!)).toEqual(['6', '1', '2', '3', '4'])
    })

    it('corrects bad data in local storage', () => {
      window.localStorage.setItem('ltimru', 'this is not valid JSON')
      addMruToolId('1', env)
      expect(window.localStorage.getItem('ltimru')).toEqual('["1"]')
    })

    it('copes with localStorage failure updating mru list', () => {
      // Note the mocking of Storage.prototype instead of localStorage. This works around a jsdom issue.
      // See: https://stackoverflow.com/a/54157998/966104
      const setItemMock = jest.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
        throw new Error('something bad')
      })

      try {
        window.localStorage.clear()
        addMruToolId('1', env)
        expect(window.localStorage.getItem('ltimru')).toEqual(null)
      } finally {
        setItemMock.mockRestore()
      }
    })
  })
})
