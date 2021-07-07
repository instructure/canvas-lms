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

import tinymce from '@instructure/canvas-rce/es/rce/tinyRCE'
import * as plugin from '../plugin'
import TestEditor from './TestEditor'

let mockAnchorOffset = 2
const mockAnchorWholeText = ''
const mockAnchorNode = {wholeText: mockAnchorWholeText}

jest.mock('@instructure/canvas-rce/es/rce/tinyRCE', () => ({
  create: jest.fn(),
  PluginManager: {
    add: jest.fn()
  },
  plugins: {
    CanvasMentionsPlugin: {}
  },
  activeEditor: {
    selection: {
      getSel: () => ({
        anchorOffset: mockAnchorOffset,
        anchorNode: mockAnchorNode
      })
    }
  }
}))

describe('plugin', () => {
  it('has a name', () => {
    expect(plugin.name).toEqual('canvas_mentions')
  })

  it('creates the plugin', () => {
    expect(tinymce.create).toHaveBeenCalledWith(
      'tinymce.plugins.CanvasMentionsPlugin',
      expect.anything()
    )
  })

  it('registers the plugin', () => {
    expect(tinymce.PluginManager.add).toHaveBeenCalledWith('canvas_mentions', expect.anything())
  })
})

describe('on input', () => {
  let editor

  beforeEach(() => {
    editor = new TestEditor()
    plugin.pluginDefinition.init(editor)
  })
})

describe('pluginDefinition', () => {
  let editor

  beforeEach(() => {
    editor = new TestEditor()
    plugin.pluginDefinition.init(editor)
  })

  describe('onInput', () => {
    let logSpy

    beforeEach(() => {
      logSpy = jest.spyOn(console, 'log')
    })

    afterEach(() => {
      logSpy.mockRestore()
    })

    describe('when no mention is triggered', () => {
      it('does not render the mentions component', () => {
        editor.trigger('input')
        expect(logSpy).not.toHaveBeenCalledWith('Mount the mentions component!')
      })
    })

    describe('when an "inline" mention is triggered', () => {
      beforeEach(() => {
        mockAnchorNode.wholeText = ' @'
      })

      it('renders the mentions component', () => {
        editor.trigger('input')
        expect(logSpy).toHaveBeenCalledWith('Mount the mentions component!')
      })
    })

    describe('when a "starting" mention is triggered', () => {
      beforeEach(() => {
        mockAnchorOffset = 1
        mockAnchorNode.wholeText = '@'
      })

      it('renders the mentions component', () => {
        editor.trigger('input')
        expect(logSpy).toHaveBeenCalledWith('Mount the mentions component!')
      })
    })
  })
})
