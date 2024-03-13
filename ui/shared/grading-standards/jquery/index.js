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

import round from '@canvas/round'
import {useScope as useI18nScope} from '@canvas/i18n'
import numberHelper from '@canvas/i18n/numberHelper'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* fillFormData, getFormData */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* ifExists, .dim, undim, confirmDelete */
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData' /* fillTemplateData, getTemplateData */
import 'jquery-scroll-to-visible/jquery.scrollTo'

const I18n = useI18nScope('grading_standards')

function roundedNumber(val) {
  return I18n.n(round(val, round.DEFAULT))
}

const MINIMUM_SCHEME_VALUE_DIFFERENCE = 0.01

$(document).ready(() => {
  $('.add_standard_link').click(event => {
    event.preventDefault()
    const $standard = $('#grading_standard_blank').clone(true).attr('id', 'grading_standard_new')
    $('#standards').append($standard.show())
    $standard.find('.edit_grading_standard_link').click()
  })
  $('.edit_letter_grades_link').click(event => {
    event.preventDefault()
    $('#edit_letter_grades_form').dialog({
      title: I18n.t('titles.grading_scheme_info', 'View/Edit Grading Scheme'),
      width: 600,
      dialogClass: 'form-inline grading-standard-dialog',
      resizable: false,
      open() {
        $('.grading-standard-dialog').find('.ui-dialog-titlebar-close')[0].focus()
      },
      close() {
        $(event.target).focus()
      },
      modal: true,
      zIndex: 1000,
    })
  })
  $('.grading_standard .delete_grading_standard_link').click(function (event) {
    event.preventDefault()
    const $standard = $(this).parents('.grading_standard')
    const url = $standard.find('.update_grading_standard_url').attr('href')
    $standard.confirmDelete({
      url,
      message: I18n.t(
        'confirm.delete_grading_scheme',
        'Are you sure you want to delete this grading scheme?'
      ),
      success(_data) {
        $(this).slideUp(function () {
          $(this).remove()
        })
      },
      error() {
        $.flashError(
          I18n.t(
            'errors.cannot_delete_grading_scheme',
            'There was a problem deleting this grading scheme'
          )
        )
      },
    })
  })
  $('.grading_standard .done_button').click(event => {
    event.preventDefault()
    $('#edit_letter_grades_form').dialog('close')
  })
  $('.grading_standard .remove_grading_standard_link').click(function (event) {
    event.preventDefault()
    // eslint-disable-next-line no-alert
    const result = window.confirm(
      I18n.t(
        'confirm.unlink_grading_scheme',
        'Are you sure you want to unlink this grading scheme?'
      )
    )
    if (!result) {
      return false
    }
    const $standard = $(this).parents('.grading_standard')
    $standard.dim()
    let put_data = {
      'assignment[grading_standard_id]': '',
      'assignment[grading_type]': 'points',
    }
    let url = $('#edit_assignment_form').attr('action')
    if ($('#update_course_url').length) {
      put_data = {
        'course[grading_standard_id]': '',
      }
      url = $('#update_course_url').attr('href')
    } else if (url && url.match(/assignments$/)) {
      url = null
    }
    function removed() {
      $('#edit_assignment_form .grading_standard_id').val('')
      $('#assignment_grading_type').val('points').change()
      $('#course_course_grading_standard_enabled').prop('checked', false).change()
      $('#course_form .grading_scheme_set').text(I18n.t('grading_scheme_not_set', 'Not Set'))
      $standard.addClass('editing')
      $standard
        .find('.update_grading_standard_url')
        .attr('href', $('#update_grading_standard_url').attr('href'))
      const data = JSON.parse($('#default_grading_standard_data').val())
      const standard = {title: '', id: null, data}
      $standard
        .fillTemplateData({
          data: standard,
          id: 'grading_standard_blank',
          avoid: '.find_grading_standard',
          hrefValues: ['id'],
        })
        .find('.edit_grading_standard_link')
        .removeClass('read_only')
      $standard.triggerHandler('grading_standard_updated', standard)
      $('#edit_letter_grades_form').dialog('close')
      $standard.undim()
    }
    if (url) {
      $.ajaxJSON(url, 'PUT', put_data, removed, () => {
        $.flashError(
          I18n.t(
            'errors.cannot_remove_grading_scheme',
            'There was a problem removing this grading scheme.  Please reload the page and try again.'
          )
        )
      })
    } else {
      removed()
    }
  })
  $('.grading_standard .edit_grading_standard_link').click(function (event) {
    event.preventDefault()
    const $standard = $(this).parents('.grading_standard')
    $standard.addClass('editing')
    $standard.find('.max_score_cell').attr('tabindex', '0')
    if ($(this).hasClass('read_only')) {
      $standard.attr('id', 'grading_standard_blank')
    }
    $standard.find('.grading_standard_row').each(function () {
      const data = $(this).getTemplateData({textValues: ['min_score', 'name']})
      $(this)
        .find('.standard_value')
        .val(data.min_score)
        .end()
        .find('.standard_name')
        .val(data.name)
    })
    $('#standards').ifExists(() => {
      $('html,body').scrollTo($standard)
    })
    $standard.find(':text:first').blur().focus().select()
  })
  $('.grading_standard .grading_standard_brief')
    .find('.collapse_data_link,.expand_data_link')
    .click(function (event) {
      event.preventDefault()
      const $brief = $(this).parents('.grading_standard_brief')
      $brief.find('.collapse_data_link,.expand_data_link').toggle()
      $brief.find('.details').slideToggle()
    })
  $(document).on('click', '.grading_standard_select', function (event) {
    event.preventDefault()
    const id = $(this).getTemplateData({textValues: ['id']}).id
    $('.grading_standard .grading_standards_select .grading_standard_select').removeClass(
      'selected_side_tab'
    )
    $(this).addClass('selected_side_tab')
    $('.grading_standard .grading_standards .grading_standard_brief').hide()
    $(`#grading_standard_brief_${id}`).show()
  })
  $('.grading_standard')
    .find('.find_grading_standard_link,.cancel_find_grading_standard_link')
    .click(function (event) {
      event.preventDefault()
      $(this)
        .parents('.grading_standard')
        .find('.display_grading_standard,.find_grading_standard')
        .toggle()
      const $find = $(this).parents('.grading_standard').find('.find_grading_standard:visible')
      if ($find.length > 0 && !$find.hasClass('loaded')) {
        $find.find('.loading_message').text(I18n.t('Loading Grading Schemes...'))
        const url = $find.find('.grading_standards_url').attr('href')
        $.ajaxJSON(
          url,
          'GET',
          {},
          data => {
            if (data.length === 0) {
              $find
                .find('.loading_message')
                .text(I18n.t('no_grading_standards', 'No grading schemes found'))
            } else {
              $find.find('.loading_message').remove()
              for (const idx in data) {
                const standard = data[idx].grading_standard
                standard.user_name = standard.display_name
                const $standard_select = $find
                  .find('.grading_standards_select .grading_standard_select.blank:first')
                  .clone(true)
                $standard_select
                  .fillTemplateData({
                    data: standard,
                  })
                  .data('context_code', standard.context_code)
                  .removeClass('blank')
                $find.find('.grading_standards_select').append($standard_select.show())
                const $standard = $find.find('.grading_standard_brief.blank:first').clone(true)
                $standard
                  .fillTemplateData({
                    data: standard,
                    id: `grading_standard_brief_${standard.id}`,
                  })
                  .data('context_code', standard.context_code)
                $standard.removeClass('blank')
                for (let jdx = 0; jdx < standard.data.length; jdx++) {
                  const row = {
                    name: standard.data[jdx][0],
                    value:
                      jdx === 0
                        ? roundedNumber(100)
                        : `< ${roundedNumber(standard.data[jdx - 1][1] * 100)}`,
                    next_value: roundedNumber(standard.data[jdx][1] * 100),
                  }
                  const $row = $standard.find('.details_row.blank:first').clone(true)
                  $row.removeClass('blank')
                  $row.fillTemplateData({data: row})
                  $standard.find('.details > table').append($row.show())
                }
                $find.find('.grading_standards').append($standard)
              }
              $find
                .find('.grading_standards_select .grading_standard_select:visible:first a:first')
                .click()
            }
            $find.addClass('loaded')
            $find.find('.grading_standards_holder').slideDown()
          },
          _data => {
            $find
              .find('.loading_message')
              .text(I18n.t('Loading Grading Schemes Failed.  Please Try Again'))
          }
        )
      }
    })
  $('.grading_standard .grading_standard_brief .select_grading_standard_link').click(function (
    event
  ) {
    event.preventDefault()
    const $brief = $(this).parents('.grading_standard_brief')
    const brief = $brief.getTemplateData({
      textValues: ['id', 'title'],
      dataValues: ['context_code'],
    })
    const id = brief.id
    const title = brief.title
    const data = []
    $(this)
      .parents('.grading_standard_brief')
      .find('.details_row:not(.blank)')
      .each(function () {
        const name = $(this).find('.name').text()
        let val = numberHelper.parse($(this).find('.next_value').text()) / 100.0
        if (Number.isNaN(Number(val))) {
          val = ''
        }
        data.push([name, val])
      })
    $(this).parents('.grading_standard').triggerHandler('grading_standard_updated', {
      id,
      data,
      title,
    })
    const current_context_code = $('#edit_letter_grades_form').data().context_code
    $(this)
      .parents('.grading_standard')
      .find('.edit_grading_standard_link')
      .toggleClass('read_only', current_context_code !== brief.context_code)
    $(this).parents('.find_grading_standard').find('.cancel_find_grading_standard_link').click()
  })
  $('.grading_standard .cancel_button').click(function (_event) {
    $(this)
      .parents('.grading_standard')
      .removeClass('editing')
      .find('.insert_grading_standard')
      .hide()
    const $standard = $(this).parents('.grading_standard')
    $standard.find('.max_score_cell').removeAttr('tabindex')
    $standard.find('.to_add').remove()
    $standard.find('.to_delete').removeClass('to_delete').show()
    if ($standard.attr('id') === 'grading_standard_new') {
      $standard.remove()
    }
  })
  $('.grading_standard').bind('grading_standard_updated', function (event, standard) {
    const $standard = $(this)
    $standard.addClass('editing')
    $standard
      .find('.update_grading_standard_url')
      .attr('href', $('#update_grading_standard_url').attr('href'))
    $standard
      .fillTemplateData({
        data: standard,
        id: `grading_standard_${standard.id || 'blank'}`,
        avoid: '.find_grading_standard',
        hrefValues: ['id'],
      })
      .fillFormData(standard, {object_name: 'grading_standard'})
    const $link = $standard.find('.insert_grading_standard:first').clone(true)
    const $row = $standard.find('.grading_standard_row:first').clone(true).removeClass('blank')
    const $table = $standard.find('.grading_standard_data')
    const $thead = $table.find('thead')
    $table.empty()
    $table.append($thead)
    $table.append($link.clone(true).show())
    $table.append($link.hide())
    for (const idx in standard.data) {
      const $row_instance = $row.clone(true)
      const row = standard.data[idx]
      $row_instance.removeClass('to_delete').removeClass('to_add')
      $row_instance
        .find('.standard_name')
        .val(row[0])
        .attr('name', `grading_standard[standard_data][scheme_${idx}][name]`)
        .end()
        .find('.standard_value')
        .val(I18n.n(round(row[1] * 100, 2)))
        .attr('name', `grading_standard[standard_data][scheme_${idx}][value]`)
      $table.append($row_instance.show())
      $table.append($link.clone(true).show())
    }
    $table.find(':text:first').blur()
    $standard.find('.grading_standard_row').each(function () {
      $(this)
        .find('.name')
        .text($(this).find('.standard_name').val())
        .end()
        .find('.min_score')
        .text($(this).find('.standard_value').val())
        .end()
        .find('.max_score')
        .text($(this).find('.edit_max_score').text())
    })
    $standard.removeClass('editing')
    $standard.find('.insert_grading_standard').hide()
    if (standard.id) {
      $standard.find('.remove_grading_standard_link').removeClass('read_only')
      let put_data = {
        'assignment[grading_standard_id]': standard.id,
        'assignment[grading_type]': 'letter_grade',
      }
      let url = $('#edit_assignment_form').attr('action')
      $('input.grading_standard_id, ').val(standard.id)
      if ($('#update_course_url').length) {
        put_data = {
          'course[grading_standard_id]': standard.id,
        }
        url = $('#update_course_url').attr('href')
      } else if (url && url.match(/assignments$/)) {
        url = null
      }
      if (url) {
        $.ajaxJSON(
          url,
          'PUT',
          put_data,
          data => {
            $('#course_form .grading_scheme_set').text(
              (data && data.course && data.course.grading_standard_title) ||
                I18n.t('grading_scheme_currently_set', 'Currently Set')
            )
          },
          () => {}
        )
      }
    } else {
      $standard.find('.remove_grading_standard_link').addClass('read_only')
    }
  })
  $('.grading_standard .save_button').click(function (_event) {
    const $standard = $(this).parents('.grading_standard')
    let url = $(
      '#edit_letter_grades_form .create_grading_standard_url,#create_grading_standard_url'
    ).attr('href')
    let method = 'POST'
    if (
      $standard.attr('id') !== 'grading_standard_blank' &&
      $standard.attr('id') !== 'grading_standard_new'
    ) {
      url = $(this).parents('.grading_standard').find('.update_grading_standard_url').attr('href')
      method = 'PUT'
    }
    const data = $standard.find('.standard_title,.grading_standard_row:visible').getFormData()
    Object.keys(data).forEach(key => {
      let parsedValue

      data[key] = data[key].trim()

      if (/^grading_standard\[.*\]\[value\]$/.test(key)) {
        parsedValue = numberHelper.parse(data[key])
        if (!Number.isNaN(Number(parsedValue))) {
          data[key] = parsedValue
        }
      }
    })
    $standard
      .find('button')
      .prop('disabled', true)
      .filter('.save_button')
      .text(I18n.t('status.saving', 'Saving...'))
    $.ajaxJSON(
      url,
      method,
      data,
      data_ => {
        const standard = data_.grading_standard
        $standard
          .find('button')
          .prop('disabled', false)
          .filter('.save_button')
          .text(I18n.t('buttons.save', 'Save'))
        $standard.triggerHandler('grading_standard_updated', standard)
      },
      () => {
        $standard
          .find('button')
          .prop('disabled', false)
          .filter('.save_button')
          .text(I18n.t('errors.save_failed', 'Save Failed'))
      }
    )
  })
  $('.grading_standard thead').mouseover(function (_event) {
    if (!$(this).parents('.grading_standard').hasClass('editing')) {
      return
    }
    $(this).parents('.grading_standard').find('.insert_grading_standard').hide()
    $(this).parents('.grading_standard').find('.insert_grading_standard:first').show()
  })
  $('.grading_standard .grading_standard_row').mouseover(function (event) {
    if (!$(this).parents('.grading_standard').hasClass('editing')) {
      return
    }
    $(this).parents('.grading_standard').find('.insert_grading_standard').hide()
    const y = event.pageY
    const offset = $(this).offset()
    const height = $(this).height()
    if (y > offset.top + height / 2) {
      $(this).next('.insert_grading_standard').show()
    } else {
      $(this).prev('.insert_grading_standard').show()
    }
  })
  $('.grading_standard *').focus(function (_event) {
    $(this).trigger('mouseover')
    if ($(this).hasClass('delete_row_link')) {
      $(this)
        .parents('.grading_standard_row')
        .nextAll('.grading_standard_row')
        .first()
        .trigger('mouseover')
    }
  })
  $('.grading_standard .insert_grading_standard_link').click(function (event) {
    event.preventDefault()
    if ($(this).parents('.grading_standard').find('.grading_standard_row').length > 40) {
      return
    }
    const $standard = $(this).parents('.grading_standard')
    const $row = $standard.find('.grading_standard_row:first').clone(true).removeClass('blank')
    const $link = $standard.find('.insert_grading_standard:first').clone(true)
    let temp_id = null
    while (
      !temp_id ||
      $(`.standard_name[name='grading_standard[standard_data][scheme_${temp_id}][name]']`).length >
        0
    ) {
      temp_id = Math.round(Math.random() * 10000)
    }
    $row
      .find('.standard_name')
      .val('-')
      .attr('name', `grading_standard[standard_data][scheme_${temp_id}][name]`)
    $row
      .find('.standard_value')
      .attr('name', `grading_standard[standard_data][scheme_${temp_id}][value]`)
    $(this).parents('.insert_grading_standard').after($row.show())
    $row.after($link)
    $standard.find(':text:first').blur()
    $row.find(':text:first').focus().select()
    $row.addClass('to_add')
  })
  $('.grading_standard .delete_row_link').click(function (event) {
    event.preventDefault()
    if ($(this).parents('.grading_standard').find('.grading_standard_row:visible').length < 2) {
      return
    }
    const $standard = $(this).parents('.grading_standard_row')
    if ($standard.prev('.insert_grading_standard').length > 0) {
      $standard.prev('.insert_grading_standard').remove()
    } else {
      $standard.next('.insert_grading_standard').remove()
    }
    $standard.fadeOut(function () {
      $(this).addClass('to_delete')
      // force refresh in case the deletion requires other changes
      $(".grading_standard input[type='text']:first").triggerHandler('change')
    })
  })
  $(".grading_standard input[type='text']").bind('blur change', function () {
    const $standard = $(this).parents('.grading_standard')
    let val = numberHelper.parse(
      $(this).parents('.grading_standard_row').find('.standard_value').val()
    )
    val = round(val, 2)
    $(this).parents('.grading_standard_row').find('.standard_value').val(I18n.n(val))

    if (Number.isNaN(Number(val))) {
      val = null
    }

    let lastVal = val || 100
    let prevVal = val || 0
    const $list = $standard.find('.grading_standard_row:not(.blank,.to_delete)')

    /*
     * Starting at the top of the list, traverse each row. Use `lastVal` to hold
     * the assigned minimum point value for the current row so that each
     * subsequent row is able to reference it while calculating its own minimum
     * point value.
     */
    for (
      let idx = $list.index($(this).parents('.grading_standard_row')) + 1;
      idx < $list.length;
      idx++
    ) {
      const $row = $list.eq(idx)

      // Parse the given point value from the input of the current row.
      let points = numberHelper.parse($row.find('.standard_value').val())

      if (Number.isNaN(Number(points))) {
        points = null
      }

      if (idx === $list.length - 1) {
        // When the current row is the last row, the minimum point value must be 0.
        points = 0
      } else if (!points || points > lastVal - MINIMUM_SCHEME_VALUE_DIFFERENCE) {
        /*
         * When the current row is NOT the last row, and the minimum point value is
         * either absent or is too close (higher value than 0.01 less than the
         * previous value), change the minimum point value to be one point less
         * than the minimum point value of the next-higher row.
         */
        points = parseInt(lastVal, 10) - 1
      }

      $row.find('.standard_value').val(I18n.n(points))
      lastVal = points
    }

    /*
     * Starting at the bottom of the list, traverse each row. Use `prevVal` to hold
     * the assigned minimum point value for the current row so that each
     * subsequent row is able to reference it while calculating its own minimum
     * point value.
     */
    for (let idx = $list.index($(this).parents('.grading_standard_row')) - 1; idx >= 0; idx--) {
      const $row = $list.eq(idx)

      // Parse the given point value from the input of the current row.
      let points = numberHelper.parse($row.find('.standard_value').val())

      if (Number.isNaN(Number(points))) {
        points = null
      }

      if (idx === $list.length - 1) {
        // When the current row is the last row, the minimum point value must be 0.
        points = 0
      } else if (!points || points < prevVal + MINIMUM_SCHEME_VALUE_DIFFERENCE) {
        /*
         * When the current row is NOT the last row, and the minimum point value is
         * either absent or is too close (higher value than 0.01 less than the
         * previous value), change the minimum point value to be one point less
         * than the minimum point value of the next-higher row.
         */
        points = parseInt(prevVal, 10) + 1
      }

      prevVal = points
      $row.find('.standard_value').val(I18n.n(points))
    }

    /*
     * Starting at the top of the list, traverse each row. Use `lastVal` to hold
     * the assigned minimum point value for the current row so that each
     * subsequent row is able to reference it while calculating its own minimum
     * point value.
     */
    lastVal = 100
    $list.each(function (idx) {
      // Parse the given point value from the input of the current row.
      let points = numberHelper.parse($(this).find('.standard_value').val())

      idx = $list.index(this)
      if (Number.isNaN(Number(points))) {
        points = null
      }

      if (idx === $list.length - 1) {
        // When the current row is the last row, the minimum point value must be 0.
        points = 0
      } else if (!points || points > lastVal - MINIMUM_SCHEME_VALUE_DIFFERENCE) {
        /*
         * When the current row is NOT the last row, and the minimum point value is
         * either absent or is too close (higher value than 0.01 less than the
         * previous value), change the minimum point value to be one point less
         * than the minimum point value of the next-higher row.
         */
        points = parseInt(lastVal, 10) - 1
      }

      $(this).find('.standard_value').val(I18n.n(points))
      lastVal = points
    })

    /*
     * Starting at the bottom of the list, traverse each row. Use `prevVal` to hold
     * the assigned minimum point value for the current row so that each
     * subsequent row is able to reference it while calculating its own minimum
     * point value.
     */
    prevVal = 0
    for (let idx = $list.length - 1; idx >= 0; idx--) {
      const $row = $list.eq(idx)

      // Parse the given point value from the input of the current row.
      let points = numberHelper.parse($row.find('.standard_value').val())

      if (Number.isNaN(Number(points))) {
        points = null
      }

      if (idx === $list.length - 1) {
        // When the current row is the last row, the minimum point value must be 0.
        points = 0
      } else if ((!points || points < prevVal + MINIMUM_SCHEME_VALUE_DIFFERENCE) && points !== 0) {
        /*
         * When the current row is NOT the last row, and the minimum point value is
         * either absent or is too close (higher value than 0.01 less than the
         * previous value), change the minimum point value to be one point more
         * than the minimum point value of the next-lower row.
         */
        points = parseInt(prevVal, 10) + 1
      }

      prevVal = points
      $row.find('.standard_value').val(I18n.n(points))
    }

    $list.each(function (idx) {
      const $prev = $list.eq(idx - 1)
      let min_score = 0
      if ($prev && $prev.length > 0) {
        min_score = numberHelper.parse($prev.find('.standard_value').val())
        if (Number.isNaN(Number(min_score))) {
          min_score = 0
        }
        $(this)
          .find('.edit_max_score')
          .text(`< ${I18n.n(min_score)}`)
      }
    })
    $list.filter(':first').find('.edit_max_score').text(I18n.n(100))
    $list.find('.max_score_cell').each(function () {
      if (!$(this).data('label')) {
        $(this).data('label', $(this).attr('aria-label'))
      }
      const label = $(this).data('label')
      $(this).attr('aria-label', `${label} ${$(this).find('.edit_max_score').text()}%`)
    })
  })
})
