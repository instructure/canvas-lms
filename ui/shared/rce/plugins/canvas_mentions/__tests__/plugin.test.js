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
import {
  onKeyDown,
  onKeyUp,
  onSetContent,
  onMouseDown
} from '../events'

jest.mock('@instructure/canvas-rce/es/rce/tinyRCE', () => ({
  create: jest.fn(),
  PluginManager: {
    add: jest.fn(),
  }
}))

afterEach(() => {
  jest.restoreAllMocks()
})

describe('plugin', () => {
  it('has a name', () => {
    expect(plugin.name).toEqual('canvas_mentions')
  })

  it('registers the plugin', () => {
    expect(tinymce.PluginManager.add).toHaveBeenCalledWith('canvas_mentions', expect.anything())
  })
})


describe('CanvasMentionsPlugin', () => {
  const onMethod = jest.fn()
  const editor = { on : onMethod }

  it('register onInputChange for "input" event', () => {
    plugin.CanvasMentionsPlugin(editor)
    expect(onMethod).toHaveBeenCalledWith('input', plugin.onInputChange)
  })

  it('register onSetContent for "SetContent" event', () => {
    plugin.CanvasMentionsPlugin(editor)
    expect(onMethod).toHaveBeenCalledWith('SetContent', onSetContent)
  })

  it('register onKeyDown for "KeyDown" event', () => {
    plugin.CanvasMentionsPlugin(editor)
    expect(onMethod).toHaveBeenCalledWith('KeyDown', onKeyDown)
  })

  it('register onKeyUp for "KeyUp" event', () => {
    plugin.CanvasMentionsPlugin(editor)
    expect(onMethod).toHaveBeenCalledWith('KeyUp', onKeyUp)
  })

  it('register onMouseDown for "MouseDown" event', () => {
    plugin.CanvasMentionsPlugin(editor)
    expect(onMethod).toHaveBeenCalledWith('MouseDown', onMouseDown)
  })

  it('register onMentionsExit for "Remove" event', () => {
    plugin.CanvasMentionsPlugin(editor)
    expect(onMethod).toHaveBeenCalledWith('Remove', expect.any(Function))
  })
})
