/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import KeyboardShortcuts from 'compiled/views/editor/KeyboardShortcuts'

let view = null

QUnit.module('editor KeyboardShortcuts', {
  setup() {
    view = new KeyboardShortcuts()
    view.$dialog = {
      opened: false,
      dialog(cmd) {
        if (cmd === 'open') {
          this.opened = true
        }
      }
    }
    return view.bindEvents()
  },
  teardown() {
    return view.remove()
  }
})

test('ALT+F8 should open the helpmenu', () => {
  $(document).trigger('editorKeyUp', [
    {
      keyCode: 119,
      altKey: true
    }
  ])
  equal(view.$dialog.opened, true)
})

test('ALT+0 opens the helpmenu', () => {
  $(document).trigger('editorKeyUp', [
    {
      keyCode: 48,
      altKey: true
    }
  ])
  equal(view.$dialog.opened, true)
})

test('ALT+0 (numpad) does not open the helpmenu (we need that for unicode entry on windows)', () => {
  $(document).trigger('editorKeyUp', [
    {
      keyCode: 96,
      altKey: true
    }
  ])
  equal(view.$dialog.opened, false)
})

test('any of those help values without alt does nothing', () => {
  $(document).trigger('editorKeyUp', [
    {
      keyCode: 119,
      altKey: false
    }
  ])
  equal(view.$dialog.opened, false)
})
