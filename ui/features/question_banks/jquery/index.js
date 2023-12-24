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
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/datetime/jquery' /* datetimeString */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, formErrors */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'

const I18n = useI18nScope('question_banks')

$(document).ready(function () {
  $('.add_bank_link').click(event => {
    event.preventDefault()
    const $bank = $('#question_bank_blank').clone(true).attr('id', 'question_bank_new')
    $('#questions').prepend($bank.show())
    $bank.find('.edit_bank_link').click()
  })
  $('.question_bank .delete_bank_link').click(function (event) {
    event.preventDefault()
    $(this)
      .parents('.question_bank')
      .confirmDelete({
        url: $(this).attr('href'),
        message: I18n.t(
          'delete_question_bank_prompt',
          'Are you sure you want to delete this bank of questions?'
        ),
        success() {
          $(this).slideUp(function () {
            $(this).remove()
          })
        },
      })
  })
  $('.question_bank .bookmark_bank_link').click(function (event) {
    event.preventDefault()
    const $link = $(this)
    const $bank = $link.parents('.question_bank')
    $.ajaxJSON($(this).attr('href'), 'POST', {}, _data => {
      $bank.find('.bookmark_bank_link').toggle()
      $bank.find('.bookmark_bank_link:visible:first').focus()
    })
  })
  $('.question_bank .edit_bank_link').click(function (event) {
    event.preventDefault()
    const $bank = $(this).parents('.question_bank')
    const data = $bank.getTemplateData({textValues: ['title']})
    $bank.find('.header_content').hide()
    const $form = $('#edit_bank_form')
    $bank.find('.header').prepend($form.show())
    $form.attr('action', $(this).attr('href'))
    $form.attr('method', 'PUT')
    if ($bank.attr('id') === 'question_bank_new') {
      $form.attr('action', $('#bank_urls .add_bank_url').attr('href'))
      $form.attr('method', 'POST')
    }
    $form.fillFormData(data, {object_name: 'assessment_question_bank'})
    $form.find(':text:visible:first').focus().select()
  })
  $('#edit_bank_form .bank_name_box').keycodes('return esc tab', function (event) {
    if (event.keyString === 'esc') {
      $(this).parents('.question_bank').addClass('dont_save')
      $(this).blur()
    } else if (event.keyString === 'return') {
      $('#edit_bank_form').submit()
    } else if (event.keyString === 'tab') {
      $('nav#breadcrumbs a:visible:first').focus()
      event.preventDefault()
    }
  })
  $('#edit_bank_form .bank_name_box').blur(function () {
    const $bank = $(this).parents('.question_bank')
    if (
      !$bank.hasClass('dont_save') &&
      !$bank.hasClass('save_in_progress') &&
      $bank.attr('id') !== 'question_bank_new'
    ) {
      $('#edit_bank_form').submit()
      return
    }
    $bank.removeClass('dont_save')
    $bank.find('.header_content').show()
    $('body').append($('#edit_bank_form').hide())
    if ($bank.attr('id') === 'question_bank_new') {
      $bank.remove()
    }
  })
  $('#edit_bank_form').formSubmit({
    object_name: 'assessment_question_bank',
    beforeSubmit(data) {
      const $bank = $(this).parents('.question_bank')
      $bank.attr('id', 'question_bank_adding')
      try {
        $bank.addClass('save_in_progress')
        $bank.find('.bank_name_box').blur()
      } catch (e) {
        // no-op
      }
      $bank.fillTemplateData({
        data,
      })
      $bank.loadingImage()
      return $bank
    },
    success(data, $bank) {
      $bank.loadingImage('remove')
      $bank.removeClass('save_in_progress')
      const bank = data.assessment_question_bank
      bank.last_updated_at = $.datetimeString(bank.updated_at)
      $bank.fillTemplateData({
        data: bank,
        hrefValues: ['id'],
      })
      // if you can convince fillTemplateData to do this, please be my guest
      $bank.find('.links a').each((_, link) => {
        link.setAttribute('title', link.getAttribute('title').replace('{{ title }}', bank.title))
      })
      $bank.find('.links a span').each((_, span) => {
        span.textContent = span.textContent.replace('{{ title }}', bank.title)
      })
      $bank.find('a.title')[0].focus()
    },
    error(data, $bank) {
      $bank.loadingImage('remove')
      $bank.removeClass('save_in_progress')
      $bank.find('.edit_bank_link').click()
      $('#edit_bank_form').formErrors(data)
    },
  })
})
