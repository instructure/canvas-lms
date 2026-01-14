/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import $ from 'jquery'
import RichContentEditor from '../RichContentEditor'
import * as RceCommandShim from '@canvas/rce-command-shim'
import RCELoader from '../serviceRCELoader'

vi.mock('@canvas/rce-command-shim', () => ({
  send: vi.fn(),
}))

describe('RichContentEditor', () => {
  describe('ensureID', () => {
    it('gives the element an id when it is missing', () => {
      const $el = $('<div/>')
      RichContentEditor.ensureID($el)
      expect($el.attr('id')).toBeTruthy()
    })

    it('gives the element an id when it is blank', () => {
      const $el = $('<div id/>')
      RichContentEditor.ensureID($el)
      expect($el.attr('id')).toBeTruthy()
    })

    it("doesn't overwrite an existing id", () => {
      const $el = $('<div id="test"/>')
      RichContentEditor.ensureID($el)
      expect($el.attr('id')).toBe('test')
    })
  })

  describe('freshNode', () => {
    it('returns the given element if the id is missing', () => {
      const $el = $('<div/>')
      const $fresh = RichContentEditor.freshNode($el)
      expect($fresh).toBe($el)
    })
  })

  describe('remote module loading', () => {
    beforeEach(() => {
      vi.spyOn(RCELoader, 'preload').mockImplementation(() => {})
      window.ENV = {}
    })

    afterEach(() => {
      vi.restoreAllMocks()
      delete window.ENV
    })

    it('loads via RCELoader.preload when service enabled', () => {
      window.ENV.RICH_CONTENT_APP_HOST = 'app-host'
      RichContentEditor.preloadRemoteModule()
      expect(RCELoader.preload).toHaveBeenCalled()
    })
  })

  describe('loadNewEditor', () => {
    let $target

    beforeEach(() => {
      $target = $('<div/>')
      vi.spyOn(RCELoader, 'loadOnTarget').mockImplementation(() => Promise.resolve())
      vi.spyOn(RichContentEditor, 'freshNode').mockReturnValue($target)
    })

    afterEach(() => {
      vi.restoreAllMocks()
    })

    it('calls RCELoader.loadOnTarget', () => {
      const options = {}
      RichContentEditor.loadNewEditor($target, options)
      expect(RCELoader.loadOnTarget).toHaveBeenCalled()
    })
  })

  describe('commandShim handling', () => {
    let $target

    beforeEach(() => {
      $target = $('<div/>')
      vi.clearAllMocks()
    })

    it('passes command to RceCommandShim', () => {
      const $freshTarget = $($target)
      vi.spyOn(RichContentEditor, 'freshNode').mockReturnValue($freshTarget)

      RichContentEditor.callOnRCE($target, 'someCommand')
      expect(RceCommandShim.send).toHaveBeenCalled()
    })
  })
})
