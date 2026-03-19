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

import {useScope as createI18nScope} from '@canvas/i18n'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/rails-flash-notifications'
import React from 'react'
import {render} from '@canvas/react'
import {Alert} from '@instructure/ui-alerts'
import replaceTags from '@canvas/util/replaceTags'
import {
  postMessageExternalContentReady,
  type Lti1p1ContentItem,
  type Service,
} from '@canvas/external-tools/messages'
import ready from '@instructure/ready'

const I18n = createI18nScope('external_content.success')

interface LtiResponseMessages {
  lti_errormsg?: string
  lti_msg?: string
}

interface ExternalContentSuccessModule {
  dataReady: (contentItems: Lti1p1ContentItem[], service_id: string | number) => void
  a2DataReady: (data: unknown) => void
  processLtiMessages: (
    messages: LtiResponseMessages | undefined,
    target: Element | null,
  ) => Promise<void>
  start: () => Promise<void>
}

const ExternalContentSuccess: ExternalContentSuccessModule = {
  dataReady(contentItems: Lti1p1ContentItem[], service_id: string | number) {
    // @ts-expect-error - Canvas ENV global not typed
    const {service}: {service: Service} = ENV
    const parentWindow = window.parent || window.opener

    postMessageExternalContentReady(parentWindow, {contentItems, service_id, service})

    setTimeout(() => {
      $('#dialog_message').text(
        I18n.t('popup_success', 'Success! This popup should close on its own...'),
      )
    }, 1000)
  },

  // Handles lti 1.0 responses for Assignments 2 which expects a
  // vanilla JS event from LTI tools in the following form.
  a2DataReady(data: unknown) {
    const parentWindow = window.parent || window.opener
    parentWindow.postMessage(
      {
        subject: 'A2ExternalContentReady',
        content_items: data,
        // @ts-expect-error - Canvas ENV global not typed
        msg: ENV.message,
        // @ts-expect-error - Canvas ENV global not typed
        log: ENV.log,
        // @ts-expect-error - Canvas ENV global not typed
        errormsg: ENV.error_message,
        // @ts-expect-error - Canvas ENV global not typed
        errorlog: ENV.error_log,
        // @ts-expect-error - Canvas ENV global not typed
        ltiEndpoint: ENV.lti_endpoint,
      },
      ENV.DEEP_LINKING_POST_MESSAGE_ORIGIN,
    )
  },

  async processLtiMessages(
    messages: LtiResponseMessages | undefined,
    target: Element | null,
  ): Promise<void> {
    const errorMessage = messages?.lti_errormsg
    const message = messages?.lti_msg

    if ((errorMessage || message) && target?.parentNode) {
      const wrapper = document.createElement('div')
      wrapper.setAttribute('id', 'lti_messages_wrapper')
      target.parentNode.insertBefore(wrapper, target)

      let root: ReturnType<typeof render> | undefined
      await new Promise<void>(resolve => {
        root = render(
          <>
            {[[errorMessage, true] as const, [message, false] as const]
              .filter(([msg]) => msg !== undefined)
              .map(([msg, isError], index) => {
                return (
                  <Alert
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
          wrapper,
        )
      })
      root?.unmount()
    }
  },

  async start(): Promise<void> {
    // @ts-expect-error - Canvas ENV global not typed
    const {lti_response_messages, service_id, retrieved_data: data} = ENV

    await this.processLtiMessages(lti_response_messages, document.querySelector('.ic-app'))

    // @ts-expect-error - Canvas ENV global not typed
    if (ENV.oembed) {
      const url = replaceTags(
        replaceTags(
          $('#oembed_retrieve_url').attr('href') ?? '',
          'endpoint',
          // @ts-expect-error - Canvas ENV global not typed
          encodeURIComponent(ENV.oembed.endpoint),
        ),
        'url',
        // @ts-expect-error - Canvas ENV global not typed
        encodeURIComponent(ENV.oembed.url),
      )
      $.ajaxJSON(
        url,
        'GET',
        {},
        (responseData: Lti1p1ContentItem[]) => ExternalContentSuccess.dataReady(responseData, ''),
        () =>
          $('#dialog_message').text(
            I18n.t(
              'oembed_failure',
              'Content retrieval failed, please try again or notify your system administrator of the error.',
            ),
          ),
      )
    } else {
      ExternalContentSuccess.dataReady(data, service_id)
      ExternalContentSuccess.a2DataReady(data)
    }
  },
}

ready(() => {
  ExternalContentSuccess.start()
})

export default ExternalContentSuccess
