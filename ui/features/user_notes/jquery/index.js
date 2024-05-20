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
import ready from '@instructure/ready'
import '@canvas/jquery/jquery.instructure_forms'
import '@canvas/loading-image'
import '@canvas/datetime/jquery'
import '@canvas/jquery/jquery.instructure_misc_plugins'
import 'jquery-pageless'
import {raw} from '@instructure/html-escape'

const I18n = useI18nScope('user_notes')

ready(function () {
  if (ENV.user_note_list_pageless_options) {
    $('#user_note_list').pageless(ENV.user_note_list_pageless_options)
  }

  $('.cancel_button')
    .click(() => {
      $('#create_entry').slideUp()
    })
    .end()
    .find(':text')
    .keycodes('esc', () => {
      $('.cancel_button').click()
    })

  $('#new_user_note_button').click(event => {
    event.preventDefault()
    $('#create_entry').slideDown()
    $('#add_entry_form').find(':text:first').focus().select()
  })

  $('#add_entry_form').formSubmit({
    resetForm: true,
    beforeSubmit(_data) {
      $('#create_entry').slideUp()
      $('#proccessing').loadingImage()
      return true
    },
    success(data) {
      $('#no_user_notes_message').hide()
      $(this).find('.title').val('')
      $(this).find('.note').val('')
      const user_note = data.user_note
      user_note.created_at = $.datetimeString(user_note.updated_at)
      const action = $('#add_entry_form').attr('action') + '/' + user_note.id
      $('#proccessing').loadingImage('remove')
      $('#user_note_blank')
        .clone(true)
        .prependTo($('#user_note_list'))
        .attr('id', 'user_note_' + user_note.id)
        .fillTemplateData({data: user_note})
        .find('.delete_user_note_link')
        .attr('href', action)
        .attr('title', (i, oldTitle) => oldTitle.replace('{{ title }}', user_note.title))
        .find('.screenreader-only')
        .text((i, oldText) => oldText.replace('{{ title }}', user_note.title))
        .end()
        .end()
        .find('.formatted_note')
        .html(raw(user_note.formatted_note))
        .end()
        .slideDown()
    },
    error(_data) {
      $('#proccessing').loadingImage('remove')
      $('#create_entry').slideDown()
    },
  })

  $('.delete_user_note_link').click(function (event) {
    event.preventDefault()
    const token = $('form:first').getFormData().authenticity_token
    const $user_note = $(this).parents('.user_note')
    $user_note.confirmDelete({
      message: I18n.t(
        'confirms.delete_journal_entry',
        'Are you sure you want to delete this journal entry?'
      ),
      token,
      url: $(this).attr('href'),
      success() {
        $(this).fadeOut('slow', function () {
          $(this).remove()
          if (!$('#user_note_list > .user_note').length) {
            $('#no_user_notes_message').show()
          }
        })
      },
      error(data) {
        $(this).formErrors(data)
      },
    })
  })
})
