//
// Copyright (C) 2012 - present Instructure, Inc.
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

import I18n from 'i18n!developer_keys'
import $ from 'jquery'
import developer_key from 'jst/developer_key'
import developerKeyFormTemplate from 'jst/developer_key_form'
import preventDefault from './fn/preventDefault'
import 'jquery.ajaxJSON'
import 'jquery.instructure_date_and_time'
import 'jqueryui/dialog'

let page = 0

function buildKey (key) {
  key.icon_image_url = key.icon_url || '/images/blank.png'
  if (!key.name) key.name = I18n.t('unnamed_tool', 'Unnamed Tool')

  if (!key.user_name) key.user_name = I18n.t('no_user', 'No User')

  key.created = $.datetimeString(key.created_at)
  key.last_auth = $.datetimeString(key.last_auth_at)
  key.last_access = $.datetimeString(key.last_access_at)
  key.inactive = key.workflow_state === 'inactive'
  const $key = $(developer_key(key))
  return $key.data('key', key)
}

function buildForm (key = {}, $orig) {

  key._formAction = !key.id ? accountEndpoint() : rawEndpoint()

  const $form = $(developerKeyFormTemplate(key))
  $form.formSubmit({
    beforeSubmit () {
      $('#edit_dialog button.submit').text(I18n.t('button.saving', 'Saving Key...'))
    },
    disableWhileLoading: true,
    success (key) {
      $('#edit_dialog').dialog('close')
      const $key = buildKey(key)
      if ($orig) {
        $orig.after($key).remove()
      } else {
        $('#keys tbody').prepend($key)
      }
      $key.find('.edit_link')[0].focus()
    },
    error () {
      $('#edit_dialog button.submit').text(I18n.t('button.saving_failed', 'Saving Key Failed'))
    }
  })
  return $form
}

const sendEvent = (event, $orig, focus_selector) =>
  $.ajaxJSON(`${rawEndpoint()}/${$orig.data('key').id}`, 'PUT', {developer_key: {event}}, (data) => {
      const $key = buildKey(data)
      $orig.after($key).remove()
      if (focus_selector) $key.find(focus_selector)[0].focus()
  })

const rawEndpoint = () => '/api/v1/developer_keys'

const accountEndpoint = () => ENV.accountEndpoint

function nextPage () {
  let req
  $('#loading').attr('class', 'loading')
  page++
  return (req = $.ajaxJSON(`${accountEndpoint()}?page=${page}`, 'GET', {}, (data) => {
    data.forEach(key => {
      const $key = buildKey(key)
      $('#keys tbody').append($key)
    })

    if (req.getAllResponseHeaders().match(/rel="next"/)) {
      if (page > 1) {
        return nextPage()
      } else {
        return $('#loading').attr('class', 'show_more')
      }
    } else {
      return $('#loading').attr('class', '')
    }
  }))
}

nextPage()
$('#keys')
  .on('click', '.delete_link', preventDefault(function () {
    const $key = $(this).closest('.key')
    const $prevKey = $key.prev()
    const $toFocus = $prevKey.length ? $prevKey.find('.delete_link')[0] : $('.add_key')[0]
    const key = $key.data('key')
    $key.confirmDelete({
      url: `/api/v1/developer_keys/${key.id}`,
      message: I18n.t('messages.confirm_delete', 'Are you sure you want to delete this developer key?'),
      success () {
        $key.remove()
        $toFocus.focus()
      }
    })
  }))
  .on('click','.edit_link', preventDefault(function () {
    const $key = $(this).closest('.key')
    const key = $key.data('key')
    const $form = buildForm(key, $key)
    $('#edit_dialog').empty().append($form).dialog('open')
  }))
  .on('click', '.deactivate_link', preventDefault(function () {
    const $key = $(this).closest('.key')
    sendEvent('deactivate', $key, '.activate_link')
  }))
  .on('click', '.activate_link', preventDefault(function () {
    const $key = $(this).closest('.key')
    sendEvent('activate', $key, '.deactivate_link')
  }))

$('.add_key').click((event) => {
  event.preventDefault()
  const $form = buildForm()
  $('#edit_dialog').empty().append($form).dialog('open')
})

$('#edit_dialog')
  .html(developerKeyFormTemplate({}))
  .dialog({autoOpen: false, width: 400})
  .on('click', '.cancel', () => $('#edit_dialog').dialog('close'))

$('.show_all').click(event => nextPage())
