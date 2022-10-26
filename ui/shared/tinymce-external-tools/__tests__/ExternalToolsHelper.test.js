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

import ExternalToolsHelper from '@canvas/tinymce-external-tools/ExternalToolsHelper'
import $ from 'jquery'

describe('ExternalToolsHelper', () => {
  describe('buttonConfig', () => {
    let fakeEditor
    beforeAll(() => {
      fakeEditor = {
        execCommand: () => {},
      }
    })

    it('transforms button data for tiymce', () => {
      const button = {
        id: 'b0',
        name: 'some tool',
        description: 'this is a cool tool',
        favorite: true,
        icon_url: '/path/to/cool_icon',
      }

      const result = ExternalToolsHelper.buttonConfig(button, fakeEditor)

      expect(result).toEqual(
        expect.objectContaining({
          id: button.id,
          description: button.description,
          title: button.name,
          image: expect.stringContaining(button.icon_url),
        })
      )
    })

    it('uses button icon_url if there is no icon_class', () => {
      const button = {
        id: 'b0',
        name: 'some tool',
        description: 'this is a cool tool',
        favorite: true,
        icon_url: 'path/to/icon',
      }

      const result = ExternalToolsHelper.buttonConfig(button, fakeEditor)

      expect(result).toEqual(
        expect.objectContaining({
          id: button.id,
          description: button.description,
          title: button.name,
          image: button.icon_url,
        })
      )
      expect(result).toEqual(
        expect.not.objectContaining({
          icon: expect.anything(),
        })
      )
    })
  })

  describe('showHideButtons', () => {
    let fakeEditor, button, menuButton
    beforeAll(() => {
      const edContainer = document.createElement('div')
      document.body.appendChild(edContainer)

      fakeEditor = {
        $,
        editorContainer: edContainer,
      }
    })
    beforeEach(() => {
      button = document.createElement('div')
      button.setAttribute('class', 'tox-tbtn')
      button.setAttribute('aria-label', 'Apps')
      button.setAttribute('style', 'display: flex')
      button.innerHTML = 'Apps'
      fakeEditor.editorContainer.appendChild(button)

      menuButton = document.createElement('div')
      menuButton.setAttribute('class', 'tox-tbtn--select')
      menuButton.setAttribute('aria-label', 'Apps')
      menuButton.setAttribute('style', 'display: flex')
      menuButton.innerHTML = 'Apps'
      fakeEditor.editorContainer.appendChild(menuButton)
    })

    afterEach(() => {
      fakeEditor.editorContainer.innerHTML = ''
    })

    it('shows MRU button if there is an MRU', () => {
      window.localStorage.setItem('ltimru', 'anything')
      ExternalToolsHelper.showHideButtons(fakeEditor)

      expect(menuButton.getAttribute('aria-hidden')).toEqual('false')
      expect(menuButton.style.display).toEqual('flex')
    })
  })

  describe('updateMRUList', () => {
    it('deals with malformed saved data', () => {
      window.localStorage.setItem('ltimru', 'not what is expected')
      expect(() => {
        ExternalToolsHelper.updateMRUList(1)
      }).not.toThrow()
    })

    it('creates the MRU list', () => {
      ExternalToolsHelper.updateMRUList(1)

      expect(window.localStorage.getItem('ltimru')).toEqual('[1]')
    })

    it('adds to the MRU list', () => {
      window.localStorage.setItem('ltimru', '[1]')
      ExternalToolsHelper.updateMRUList(2)

      expect(JSON.parse(window.localStorage.getItem('ltimru'))).toEqual([2, 1])
    })

    it('does not add a duplicate to the MRU list', () => {
      window.localStorage.setItem('ltimru', '[2, 1]')
      ExternalToolsHelper.updateMRUList(1)

      expect(JSON.parse(window.localStorage.getItem('ltimru'))).toEqual([2, 1])
    })

    it('limits the MRU list to the max length', () => {
      window.localStorage.setItem('ltimru', '[1,2,3,4,5]')
      ExternalToolsHelper.updateMRUList(6)

      expect(JSON.parse(window.localStorage.getItem('ltimru'))).toEqual([6, 1, 2, 3, 4])
    })
  })
})
