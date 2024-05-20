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
import React from 'react'
import ReactDOM from 'react-dom'
import {Alert} from '@instructure/ui-alerts'
import replaceTags from '@canvas/util/replaceTags'
import {postMessageExternalContentReady} from '@canvas/external-tools/messages'

const I18n = useI18nScope('external_content.success')

const ExternalContentSuccess = {}

const {lti_response_messages, service_id, retrieved_data: data, service} = ENV
const parentWindow = window.parent || window.opener

ExternalContentSuccess.dataReady = function (contentItems, service_id) {
  postMessageExternalContentReady(parentWindow, {contentItems, service_id, service})

  setTimeout(() => {
    $('#dialog_message').text(
      I18n.t('popup_success', 'Success! This popup should close on its own...')
    )
  }, 1000)
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
      ltiEndpoint: ENV.lti_endpoint,
    },
    ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN
  )
}

ExternalContentSuccess.processLtiMessages = async (messages, target) => {
  const errorMessage = messages?.lti_errormsg
  const message = messages?.lti_msg

  if (errorMessage || message) {
    const wrapper = document.createElement('div')
    wrapper.setAttribute('id', 'lti_messages_wrapper')
    target.parentNode.insertBefore(wrapper, target)

    await new Promise(resolve => {
      ReactDOM.render(
        <>
          {[
            [errorMessage, true],
            [message, false],
          ]
            .filter(([msg, _]) => msg !== undefined)
            .map(([msg, isError], index) => {
              return (
                <Alert
                  // eslint-disable-next-line react/no-array-index-key
                  key={index}
                  variant={isError ? 'error' : 'info'}
                  renderCloseButtonLabel="Close"
                  onDismiss={() => resolve()}
                  timeout={5000}
                >
                  <span id={isError ? 'lti_error_message' : 'lti_message'}>{msg}</span>
                </Alert>
              )
            })}
        </>,
        wrapper
      )
    })
    ReactDOM.unmountComponentAtNode(wrapper)
  }
}

ExternalContentSuccess.start = async function () {
  await this.processLtiMessages(lti_response_messages, document.querySelector('.ic-app'))

  if (ENV.oembed) {
    const url = replaceTags(
      replaceTags(
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
  } else {
    ExternalContentSuccess.dataReady(data, service_id)
    ExternalContentSuccess.a2DataReady(data)
  }
}

$(document).ready(() => {
  ExternalContentSuccess.start()
})

export default ExternalContentSuccess
