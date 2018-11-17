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

import I18n from 'i18n!terms.index'

import $ from 'jquery'
import 'jquery.instructure_date_and_time'
import 'jquery.instructure_forms'
import 'jquery.instructure_misc_helpers'
import 'jquery.instructure_misc_plugins'
import 'jquery.templateData'

const dateOpts = {format: 'full'}

$(document).ready(() => {
  $('.submit_button').click(function(event) {
    const $term = $(this).closest('.term')
    return $term.find('.enrollment_term_form').submit()
  })

  $('.edit_term_link').click(function(event) {
    event.preventDefault()
    $(this)
      .parents('.term')
      .addClass('editing_term')
    $(this)
      .parents('.term')
      .find(':text:visible:first')
      .focus()
      .select()
    $(this)
      .parents('.term')
      .find('.date_field')
      .not('.already_has_date_field')
      .addClass('already_has_date_field')
      .date_field()
  })

  $('.term .cancel_button').click(function() {
    const $term = $(this).closest('.term')
    $term.removeClass('editing_term')
    if ($term.attr('id') === 'term_new') {
      $term.remove()
      $('.add_term_link').focus()
    } else {
      $('.edit_term_link', $term).focus()
    }
  })

  $('.cant_delete_term_link').click(event => {
    event.preventDefault()
    alert(
      I18n.t('messages.classes_in_term', "You can't delete a term that still has classes in it.")
    )
  })

  $('.delete_term_link').click(function(event) {
    event.preventDefault()
    const $term = $(this).closest('.term')
    let $focusTerm = $term.prev()
    if (!$focusTerm.length) {
      $focusTerm = $term.next()
    }
    const $toFocus = $focusTerm.length
      ? $('.delete_term_link,.cant_delete_term_link', $focusTerm)
      : $('.add_term_link')
    const url = $term.find('.enrollment_term_form').attr('action')
    return $term.confirmDelete({
      url,
      message: I18n.t('prompts.delete', 'Are you sure you want to delete this term?'),
      success() {
        $(this).fadeOut(function() {
          $(this).remove()
          $toFocus.focus()
        })
      }
    })
  })

  $('.enrollment_term_form').formSubmit({
    processData(data) {
      const permissions = $(this)
        .parents('tr')
        .find('.permissions')
        .getFormData({object_name: 'enrollment_term'})
      return $.extend(permissions, data)
    },

    beforeSubmit(data) {
      const $tr = $(this).parents('.term')
      $tr.find('button').attr('disabled', true)
      return $tr.find('.submit_button').text(I18n.t('messages.submitting', 'Submitting...'))
    },

    success(data) {
      const term = data.enrollment_term
      const $tr = $(this).parents('.term')
      $tr.find('button').attr('disabled', false)
      $tr.find('.submit_button').text(I18n.t('update_term', 'Update Term'))
      const url = $.replaceTags($('.term_url').attr('href'), 'id', term.id)
      $(this).attr('action', url)
      $(this).attr('method', 'PUT')
      for (const idx in term.enrollment_dates_overrides) {
        var start_string
        const override = term.enrollment_dates_overrides[idx].enrollment_dates_override
        const type_string = $.underscore(override.enrollment_type)
        // Student enrollments without an overridden start date get the term's overall start date, while teacher, ta,
        // and designer roles without an overridden start date allow access from the dawn of time. The logic
        // implementing this is in EnrollmentTerm#enrollment_dates_for.
        if (override.start_at) {
          start_string = $.dateString(override.start_at, dateOpts)
        } else if (type_string === 'student_enrollment') {
          start_string = I18n.t('term start')
        } else {
          start_string = I18n.t('whenever')
        }
        term[`${type_string}_start_at`] = start_string
        // Non-overridden end dates always inherit the term end date, no matter the role.
        term[`${type_string}_end_at`] =
          $.dateString(override.end_at, dateOpts) || I18n.t('date.term_end', 'term end')
        term[`enrollment_term[overrides][${type_string}][start_at]`] = $.dateString(
          override.start_at,
          dateOpts
        )
        term[`enrollment_term[overrides][${type_string}][end_at]`] = $.dateString(
          override.end_at,
          dateOpts
        )
      }
      term.start_at =
        $.dateString(term.start_at, dateOpts) || I18n.t('date.unspecified', 'whenever')
      term.end_at = $.dateString(term.end_at, dateOpts) || I18n.t('date.unspecified', 'whenever')
      $tr.fillTemplateData({data: term})
      $tr.attr('id', `term_${term.id}`)
      $tr.fillFormData(data, {object_name: 'enrollment_term'})

      $tr.removeClass('editing_term')
      $('.edit_term_link', $tr).focus()
    },

    error(data) {
      let button_text
      const $term = $(this).closest('.term')
      const $tr = $(this).parents('.term')
      $tr.find('button').attr('disabled', false)
      $(this).formErrors(data)
      if ($term.attr('id') === 'term_new') {
        button_text = I18n.t('add_term', 'Add Term')
      } else {
        button_text = I18n.t('update_term', 'Update Term')
      }
      $tr.find('.submit_button').text(button_text)
      $('.edit_term_link', $(this).closest('term')).focus()
    }
  })

  $('.add_term_link').click(event => {
    event.preventDefault()
    if ($('#term_new').length > 0) return
    const $term = $('#term_blank')
      .clone(true)
      .attr('id', 'term_new')
    $('#terms').prepend($term.show())
    $term.find('.edit_term_link').click()
  })
})
