//
// Copyright (C) 2014 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'

import I18n from 'i18n!external_content.success'
import 'jquery.ajaxJSON'
import 'jquery.instructure_misc_helpers'
import '../../jquery.rails_flash_notifications'

function dataReady(data, service_id) {
  const e = $.Event('externalContentReady')
  e.contentItems = data
  e.service_id = service_id
  parentWindow.$(parentWindow).trigger('externalContentReady', e)

  if (parentWindow[callback] && parentWindow[callback].ready) {
    parentWindow[callback].ready(data)
    setTimeout(() => {
      if (callback === 'external_tool_dialog') {
        $("#dialog_message").text(I18n.t("popup_success", "Success! This popup should close on its own..."));
      } else {
        $("#dialog_message").text('');
      }
    }, 1000);
  } else {
    $('#dialog_message').text(
      I18n.t(
        'content_failure',
        'Content retrieval failed, please try again or notify your system administrator of the error.'
      )
    )
  }
}

const {lti_response_messages} = ENV
const {service_id} = ENV
const data = ENV.retrieved_data
var callback = ENV.service
var parentWindow = window.parent
while (parentWindow && parentWindow.parent !== parentWindow && !parentWindow[callback]) {
  parentWindow = parentWindow.parent
}

if (lti_response_messages.lti_errormsg) {
  parentWindow.$.flashError(lti_response_messages.lti_errormsg)
}
if (lti_response_messages.lti_msg) {
  parentWindow.$.flashMessage(lti_response_messages.lti_msg)
}

if (ENV.oembed) {
  const url = $.replaceTags(
    $.replaceTags(
      $('#oembed_retrieve_url').attr('href'),
      'endpoint',
      encodeURIComponent(ENV.oembed.endpoint)
    ),
    'url',
    encodeURIComponent(ENV.oembed.url)
  )
  $.ajaxJSON(
    url,
    'GET',
    {},
    data => dataReady(data),
    () =>
      $('#dialog_message').text(
        I18n.t(
          'oembed_failure',
          'Content retrieval failed, please try again or notify your system administrator of the error.'
        )
      )
  )
} else {
  dataReady(data, service_id)
}
