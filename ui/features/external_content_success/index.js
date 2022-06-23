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

import {useScope as useI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('external_content.success')

const ExternalContentSuccess = {}

const {lti_response_messages} = ENV
const {service_id} = ENV
const data = ENV.retrieved_data
const callback = ENV.service
let parentWindow = window.parent || window.opener

ExternalContentSuccess.getIFrameSrc = function () {
  let src = parentWindow.$('[data-cid="Modal"]').find('iframe').attr('src')

  if (src === undefined) {
    src = parentWindow.$('[data-cid="Tray"]').find('iframe').attr('src')
  }

  return src
}

ExternalContentSuccess.getLaunchType = function () {
  const src = ExternalContentSuccess.getIFrameSrc()

  if (src === undefined) {
    return undefined
  }

  const params = new URLSearchParams(src.split('?')[1])
  return params.get('launch_type')
}

ExternalContentSuccess.dataReady = function (data, service_id) {
  const e = $.Event('externalContentReady')
  e.contentItems = data
  e.service_id = service_id

  parentWindow.$(parentWindow).trigger('externalContentReady', e)

  if (parentWindow[callback] && parentWindow[callback].ready) {
    parentWindow[callback].ready(data)
    setTimeout(() => {
      if (callback === 'external_tool_dialog') {
        $('#dialog_message').text(
          I18n.t('popup_success', 'Success! This popup should close on its own...')
        )
      } else {
        $('#dialog_message').text('')
      }
    }, 1000)
  } else {
    $('#dialog_message').text(
      I18n.t(
        'content_failure',
        'Content retrieval failed, please try again or notify your system administrator of the error.'
      )
    )
  }
}

// Handles lti 1.0 responses for Assignments 2 which expects a
// vanilla JS event from LTI tools in the following form.
ExternalContentSuccess.a2DataReady = function (data) {
  parentWindow.postMessage(
    {
      subject: 'A2ExternalContentReady',
      content_items: data,
      msg: ENV.message,
      log: ENV.log,
      errormsg: ENV.error_message,
      errorlog: ENV.error_log,
      ltiEndpoint: ENV.lti_endpoint
    },
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
  )
}

ExternalContentSuccess.start = function () {
  while (parentWindow && parentWindow.parent !== parentWindow && !parentWindow[callback]) {
    parentWindow = parentWindow.parent
  }

  if (parentWindow.$ === undefined) {
    parentWindow.$ = $
  }

  if (lti_response_messages && lti_response_messages.lti_errormsg) {
    parentWindow.$.flashError(lti_response_messages.lti_errormsg)
  }
  if (lti_response_messages && lti_response_messages.lti_msg) {
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
      data => ExternalContentSuccess.dataReady(data),
      () =>
        $('#dialog_message').text(
          I18n.t(
            'oembed_failure',
            'Content retrieval failed, please try again or notify your system administrator of the error.'
          )
        )
    )
  } else if (ExternalContentSuccess.getLaunchType() === 'assignment_index_menu') {
    parentWindow.location.reload()
  } else if (parentWindow.$(parentWindow).data('events')?.externalContentReady) {
    ExternalContentSuccess.dataReady(data, service_id)
  } else {
    ExternalContentSuccess.a2DataReady(data)
  }
}

$(document).ready(() => {
  ExternalContentSuccess.start()
})

export default ExternalContentSuccess
