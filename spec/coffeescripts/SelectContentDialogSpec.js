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

import SelectContentDialog from 'select_content_dialog'
import $ from 'jquery'
import fakeENV from 'helpers/fakeENV'

let fixtures = null
let clickEvent = {}

QUnit.module('SelectContentDialog', {
  setup() {
    this.allowances = ['midi', 'media']
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = this.allowances
    fixtures = document.getElementById('fixtures')
    fixtures.innerHTML = `<div id="context_external_tools_select"> \
<div class="tools"><div id="test-tool" class="tool resource_selection"></div></div></div>`
    const $l = $(document.getElementById('test-tool'))
    clickEvent = {
      originalEvent: MouseEvent,
      type: 'click',
      timeStamp: 1433863761376,
      jQuery17209791898143012077: true,
      preventDefault() {}
    }
    $l.data('tool', {placements: {resource_selection: {}}})
    sandbox.stub(window, 'confirm').returns(true)
  },
  teardown() {
    ENV.LTI_LAUNCH_FRAME_ALLOWANCES = undefined
    $(window).off('beforeunload')
    clickEvent = {}
    fixtures.innerHTML = ''
    $('#resource_selection_dialog')
      .parent()
      .remove()
  }
})

test('it creates a confirm alert before closing the modal', function() {
  const l = document.getElementById('test-tool')
  SelectContentDialog.Events.onContextExternalToolSelect.bind(l)(clickEvent)
  const $dialog = $('#resource_selection_dialog')
  $dialog.dialog('close')
  strictEqual(window.confirm.callCount, 1)
})

test('sets the iframe allowances', function() {
  const l = document.getElementById('test-tool')
  SelectContentDialog.Events.onContextExternalToolSelect.bind(l)(clickEvent)
  const $dialog = $('#resource_selection_dialog')
  equal($dialog.find('#resource_selection_iframe').attr('allow'), this.allowances.join('; '))
})

test('it removes the confirm alert if a selection is passed back', function() {
  const l = document.getElementById('test-tool')
  SelectContentDialog.Events.onContextExternalToolSelect.bind(l)(clickEvent)
  const $dialog = $('#resource_selection_dialog')
  const selectionEvent = $.Event('selection', {
    contentItems: [
      {
        '@type': 'LtiLinkItem',
        url: 'http://canvas.instructure.com/test',
        placementAdvice: {presentationDocumentTarget: ''}
      }
    ]
  })
  $dialog.trigger(selectionEvent)
  strictEqual(window.confirm.callCount, 0)
})
