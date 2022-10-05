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

import ExternalToolsPlugin from '@canvas/tinymce-external-tools'
import $ from 'jquery'
import 'jqueryui/dialog'

const setUp = function () {
  const INST = {}
  INST.editorButtons = [{id: 'button_id'}]
  this.fakeEditor = {
    addCommand: sinon.spy(),
    addButton: sinon.spy(),
    getContent() {},
    selection: {
      getContent() {},
    },
    ui: {
      registry: {
        addButton: sinon.spy(),
        addMenuButton: sinon.spy(),
        addIcon: sinon.spy(),
        addNestedMenuItem: sinon.spy(),
      },
    },
  }
  this.INST = INST
}

QUnit.module('initializeExternalTools', {
  setup() {
    return setUp.call(this)
  },
  teardown() {
    return $(window).off('beforeunload')
  },
})

test('adds MRU menu button to the toolbar', function () {
  ExternalToolsPlugin.init(this.fakeEditor, undefined, this.INST)
  ok(this.fakeEditor.ui.registry.addMenuButton.calledWith('lti_mru_button'))
})

test('adds favorite buttons to the toolbar', function () {
  this.INST.editorButtons[0].favorite = true
  ExternalToolsPlugin.init(this.fakeEditor, undefined, this.INST)
  ok(this.fakeEditor.ui.registry.addButton.calledWith('instructure_external_button_button_id'))
})

test("creates the tool's icon", function () {
  this.INST.editorButtons[0].favorite = true
  this.INST.editorButtons[0].icon_url = 'tool_image'
  ExternalToolsPlugin.init(this.fakeEditor, undefined, this.INST)
  ok(this.fakeEditor.ui.registry.addIcon.calledWith('lti_tool_button_id'))
})

test('adds Apps to the Tools menubar menu', function () {
  ExternalToolsPlugin.init(this.fakeEditor, undefined, this.INST)
  ok(this.fakeEditor.ui.registry.addNestedMenuItem.calledWith('lti_tools_menuitem'))
})
