/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import * as RceCommandShim from '../RceCommandShim'
import fixtures from '@canvas/test-utils/fixtures'

let remoteEditor = null

describe('RceCommandShim - send', () => {
  let $target

  beforeEach(() => {
    fixtures.setup()
    $target = fixtures.create('<textarea />')
    remoteEditor = {
      hidden: false,
      isHidden: () => remoteEditor.hidden,
      call: jest.fn().mockReturnValue('methodResult'),
    }
  })

  afterEach(() => {
    fixtures.teardown()
  })

  it("just forwards through target's remoteEditor if set", () => {
    $target.data('remoteEditor', remoteEditor)
    expect(RceCommandShim.send($target, 'methodName', 'methodArgument')).toBe('methodResult')
    expect(remoteEditor.call).toHaveBeenCalledWith('methodName', 'methodArgument')
  })

  it('returns false for exists? if neither remoteEditor nor rich_text are set (e.g. load failed)', () => {
    $target.data('remoteEditor', null)
    expect(RceCommandShim.send($target, 'exists?')).toBe(false)
  })

  it("returns target's val() for get_code if neither remoteEditor nor rich_text are set (e.g. load failed)", () => {
    $target.data('remoteEditor', null)
    $target.val('current raw value')
    expect(RceCommandShim.send($target, 'get_code')).toBe('current raw value')
  })

  it('returns target val for get_code if editor is hidden', () => {
    remoteEditor.hidden = true
    $target.data('remoteEditor', remoteEditor)
    $target.val('current HTML value')
    expect(RceCommandShim.send($target, 'get_code')).toBe('current HTML value')
  })

  it("uses the editor's get_code if visible", () => {
    remoteEditor.hidden = false
    $target.data('remoteEditor', remoteEditor)
    expect(RceCommandShim.send($target, 'get_code')).toBe('methodResult')
  })

  it('transforms create_link call for remote editor', () => {
    const url = 'http://someurl'
    const classes = 'one two'
    const previewAlt = 'alt text for preview'
    $target.data('remoteEditor', remoteEditor)
    RceCommandShim.send($target, 'create_link', {
      url,
      classes,
      dataAttributes: {'preview-alt': previewAlt},
    })
    expect(remoteEditor.call).toHaveBeenCalledWith('insertLink', {
      url,
      classes,
      href: url,
      class: classes,
      'data-preview-alt': previewAlt,
      dataAttributes: {'preview-alt': previewAlt},
    })
  })
})

describe('RceCommandShim - focus', () => {
  let $target

  beforeEach(() => {
    fixtures.setup()
    $target = fixtures.create('<textarea />')
    const editor = {
      focus: jest.fn(),
    }
    const tinymce = {
      get: () => editor,
    }
    RceCommandShim.setTinymce(tinymce)
  })

  afterEach(() => {
    fixtures.teardown()
  })

  it("just forwards through target's remoteEditor if set", () => {
    remoteEditor = {focus: jest.fn()}
    $target.data('remoteEditor', remoteEditor)
    RceCommandShim.focus($target)
    expect(remoteEditor.focus).toHaveBeenCalled()
  })
})

describe('RceCommandShim - destroy', () => {
  let $target

  beforeEach(() => {
    fixtures.setup()
    $target = fixtures.create('<textarea />')
  })

  afterEach(() => {
    fixtures.teardown()
  })

  it("forwards through target's remoteEditor if set", () => {
    remoteEditor = {destroy: jest.fn()}
    $target.data('remoteEditor', remoteEditor)
    RceCommandShim.destroy($target)
    expect(remoteEditor.destroy).toHaveBeenCalled()
  })

  it("clears target's remoteEditor afterwards if set", () => {
    remoteEditor = {destroy: jest.fn()}
    $target.data('remoteEditor', remoteEditor)
    RceCommandShim.destroy($target)
    expect($target.data('remoteEditor')).toBeNull()
  })

  it('does not throw an exception if remoteEditor is not set', () => {
    const consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation(() => {})
    $target.data('remoteEditor', null)
    expect(() => {
      RceCommandShim.destroy($target)
    }).not.toThrow()
    consoleWarnSpy.mockRestore()
  })
})
