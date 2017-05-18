#
# Copyright (C) 2012 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'i18n!developer_keys'
  'jquery'
  'jst/developer_key'
  'jst/developer_key_form'
  'compiled/fn/preventDefault'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
], (I18n, $, developer_key, developerKeyFormTemplate, preventDefault) ->
  page = 0
  buildKey = (key) ->
    key.icon_image_url = key.icon_url || "/images/blank.png"
    key.name ||= I18n.t('unnamed_tool', "Unnamed Tool")
    key.user_name ||= I18n.t('no_user', "No User")
    key.created = $.datetimeString(key.created_at)
    key.last_auth = $.datetimeString(key.last_auth_at)
    key.last_access = $.datetimeString(key.last_access_at)
    key.inactive = key.workflow_state == 'inactive'
    $key = $(developer_key(key))
    $key.data('key', key)

  buildForm = (key, $orig) ->
    key = key || {}

    if !key.id
      key._formAction = accountEndpoint()
    else
      key._formAction = rawEndpoint()

    $form = $(developerKeyFormTemplate(key))
    $form.formSubmit({
      beforeSubmit: ->
        $("#edit_dialog button.submit").text(I18n.t('button.saving', "Saving Key..."))
      disableWhileLoading: true
      success: (key) ->
        $("#edit_dialog").dialog('close')
        $key = buildKey(key)
        if $orig
          $orig.after($key).remove()
        else
          $("#keys tbody").prepend($key)
        $key.find('.edit_link')[0].focus()
      error: ->
        $("#edit_dialog button.submit").text(I18n.t('button.saving_failed', "Saving Key Failed"))
    })
    return $form

  sendEvent = (event, $orig, focus_selector) ->
    $.ajaxJSON(rawEndpoint() + '/' + $orig.data('key').id, 'PUT', { developer_key: { event: event }},
      (data) ->
        $key = buildKey(data)
        $orig.after($key).remove()
        $key.find(focus_selector)[0].focus() if focus_selector
    )

  rawEndpoint = ->
    return '/api/v1/developer_keys'

  accountEndpoint = ->
    return ENV.accountEndpoint

  nextPage = ->
    $("#loading").attr('class', 'loading')
    page++
    req = $.ajaxJSON(accountEndpoint() + '?page=' + page, 'GET', {}, (data) ->
      for key in data
        $key = buildKey(key)
        $("#keys tbody").append($key)
      if req.getAllResponseHeaders().match /rel="next"/
        if page > 1
          nextPage()
        else
          $("#loading").attr('class', 'show_more')
      else
        $("#loading").attr('class', '')
    )
  nextPage()
  $("#keys").on('click', '.delete_link', preventDefault ->
    $key = $(this).closest(".key")
    $prevKey = $key.prev()
    $toFocus = if $prevKey.length then $prevKey.find('.delete_link')[0] else $('.add_key')[0]
    key = $key.data('key')
    $key.confirmDelete({
      url: "/api/v1/developer_keys/" + key.id,
      message: I18n.t('messages.confirm_delete', 'Are you sure you want to delete this developer key?'),
      success: ->
        $key.remove()
        $toFocus.focus()
    })
  ).on('click', '.edit_link', preventDefault ->
    $key = $(this).closest(".key")
    key = $key.data('key')
    $form = buildForm(key, $key)
    $("#edit_dialog").empty().append($form).dialog('open')
  ).on('click', '.deactivate_link', preventDefault ->
    $key = $(this).closest(".key")
    sendEvent('deactivate', $key, '.activate_link')
  ).on('click', '.activate_link', preventDefault ->
    $key = $(this).closest(".key")
    sendEvent('activate', $key, '.deactivate_link')
  )
  $(".add_key").click((event) ->
    event.preventDefault()
    $form = buildForm()
    $("#edit_dialog").empty().append($form).dialog('open')
  )
  $("#edit_dialog").html(developerKeyFormTemplate({})).dialog({
    autoOpen: false,
    width: 400
  }).on('click', '.cancel', () ->
    $("#edit_dialog").dialog('close')
  )
  $(".show_all").click (event) ->
    nextPage()
