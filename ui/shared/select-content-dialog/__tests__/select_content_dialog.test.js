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

import {
  Events,
  externalContentReadyHandler,
  deepLinkingResponseHandler,
  extractContextExternalToolItemData,
  resetExternalToolFields,
  selectContentDialog,
} from '../jquery/select_content_dialog'
import $ from 'jquery'
import 'jquery-migrate' // required

// The tests here, and the code they test, use jQuery's is(":visible") method. This is necessary to make them work as expected with jest.
// https://stackoverflow.com/questions/64136050/visible-selector-not-working-in-jquery-jest/
// I couldn't seem to get it working by stubbing getClientRects, so I just mocked the visible pseudo-selector.
function mockGetClientRects() {
  jest.spyOn($.expr.pseudos, 'visible').mockImplementation(function (el) {
    let node = el
    while (node) {
      if (node === document) {
        break
      }
      if (!node.style || node.style.display === 'none' || node.style.visibility === 'hidden') {
        return false
      }
      node = node.parentNode
    }
    return true
  })
}

let originalENV
let fixtures = null

beforeEach(() => {
  originalENV = {...window.ENV}
  document.body.innerHTML = `<div id="fixtures"></div>`
  fixtures = document.getElementById('fixtures')
  mockGetClientRects()
})

afterEach(() => {
  window.ENV = originalENV
  document.body.innerHTML = ``
  jest.restoreAllMocks()
})

describe('SelectContentDialog', () => {
  let clickEvent = {}
  let allowances

  beforeEach(() => {
    allowances = ['midi', 'media']
    window.ENV.LTI_LAUNCH_FRAME_ALLOWANCES = allowances

    fixtures.innerHTML = `<div id="context_external_tools_select"> \
<div class="tools"><div id="test-tool" class="tool resource_selection"></div></div></div>`
    const $l = $(document.getElementById('test-tool'))

    clickEvent = {
      originalEvent: MouseEvent,
      type: 'click',
      timeStamp: 1433863761376,
      jQuery17209791898143012077: true,
      preventDefault() {},
    }

    $l.data('tool', {name: 'mytool', placements: {resource_selection: {}}})
    jest.spyOn(window, 'confirm').mockImplementation(() => true)
  })

  afterEach(() => {
    $(window).off('beforeunload')
    clickEvent = {}
    $('#resource_selection_dialog').remove()
  })

  it('it creates a confirm alert before closing the modal', () => {
    const l = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind(l)(clickEvent)
    const $dialog = $('#resource_selection_dialog')
    $dialog.dialog('close')
    expect(window.confirm).toHaveBeenCalledTimes(1)
    expect(window.confirm).toHaveBeenCalledWith(
      expect.stringMatching(/Changes you made may not be saved/)
    )
  })

  it('sets the iframe allowances', function () {
    const l = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind(l)(clickEvent)
    const $dialog = $('#resource_selection_dialog')
    expect($dialog.find('#resource_selection_iframe').attr('allow')).toEqual(allowances.join('; '))
  })

  it("starts with focus on the 'x' button", function () {
    const l = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind(l)(clickEvent)
    expect(document.activeElement).toEqual(document.querySelector('.ui-dialog-titlebar-close'))
  })

  it('maintains the same size iframe after focusing and blurring the screen reader alerts', function () {
    const l = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind(l)(clickEvent)
    const $dialog = $('#resource_selection_dialog')
    const closeButton = document.querySelector('.ui-dialog-titlebar-close')
    const srAlert = document.querySelector('.before_external_content_info_alert')
    // Something seems to be setting width to 0 in the test, probably because
    // width and eheight are messed up. We can just set the css width/height
    // again here.
    // NOTE: may be fragile if we do stuff with 'width' and 'height' in the
    // future and don't use css('height') etc. to change the dimensions.
    const $iframe = $dialog.find('#resource_selection_iframe')
    $iframe.css('height', '800px')
    $iframe.css('width', '400px')
    srAlert.focus()
    closeButton.focus()
    srAlert.focus()
    closeButton.focus()
    expect($iframe.css('height')).toEqual('800px')
    expect($iframe.css('width')).toEqual('400px')
  })

  it('sets the iframe "data-lti-launch" attribute', function () {
    const l = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind(l)(clickEvent)
    const $dialog = $('#resource_selection_dialog')
    expect($dialog.find('#resource_selection_iframe').attr('data-lti-launch')).toEqual('true')
    expect($dialog.find('#resource_selection_iframe').attr('title')).toEqual('mytool')
  })

  it('close dialog when 1.1 content items are empty', () => {
    window.ENV.FEATURES = {
      lti_overwrite_user_url_input_select_content_dialog: true,
    }
    const l = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind(l)(clickEvent)
    const $dialog = $('#resource_selection_dialog')
    expect($dialog.is(':visible')).toBe(true)
    const externalContentReadyEvent = {
      data: {
        subject: 'externalContentReady',
        contentItems: [
          {
            '@type': 'LtiLinkItem',
            url: 'http://canvas.instructure.com/test',
            placementAdvice: {presentationDocumentTarget: ''},
          },
        ],
      },
    }
    externalContentReadyHandler(externalContentReadyEvent, l)
    expect($dialog.is(':visible')).toBe(false)
    expect(window.confirm).toHaveBeenCalledTimes(0)
  })

  it('close dialog when 1.3 content items are empty', async () => {
    const $testTool = document.getElementById('test-tool')
    Events.onContextExternalToolSelect.bind($testTool)(clickEvent)

    const $resourceSelectionDialog = $('#resource_selection_dialog')

    expect($resourceSelectionDialog.is(':visible')).toBe(true)

    const deepLinkingEvent = {
      data: {
        subject: 'LtiDeepLinkingResponse',
        content_items: [],
        ltiEndpoint: 'https://canvas.instructure.com/api/lti/deep_linking',
      },
    }

    deepLinkingResponseHandler(deepLinkingEvent)

    expect($resourceSelectionDialog.is(':visible')).toBe(false)
    expect(window.confirm).toHaveBeenCalledTimes(0)
  })
})

