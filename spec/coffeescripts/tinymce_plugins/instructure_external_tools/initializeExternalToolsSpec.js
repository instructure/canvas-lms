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

import ExternalToolsPlugin from 'tinymce_plugins/instructure_external_tools/initializeExternalTools'
import $ from 'jquery'
import 'jqueryui/dialog'

const setUp = function(maxButtons) {
  const INST = {}
  INST.editorButtons = [{id: 'button_id'}]
  INST.maxVisibleEditorButtons = maxButtons
  this.commandSpy = sinon.spy()
  this.buttonSpy = sinon.spy()
  this.fakeEditor = {
    addCommand: this.commandSpy,
    addButton: this.buttonSpy,
    getContent() {},
    selection: {
      getContent() {}
    }
  }
  this.INST = INST
}

QUnit.module('initializeExternalTools: with 2 max maxVisibleEditorButtons', {
  setup() {
    return setUp.call(this, 2)
  },
  teardown() {
    return $(window).off('beforeunload')
  }
})

test('adds button directly to toolbar', function() {
  const initResult = ExternalToolsPlugin.init(this.fakeEditor, 'some.fake.url', this.INST)
  equal(initResult, null)
  ok(this.buttonSpy.calledWith('instructure_external_button_button_id'))
  ok(this.commandSpy.calledWith('instructureExternalButtonbutton_id'))
})

QUnit.module('initializeExternalTools: with 0 max maxVisibleEditorButtons', {
  setup() {
    return setUp.call(this, 0)
  },
  teardown() {}
})

test('adds button to clumped buttons', function() {
  const initResult = ExternalToolsPlugin.init(this.fakeEditor, 'some.fake.url', this.INST)
  equal(initResult, null)
  ok(this.buttonSpy.calledWith('instructure_external_button_clump'))
  ok(this.commandSpy.notCalled)
})

QUnit.module('buttonSelected', {
  setup() {
    const fixtures = document.getElementById('fixtures')
    fixtures.innerHTML =
      '<a href="http://example.com" id="context_external_tool_resource_selection_url"></a>'
    setUp.call(this, 0)
    this.dialogCancelHandler = ExternalToolsPlugin.dialogCancelHandler
  },
  teardown() {
    $(window).off('beforeunload')
    fixtures.innerHTML = ''
    ExternalToolsPlugin.dialogCancelHandler = this.dialogCancelHandler
  }
})

test('it attaches the confirm unload handler', function() {
  ExternalToolsPlugin.dialogCancelHandler = sinon.spy()
  const $dialog = ExternalToolsPlugin.buttonSelected(this.buttonSpy, this.fakeEditor)
  $dialog.dialog('close')
  ok(ExternalToolsPlugin.dialogCancelHandler.called)
})

test('it removes the confirm unload handler on externalContentReady event', function() {
  ExternalToolsPlugin.dialogCancelHandler = sinon.spy()
  const $dialog = ExternalToolsPlugin.buttonSelected(this.buttonSpy, this.fakeEditor)
  $(window).trigger('externalContentReady', {
    contentItems: [
      {
        '@type': 'LtiLinkItem',
        url: 'http://canvas.instructure.com/test',
        placementAdvice: {presentationDocumentTarget: ''}
      }
    ]
  })
  ok(ExternalToolsPlugin.dialogCancelHandler.notCalled)
})

test('it removes the externalContentReady handler on close', function() {
  const externalContentReadySpy = sinon.spy()
  ExternalToolsPlugin.dialogCancelHandler = function() {}
  const $dialog = ExternalToolsPlugin.buttonSelected(this.buttonSpy, this.fakeEditor)
  $(window).bind('externalContentReady', externalContentReadySpy)
  $dialog.dialog('close')
  $(window).trigger('externalContentReady', {
    contentItems: [
      {
        '@type': 'LtiLinkItem',
        url: 'http://canvas.instructure.com/test',
        placementAdvice: {presentationDocumentTarget: ''}
      }
    ]
  })
  ok(externalContentReadySpy.notCalled)
})
