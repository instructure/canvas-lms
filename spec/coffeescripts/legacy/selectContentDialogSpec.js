/*
 * Copyright (C) 2014 - present Instructure, Inc.
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
import SelectContentDialog from '@canvas/select-content-dialog'

QUnit.module('SelectContentDialog: Dialog options', {
  setup() {
    sandbox.spy($.fn, 'dialog')
    $('#fixtures').html("<div id='select_context_content_dialog'></div>")
  },
  teardown() {
    $('.ui-dialog').remove()
    $('#fixtures').html('')
  },
})

test('opens a dialog with the width option', () => {
  const width = 500
  INST.selectContentDialog({width})
  equal($.fn.dialog.getCall(0).args[0].width, width)
})

test('opens a dialog with the height option', () => {
  const height = 100
  INST.selectContentDialog({height})
  equal($.fn.dialog.getCall(0).args[0].height, height)
})

test('opens a dialog with the dialog_title option', () => {
  const dialogTitle = 'To be, or not to be?'
  INST.selectContentDialog({dialog_title: dialogTitle})
  equal($.fn.dialog.getCall(0).args[0].title, dialogTitle)
})

QUnit.module('SelectContentDialog: deepLinkingListener', {
  setup() {
    $('#fixtures').html(`
      <div>
        <div id='select_context_content_dialog'></div>
        <div id='resource_selection_dialog'></div>
        <input type='text' id='external_tool_create_url' />
        <input type='text' id='external_tool_create_title' />
        <input type='text' id='external_tool_create_custom_params' />
        <input type='text' id='external_tool_create_assignment_id' />
        <input type='text' id='external_tool_create_iframe_width' />
        <input type='text' id='external_tool_create_iframe_height' />
        <div id='context_external_tools_select'>
          <span class='domain_message'"
        </div>
      </div>
    `)

    const $selectContextContentDialog = $('#select_context_content_dialog')
    const $resourceSelectionDialog = $('#resource_selection_dialog')
    const options = {
      autoOpen: false,
      modal: true,
    }

    $selectContextContentDialog.dialog(options).dialog('open')
    $resourceSelectionDialog.dialog(options).dialog('open')
  },
  teardown() {
    $('.ui-dialog').remove()
    $('#fixtures').html('')
  },
})

const customParams = {
  root_account_id: '$Canvas.rootAccount.id',
  referer: 'LTI test tool example',
}

const deepLinkingEvent = {
  data: {
    subject: 'LtiDeepLinkingResponse',
    content_items: [
      {
        type: 'ltiResourceLink',
        url: 'https://www.my-tool.com/launch-url',
        title: 'My Tool',
        new_tab: '0',
        custom: customParams,
        iframe: {
          width: 123,
          height: 456,
        },
      },
    ],
    ltiEndpoint: 'https://canvas.instructure.com/api/lti/deep_linking',
  },
}

const assignmentId = '42'
const deepLinkingEventWithAssignmentId = {
  data: {
    subject: 'LtiDeepLinkingResponse',
    content_items: [
      {
        type: 'ltiResourceLink',
        url: 'https://www.my-tool.com/launch-url',
        title: 'My Tool',
        new_tab: '0',
        assignment_id: assignmentId,
      },
    ],
    ltiEndpoint: 'https://canvas.instructure.com/api/lti/deep_linking',
  },
}

test('sets the tool url', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)
  const {url} = deepLinkingEvent.data.content_items[0]
  equal($('#external_tool_create_url').val(), url)
})

test('sets the tool title', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)
  const {title} = deepLinkingEvent.data.content_items[0]
  equal($('#external_tool_create_title').val(), title)
})

test('sets the tool custom params', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)

  equal($('#external_tool_create_custom_params').val(), JSON.stringify(customParams))
})

test('sets the content item assignment id if given', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEventWithAssignmentId)
  equal($('#external_tool_create_assignment_id').val(), assignmentId)
})

test('sets the iframe width', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)
  equal($('#external_tool_create_iframe_height').val(), 456)
})

test('sets the iframe height', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)
  equal($('#external_tool_create_iframe_width').val(), 123)
})

test('recover item data from context external tool item', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)

  const data = SelectContentDialog.extractContextExternalToolItemData()

  equal(data['item[type]'], 'context_external_tool')
  equal(data['item[id]'], 0)
  equal(data['item[new_tab]'], '0')
  equal(data['item[indent]'], undefined)
  equal(data['item[url]'], 'https://www.my-tool.com/launch-url')
  equal(data['item[title]'], 'My Tool')
  equal(data['item[custom_params]'], JSON.stringify(customParams))
  equal(data['item[iframe][width]'], 123)
  equal(data['item[iframe][height]'], 456)
})

test('recover assignment id from context external tool item data if given', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEventWithAssignmentId)

  const data = SelectContentDialog.extractContextExternalToolItemData()
  equal(data['item[assignment_id]'], assignmentId)
})

test('reset external tool fields', async () => {
  $('#external_tool_create_url').val('Sample')
  $('#external_tool_create_title').val('Sample')
  $('#external_tool_create_custom_params').val('Sample')
  $('#external_tool_create_assignment_id').val('Sample')
  $('#external_tool_create_iframe_width').val('Sample')
  $('#external_tool_create_iframe_height').val('Sample')

  equal($('#external_tool_create_url').val(), 'Sample')
  equal($('#external_tool_create_title').val(), 'Sample')
  equal($('#external_tool_create_custom_params').val(), 'Sample')
  equal($('#external_tool_create_assignment_id').val(), 'Sample')
  equal($('#external_tool_create_iframe_width').val(), 'Sample')
  equal($('#external_tool_create_iframe_height').val(), 'Sample')

  SelectContentDialog.resetExternalToolFields()

  equal($('#external_tool_create_url').val(), '')
  equal($('#external_tool_create_title').val(), '')
  equal($('#external_tool_create_custom_params').val(), '')
  equal($('#external_tool_create_assignment_id').val(), '')
  equal($('#external_tool_create_iframe_width').val(), '')
  equal($('#external_tool_create_iframe_height').val(), '')
})

test('close all dialogs when content items attribute is empty', async () => {
  const deepLinkingEvent = {
    data: {
      subject: 'LtiDeepLinkingResponse',
      content_items: [],
      ltiEndpoint: 'https://canvas.instructure.com/api/lti/deep_linking',
    },
  }

  await SelectContentDialog.deepLinkingListener(deepLinkingEvent)

  strictEqual($('#select_context_content_dialog').is(':visible'), false)
  strictEqual($('#resource_selection_dialog').is(':visible'), false)
})

test('close dialog when content item has assignment_id', async () => {
  await SelectContentDialog.deepLinkingListener(deepLinkingEventWithAssignmentId)

  strictEqual($('#select_context_content_dialog').is(':visible'), false)
  strictEqual($('#resource_selection_dialog').is(':visible'), false)
})
