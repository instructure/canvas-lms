/* eslint-disable eqeqeq */
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
import '@canvas/datetime/jquery' /* time_field, datetime_field */
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, formErrors */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/util/templateData'
import 'jqueryui/menu'
import 'jqueryui/autocomplete'
import PaginatedList from './PaginatedList'
import enrollmentTemplate from '../jst/enrollment.handlebars'
import sectionEnrollmentPresenter from '../sectionEnrollmentPresenter'
import '@canvas/context-cards/react/StudentContextCardTrigger'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('section')

$(document).ready(function () {
  const section_id = window.location.pathname.split('/')[4],
    $edit_section_form = $('#edit_section_form'),
    $edit_section_link = $('.edit_section_link')
  new PaginatedList($('#current-enrollment-list'), {
    presenter: sectionEnrollmentPresenter,
    template: enrollmentTemplate,
    url: '/api/v1/sections/' + section_id + '/enrollments?include[]=can_be_removed',
  })
  new PaginatedList($('#completed-enrollment-list'), {
    presenter: sectionEnrollmentPresenter,
    requestParams: {state: 'completed', page: 1, per_page: 25},
    template: enrollmentTemplate,
    url: '/api/v1/sections/' + section_id + '/enrollments?include[]=can_be_removed',
  })

  $edit_section_form
    .formSubmit({
      beforeSubmit(data) {
        $edit_section_form.hide()
        $edit_section_form.find('.name').text(data['course_section[name]']).show()
        $edit_section_form.loadingImage({image_size: 'small'})
      },
      success(data) {
        const section = data.course_section
        $edit_section_form.loadingImage('remove')
        $('#section_name').text(section.name)
        $('span.sis_source_id').text(section.sis_source_id || '')
      },
      error(_data) {
        $edit_section_form.loadingImage('remove')
        $edit_section_form.show()
      },
    })
    .find(':text')
    .keycodes('return esc', function (event) {
      if (event.keyString === 'return') {
        $edit_section_form.submit()
      } else {
        $(this).parents('.section').find('.name').show()
        $edit_section_form.hide()
      }
    })
    .end()
    .find('.cancel_button')
    .click(() => {
      $edit_section_form.hide()
    })

  $edit_section_link.click(event => {
    event.preventDefault()
    $edit_section_form.toggle()
    $('#edit_section_form :text:visible:first').focus().select()
  })

  $('.user_list').on('click', '.unenroll_user_link', function (event) {
    event.preventDefault()
    $(this)
      .parents('.user')
      .confirmDelete({
        message: I18n.t(
          'confirms.delete_enrollment',
          'Are you sure you want to delete this enrollment permanently?'
        ),
        url: $(this).attr('href'),
        success() {
          $(this).slideUp(function () {
            $(this).remove()
          })
        },
      })
  })
  $('.datetime_field').datetime_field()
  $('.uncrosslist_link').click(event => {
    event.preventDefault()
    $('#uncrosslist_form').dialog({
      width: 400,
      modal: true,
      zIndex: 1000,
    })
  })
  $('#uncrosslist_form .cancel_button')
    .click(_event => {
      $('#uncrosslist_form').dialog('close')
    })
    .submit(function () {
      $(this)
        .find('button')
        .prop('disabled', true)
        .filter('.submit_button')
        .text(I18n.t('status.removing_crosslisting_of_section', 'De-Cross-Listing Section...'))
    })
  $('.crosslist_link').click(event => {
    event.preventDefault()
    $('#crosslist_course_form').dialog({
      width: 450,
      modal: true,
      zIndex: 1000,
    })
    $('#crosslist_course_form .submit_button').prop('disabled', true)
    $('#course_autocomplete_id_lookup').val('')
    $('#course_id').val('').change()
  })
  $('#course_autocomplete_id_lookup').autocomplete({
    source: $('#course_autocomplete_url').attr('href'),
    select(event, ui) {
      $('#course_id').val('')
      $('#crosslist_course_form').triggerHandler('id_entered', ui.item)
    },
  })
  $('#course_id').keycodes('return', function (event) {
    event.preventDefault()
    $(this).change()
  })
  $('#course_id').bind('change', function () {
    $('#course_autocomplete_id_lookup').val('')
    $('#crosslist_course_form').triggerHandler('id_entered', {id: $(this).val()})
  })
  $('#crosslist_course_form .cancel_button').click(() => {
    $('#crosslist_course_form').dialog('close')
  })
  let latest_course_id = null
  $('#crosslist_course_form').bind('id_entered', (event, course) => {
    if (course.id == latest_course_id) {
      return
    }
    $('#crosslist_course_form .submit_button').prop('disabled', true)
    $('#course_autocomplete_id').val('')
    if (!course.id) {
      $('#sis_id_holder,#account_name_holder').hide()
      $('#course_autocomplete_name').text('')
      return
    }
    course.name =
      course.name ||
      I18n.t('default_course_name', 'Course ID "%{course_id}"', {course_id: course.id})
    $('#course_autocomplete_name_holder').show()
    const confirmingText = I18n.t('status.confirming_course', 'Confirming %{course_name}...', {
      course_name: course.name,
    })
    $('#course_autocomplete_name').text(confirmingText)
    $.screenReaderFlashMessage(confirmingText)
    $('#sis_id_holder,#account_name_holder').hide()
    $('#course_autocomplete_account_name').hide()
    const url = replaceTags($('#course_confirm_crosslist_url').attr('href'), 'id', course.id)
    latest_course_id = course.id
    const course_id_before_get = latest_course_id
    $.ajaxJSON(
      url,
      'GET',
      {},
      data => {
        if (course_id_before_get != latest_course_id) {
          return
        }
        if (data && data.allowed) {
          const template_data = {
            sis_id: data.course && data.course.sis_source_id,
            account_name: data.account && data.account.name,
          }
          $('#course_autocomplete_name_holder').fillTemplateData({data: template_data})
          $('#course_autocomplete_name').text(data.course.name)
          $.screenReaderFlashMessage(data.course.name)
          $('#sis_id_holder').showIf(template_data.sis_id)
          $('#account_name_holder').showIf(template_data.account_name)

          $('#course_autocomplete_id').val(data.course.id)
          $('#crosslist_course_form .submit_button').prop('disabled', false)
        } else {
          const errorText = I18n.t(
            'errors.course_not_authorized_for_crosslist',
            '%{course_name} not authorized for cross-listing',
            {course_name: course.name}
          )
          $('#course_autocomplete_name').text(errorText)
          $.screenReaderFlashError(errorText)
          $('#sis_id_holder,#account_name_holder').hide()
        }
      },
      _data => {
        $('#course_autocomplete_name').text(
          I18n.t('errors.confirmation_failed', 'Confirmation Failed')
        )
      }
    )
  })
})
