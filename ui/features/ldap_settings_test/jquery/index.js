/* eslint-disable @typescript-eslint/no-shadow */
/*
 * Copyright (C) 2013 - present Instructure, Inc.
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
import h from '@instructure/html-escape'
import authenticity_token from '@canvas/authenticity-token'
import '@canvas/jquery/jquery.ajaxJSON'
import 'jqueryui/dialog'

const I18n = useI18nScope('accounts')

function testLDAP() {
  clearTestLDAP()
  $('#test_ldap_dialog').dialog({
    title: I18n.t('test_ldap_dialog_title', 'Test LDAP Settings'),
    width: 600,
    modal: true,
    zIndex: 1000,
  })
  ENV.LDAP_TESTS[0].js_function()
}
function clearTestLDAP() {
  $.each(ENV.LDAP_TESTS, (i, test) => {
    $('#ldap_' + test.test_type + '_result').html('')
    $('#ldap_' + test.test_type + '_help .server_error').remove()
    $('#ldap_' + test.test_type + '_help').hide()
  })
  $('#ldap_login_result').html('')
  $('#ldap_login_form').hide()
}
$.each(ENV.LDAP_TESTS, (i, test) => {
  test.js_function = function () {
    $('#ldap_' + test.test_type + '_result').html("<img src='/images/ajax-loader.gif'/>")
    $.getJSON(test.url, data => {
      let success = true
      let server_error = ''
      $.each(data, (i, config) => {
        if (!config['ldap_' + test.test_type + '_test']) {
          success = false
          if (config.errors[0] && config.errors[0]['ldap_' + test.test_type + '_test']) {
            server_error = config.errors[0]['ldap_' + test.test_type + '_test']
          }
        }
      })
      if (success) {
        $('#ldap_' + test.test_type + '_result').html(
          "<h4 style='color:green'>" + h(I18n.t('test_ldap_result_ok', 'OK')) + '</h4>'
        )
        if (ENV.LDAP_TESTS[i + 1]) {
          // proceed to the next test
          ENV.LDAP_TESTS[i + 1].js_function()
        } else {
          // show login test tool
          $('#ldap_login_form').show('blind')
        }
      } else {
        $('#ldap_' + test.test_type + '_result').html(
          "<h4 style='color:red'>" + h(I18n.t('test_ldap_result_failed', 'Failed')) + '</h4>'
        )
        $('#ldap_' + test.test_type + '_help').show()
        const $server_error = $('<p></p>')
          .addClass('server_error')
          .css('color', 'red')
          .text(server_error)
        $('#ldap_' + test.test_type + '_help').append($server_error)

        $.each(ENV.LDAP_TESTS.slice(i + 1), (i, next_test) => {
          $('#ldap_' + next_test.test_type + '_result').html(
            "<h4 style='color:red'>" + h(I18n.t('test_ldap_result_canceled', 'Canceled')) + '</h4>'
          )
        })
        $('#ldap_login_result').html(
          "<h4 style='color:red'>" + h(I18n.t('test_ldap_result_canceled', 'Canceled')) + '</h4>'
        )
      }
    })
  }
})
function testLDAPLogin() {
  $('#ldap_test_login').prop('disabled', true).prop('value', I18n.t('testing', 'Testing...'))
  $('#ldap_login_result').html("<img src='/images/ajax-loader.gif'/>")
  const username = $('#ldap_test_login_user').val()
  const password = $('#ldap_test_login_pass').val()
  $.post(
    ENV.LOGIN_TEST_URL,
    {username, password, authenticity_token: authenticity_token()},
    data => {
      let success = true
      let message = ''
      $.each(data, (i, config) => {
        if (!config.ldap_login_test) {
          success = false
        }
        if (config.errors) {
          $.each(config.errors, (i, m) => {
            $.each(m, (err, msg) => {
              message += msg
            })
          })
        }
      })
      if (success) {
        $('#ldap_login_help_error').hide()
        $('#ldap_login_result').html(
          "<h4 style='color:green'>" + h(I18n.t('test_ldap_result_ok', 'OK')) + '</h4>'
        )
        $('#ldap_test_login')
          .prop('disabled', false)
          .prop('value', I18n.t('test_login', 'Test Login'))
      } else {
        $('#ldap_login_result').html(
          "<h4 style='color:red'>" + h(I18n.t('test_ldap_result_failed', 'Failed')) + '</h4>'
        )
        $('#ldap_login_help').show()
        $('#ldap_test_login')
          .prop('disabled', false)
          .prop('value', I18n.t('retry_login', 'Retry Login'))
        $('#ldap_login_help_error').text(message)
      }
    }
  )
}

$(document).ready(() => {
  $('.test_ldap_link').click(event => {
    event.preventDefault()
    // kick off our test
    testLDAP()
  })
  $('.ldap_test_close').click(event => {
    event.preventDefault()
    $('#test_ldap_dialog').dialog('close')
  })
  $('#ldap_test_login_form').submit(event => {
    event.preventDefault()
    testLDAPLogin()
  })
})