describe('SelectContentDialog: Dialog options', () => {
  beforeEach(() => {
    jest.spyOn($.fn, 'dialog')
    $('#fixtures').html("<div id='select_context_content_dialog'></div>")
  })

  afterEach(() => {
    $('.ui-dialog').remove()
    $('#fixtures').html('')
    jest.restoreAllMocks()
  })

  it('opens a dialog with the width option', () => {
    const width = 500
    selectContentDialog({width})
    expect($.fn.dialog).toHaveBeenCalledWith(expect.objectContaining({width}))
  })

  it('opens a dialog with the height option', () => {
    const height = 100
    selectContentDialog({height})
    expect($.fn.dialog).toHaveBeenCalledWith(expect.objectContaining({height}))
  })

  it('opens a dialog with the dialog_title option', () => {
    const dialogTitle = 'To be, or not to be?'
    selectContentDialog({dialog_title: dialogTitle})
    expect($.fn.dialog).toHaveBeenCalledWith(expect.objectContaining({title: dialogTitle}))
  })
})

describe('SelectContentDialog: deepLinkingResponseHandler', () => {
  beforeEach(() => {
    window.ENV.FEATURES = {
      lti_overwrite_user_url_input_select_content_dialog: true,
    }
    $('#fixtures').html(`
        <div>
          <div id='select_context_content_dialog'>
            <div id='resource_selection_dialog'></div>
            <input type='text' id='external_tool_create_url' />
            <div class='select_item_name'>
              <input type='text' id='external_tool_create_title' />
            </div>
            <input type='text' id='external_tool_create_custom_params' />
            <input type='text' id='external_tool_create_line_item' />
            <input type='text' id='external_tool_create_description' />
            <input type='text' id='external_tool_create_available' />
            <input type='text' id='external_tool_create_submission' />
            <input type='text' id='external_tool_create_assignment_id' />
            <input type='text' id='external_tool_create_iframe_width' />
            <input type='text' id='external_tool_create_iframe_height' />
            <input type='checkbox' id='external_tool_create_new_tab' />
            <input type='text' id='external_tool_create_preserve_existing_assignment_name' />
            <div id='context_external_tools_select'>
              <span class='domain_message' />
              <div class='tools'>
                <div class='tool selected'></div>
              </div>
            </div>
          </div>
        </div>
      `)

    const $selectContextContentDialog = $('#select_context_content_dialog')
    const $resourceSelectionDialog = $('#resource_selection_dialog')
    const options = {
      autoOpen: false,
      modal: true,
    }

    const tool = $('#context_external_tools_select .tools .tool.selected')
    tool.data('tool', {
      name: 'mytool',
      url: 'https://www.my-tool.com/tool-url',
      definition_id: 0,
      placements: {resource_selection: {}},
    })

    $selectContextContentDialog.dialog(options).dialog('open')
    $resourceSelectionDialog.dialog(options).dialog('open')
    jest.spyOn(window, 'confirm').mockImplementation(() => true)
  })

  afterEach(() => {
    $('.ui-dialog').remove()
    $('#fixtures').html('')
  })

  const customParams = {
    root_account_id: '$Canvas.rootAccount.id',
    referer: 'LTI test tool example',
  }

  const contentItem = {
    type: 'ltiResourceLink',
    url: 'https://www.my-tool.com/launch-url',
    new_tab: '0',
    custom: customParams,
    iframe: {
      width: 123,
      height: 456,
    },
    lineItem: {scoreMaximum: 4},
    available: {startDateTime: '2023-04-12T00:00:00.000Z', endDateTime: '2023-04-22T00:00:00.000Z'},
    submission: {
      startDateTime: '2023-04-12T00:00:00.000Z',
      endDateTime: '2023-04-21T00:00:00.000Z',
    },
    text: 'Description text',
    'https://canvas.instructure.com/lti/preserveExistingAssignmentName': true,
  }
  const makeDeepLinkingEvent = (additionalContentItemFields = {}, omitFields = []) => {
    const omittedContentItem = Object.fromEntries(
      Object.entries(contentItem).filter(([key]) => !omitFields.includes(key))
    )
    return {
      data: {
        subject: 'LtiDeepLinkingResponse',
        content_items: [{...omittedContentItem, ...additionalContentItemFields}],
        ltiEndpoint: 'https://canvas.instructure.com/api/lti/deep_linking',
      },
    }
  }
  const deepLinkingEventWithoutTitle = makeDeepLinkingEvent()
  const deepLinkingEvent = makeDeepLinkingEvent({title: 'My Tool'})

  const assignmentId = '42'
  const deepLinkingEventWithAssignmentId = makeDeepLinkingEvent({
    title: 'My Tool',
    assignment_id: assignmentId,
  })

  it('sets the tool url', async () => {
    deepLinkingResponseHandler(deepLinkingEvent)
    const {url} = deepLinkingEvent.data.content_items[0]
    expect($('#external_tool_create_url').val()).toEqual(url)
  })

  it('sets the tool url without the optional title', async () => {
    deepLinkingResponseHandler(deepLinkingEventWithoutTitle)
    const {url} = deepLinkingEvent.data.content_items[0]
    expect($('#external_tool_create_url').val()).toEqual(url)
  })

  it('sets the tool url from the tool if the url isnt included', async () => {
    deepLinkingResponseHandler(
      makeDeepLinkingEvent(
        {
          title: 'My Tool',
        },
        'url'
      )
    )
    expect($('#external_tool_create_url').val()).toEqual('https://www.my-tool.com/tool-url')
  })

  it('Overwrites the tool url if the lti_overwrite_user_url_input_select_content_dialog feature flag is set', async () => {
    $('#external_tool_create_url').val('foo')
    deepLinkingResponseHandler(
      makeDeepLinkingEvent(
        {
          title: 'My Tool',
        },
        'url'
      )
    )
    expect($('#external_tool_create_url').val()).toEqual('https://www.my-tool.com/tool-url')
  })

  it("Doesn't overwrite the tool url if the lti_overwrite_user_url_input_select_content_dialog feature flag is not set", async () => {
    window.ENV.FEATURES.lti_overwrite_user_url_input_select_content_dialog = false
    $('#external_tool_create_url').val('foo')
    deepLinkingResponseHandler(
      makeDeepLinkingEvent({
        title: 'My Tool',
      })
    )
    expect($('#external_tool_create_url').val()).toEqual('foo')
  })

  it('sets the tool title', async () => {
    deepLinkingResponseHandler(deepLinkingEvent)
    const {title} = deepLinkingEvent.data.content_items[0]
    expect($('#external_tool_create_title').val()).toEqual(title)
  })

  it('sets the tool title to the tool name if no content_item title is given', async () => {
    deepLinkingResponseHandler(makeDeepLinkingEvent())
    expect($('#external_tool_create_title').val()).toEqual('mytool')
  })

  it('does not set the tool title to the tool name if no content_item title is given with no_name_input set', async () => {
    selectContentDialog({
      no_name_input: true,
    })
    deepLinkingResponseHandler(makeDeepLinkingEvent())
    expect($('#external_tool_create_title').val()).toEqual('')
  })

  it('sets the tool custom params', async () => {
    deepLinkingResponseHandler(deepLinkingEvent)

    expect($('#external_tool_create_custom_params').val()).toEqual(JSON.stringify(customParams))
  })

  it('sets the content item assignment id if given', async () => {
    deepLinkingResponseHandler(deepLinkingEventWithAssignmentId)
    expect($('#external_tool_create_assignment_id').val()).toEqual(assignmentId)
  })

  it('sets the iframe width', async () => {
    deepLinkingResponseHandler(deepLinkingEvent)
    expect($('#external_tool_create_iframe_height').val()).toEqual('456')
  })

  it('sets the iframe height', async () => {
    deepLinkingResponseHandler(deepLinkingEvent)
    expect($('#external_tool_create_iframe_width').val()).toEqual('123')
  })

  it('recover item data from context external tool item', async () => {
    deepLinkingResponseHandler(deepLinkingEvent)

    const data = extractContextExternalToolItemData()

    expect(data['item[type]']).toEqual('context_external_tool')
    expect(data['item[new_tab]']).toEqual('0')
    expect(data['item[indent]']).toBeUndefined()
    expect(data['item[url]']).toEqual('https://www.my-tool.com/launch-url')
    expect(data['item[title]']).toEqual('My Tool')
    expect(data['item[custom_params]']).toEqual(JSON.stringify(customParams))
    expect(data['item[iframe][width]']).toEqual('123')
    expect(data['item[iframe][height]']).toEqual('456')
    expect(data['item[line_item]']).toEqual('{"scoreMaximum":4}')
    expect(data['item[available]']).toEqual(
      '{"startDateTime":"2023-04-12T00:00:00.000Z","endDateTime":"2023-04-22T00:00:00.000Z"}'
    )
    expect(data['item[submission]']).toEqual(
      '{"startDateTime":"2023-04-12T00:00:00.000Z","endDateTime":"2023-04-21T00:00:00.000Z"}'
    )
    expect(data['item[description]']).toEqual('Description text')
    expect(data['item[preserveExistingAssignmentName]']).toEqual('true')
  })

  it('recover assignment id from context external tool item data if given', async () => {
    deepLinkingResponseHandler(deepLinkingEventWithAssignmentId)

    const data = extractContextExternalToolItemData()
    expect(data['item[assignment_id]']).toEqual(assignmentId)
  })

  it('checks the new tab checkbox if content item window.targetName is _blank', async () => {
    deepLinkingResponseHandler(makeDeepLinkingEvent({window: {targetName: '_blank'}}))

    const data = extractContextExternalToolItemData()
    expect(data['item[new_tab]']).toEqual('1')
  })

  it('reset external tool fields', async () => {
    $('#external_tool_create_url').val('Sample')
    $('#external_tool_create_title').val('Sample')
    $('#external_tool_create_custom_params').val('Sample')
    $('#external_tool_create_assignment_id').val('Sample')
    $('#external_tool_create_iframe_width').val('Sample')
    $('#external_tool_create_iframe_height').val('Sample')

    expect($('#external_tool_create_url').val()).toEqual('Sample')
    expect($('#external_tool_create_custom_params').val()).toEqual('Sample')
    expect($('#external_tool_create_assignment_id').val()).toEqual('Sample')
    expect($('#external_tool_create_iframe_width').val()).toEqual('Sample')
    expect($('#external_tool_create_iframe_height').val()).toEqual('Sample')
    expect($('#external_tool_create_title').val()).toEqual('Sample')

    resetExternalToolFields()

    expect($('#external_tool_create_url').val()).toEqual('')
    expect($('#external_tool_create_title').val()).toEqual('')
    expect($('#external_tool_create_custom_params').val()).toEqual('')
    expect($('#external_tool_create_assignment_id').val()).toEqual('')
    expect($('#external_tool_create_iframe_width').val()).toEqual('')
    expect($('#external_tool_create_iframe_height').val()).toEqual('')
  })

  it('close all dialogs when content items attribute is empty', async () => {
    const deepLinkingEvent = {
      data: {
        subject: 'LtiDeepLinkingResponse',
        content_items: [],
        ltiEndpoint: 'https://canvas.instructure.com/api/lti/deep_linking',
      },
    }

    deepLinkingResponseHandler(deepLinkingEvent)

    expect($('#select_context_content_dialog').is(':visible')).toBe(false)
    expect(window.confirm).toHaveBeenCalledTimes(0)
  })
})
