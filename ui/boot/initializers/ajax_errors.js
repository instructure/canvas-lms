/*
 * Copyright (C) 2011 - present Instructure, Inc.
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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.ajaxJSON' // ajaxJSON, defaultAjaxError
import '@canvas/rails-flash-notifications' // flashError

if (!('INST' in window)) window.INST = {}

const I18n = useI18nScope('ajax_errors')

INST.errorCount = 0
window.onerror = function (_msg, _url, _line, _column, _errorObj) {
  INST.errorCount += 1
}

// puts the little red box when something bad happens in ajax.
$(document).ready(function () {
  $('#instructure_ajax_error_result').defaultAjaxError(function (
    event,
    request,
    settings,
    error,
    debugOnly
  ) {
    if (error === 'abort') return
    let status = '0'
    let text = I18n.t('no_text', 'No text')
    try {
      status = request.status
      text = request.responseText
    } catch (e) {
      // no-op
    }

    const $obj = $(this)
    const ajaxErrorFlash = function (message, _xhr) {
      const i = $obj[0]
      if (!i) {
        return
      }
      const d =
        i.contentDocument ||
        (i.contentWindow && i.contentWindow.document) ||
        window.frames[$obj.attr('id')].document
      const $body = $(d).find('body')
      $body.html(
        $('<h1 />').text(
          I18n.t('error_heading', 'Ajax Error: %{status_code}', {status_code: status})
        )
      )
      $body.append(htmlEscape(text))
      $('#instructure_ajax_error_box').hide()
      message = htmlEscape(message)
      if (debugOnly) {
        message += "<br/><span style='font-size: 0.7em;'>(Development Only)</span>"
      }
      if (debugOnly || INST.environment !== 'production') {
        message +=
          "<br/><a href='#' class='last_error_details_link'>" +
          htmlEscape(I18n.t('links.details', 'details...')) +
          '</a>'
      }
      $.flashError({html: message})
    }

    $.ajaxJSON(
      window.location.protocol +
        '//' +
        window.location.host +
        '/simple_response.json?rnd=' +
        Math.round(Math.random() * 9999999),
      'GET',
      {},
      () => {
        if ($.ajaxJSON.isUnauthenticated(request)) {
          let message = htmlEscape(
            I18n.t(
              'errors.logged_out',
              'You are not currently logged in, possibly due to a long period of inactivity.'
            )
          )
          message +=
            "<br/><a href='/login' id='inactivity_login_link' target='_new'>" +
            htmlEscape(I18n.t('links.login', 'Login')) +
            '</a>'
          $.flashError({html: message}, 30000)
          $('#inactivity_login_link').focus()
          // eslint-disable-next-line eqeqeq
        } else if (status != 409) {
          ajaxErrorFlash(
            I18n.t('errors.unhandled', "Oops! The last request didn't work out."),
            request
          )
        }
      },
      () => {
        ajaxErrorFlash(
          I18n.t(
            'errors.connection_lost',
            "Connection to %{host} was lost.  Please make sure you're connected to the Internet and try again.",
            {host: window.location.host}
          ),
          request
        )
      },
      {skipDefaultError: true}
    )
    window.ajaxErrorFlash = ajaxErrorFlash
    let data = $.ajaxJSON.findRequest(request)
    data = data || {}
    if (data.data) {
      data.params = ''
      for (const name in data.data) {
        data.params += '&' + name + '=' + data.data[name]
      }
    }
    let username = ''
    try {
      username = $('#identity .user_name').text()
    } catch (e) {
      // no-op
    }
    if (INST.ajaxErrorURL) {
      const txt =
        '&Msg=' +
        escape(text) +
        '&StatusCode=' +
        escape(status) +
        '&URL=' +
        escape(data.url || 'unknown') +
        '&Page=' +
        escape(window.location.href) +
        '&Method=' +
        escape(data.submit_type || 'unknown') +
        '&UserName=' +
        escape(username) +
        '&Platform=' +
        escape(navigator.platform) +
        '&UserAgent=' +
        escape(navigator.userAgent) +
        '&Params=' +
        escape(data.params || 'unknown')
      $('body').append(
        "<img style='position: absolute; left: -1000px; top: 0;' src='" +
          htmlEscape(INST.ajaxErrorURL + txt.substring(0, 2000)) +
          "' />"
      )
    }
  })
  $(document).on('click', '.last_error_details_link', event => {
    event.preventDefault()
    event.stopPropagation()
    $('#instructure_ajax_error_box').show()
  })
  $('.close_instructure_ajax_error_box_link').click(event => {
    event.preventDefault()
    $('#instructure_ajax_error_box').hide()
  })
})
