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
import calcCmd from './calcCmd'
import htmlEscape from '@instructure/html-escape'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* /\$\.raw/ */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import 'jqueryui/sortable'

const I18n = useI18nScope('calculator')

const generateFinds = function ($table) {
  const finds = {}
  finds.formula_rows = $table.find('.formula_row')
  finds.formula_rows.each(function (_i) {
    this.formula = $(this).find('.formula')
    this.status = $(this).find('.status')
    $(this).data('formula', $(this).find('.formula'))
    $(this).data('status', $(this).find('.status'))
  })
  finds.round = $table.find('.round')
  finds.status = $table.find('.status')
  finds.last_row_details = $table.find('.last_row_details')
  return finds
}
$.fn.superCalc = function (options, more_options) {
  if (options === 'recalculate') {
    $(this).triggerHandler('calculate', more_options)
  } else if (options === 'clear') {
    calcCmd.clearMemory()
  } else if (options === 'cache_finds') {
    $(this).data('cached_finds', generateFinds($(this).data('table')))
  } else if (options === 'clear_cached_finds') {
    $(this).data('cached_finds', null)
  } else {
    options = options || {}
    options.c1 = true
    const $entryBox = $(this)
    const $table = $(
      "<table class='formulas' aria-live='polite'>" +
        "<thead><tr><td id='headings.formula'>" +
        htmlEscape(I18n.t('headings.formula', 'Formula')) +
        "</td><td id='headings.result'>" +
        htmlEscape(I18n.t('headings.result', 'Result')) +
        "</td><td aria-hidden='true'>&nbsp;</td></tr></thead>" +
        '<tfoot>' +
        "<tr><td colspan='3' class='last_row_details' style='display: none;'>" +
        htmlEscape(
          I18n.t(
            'last_formula_row',
            'the last formula row will be used to compute the final answer'
          )
        ) +
        '</td></tr>' +
        "<tr><td></td><td class='decimal_places'>" +
        "<select aria-labelledby='decimal_places_label' class='round'><option>0</option><option>1</option><option>2</option><option>3</option><option>4</option></select> " +
        "<label id='decimal_places_label'>" +
        htmlEscape(I18n.t('decimal_places', 'Decimal Places')) +
        '</label>' +
        '</td></tr>' +
        '</tfoot>' +
        '<tbody></tbody>' +
        '</table>'
    )

    $entryBox.attr('aria-labelledby', 'headings.formula')
    $entryBox.css('width', '220px')
    $(this).data('table', $table)
    $entryBox.before($table)
    $table.find('tfoot tr:last td:first').append($entryBox)
    const $displayBox = $entryBox.clone(true).removeAttr('id')
    $table.find('tfoot tr:last td:first').append($displayBox)
    const $enter = $(
      "<button type='button' class='btn save_formula_button'>" +
        htmlEscape(I18n.t('buttons.save', 'Save')) +
        '</button>'
    )
    $table.find('tfoot tr:last td:first').append($enter)
    $entryBox.hide()
    const $input = $("<input type='text' readonly='true'/>")
    $table.find('tfoot tr:last td:first').append($input.hide())
    $entryBox.data('supercalc_options', options)
    $entryBox.data('supercalc_answer', $input)
    $table.on('click', '.save_formula_button', () => {
      $displayBox.triggerHandler('keypress', true)
    })
    $table.on('click', '.delete_formula_row_link', event => {
      event.preventDefault()
      $(event.target).parents('tr').remove()
      $entryBox.triggerHandler('calculate')
    })
    $table.find('tbody').sortable({
      items: '.formula_row',
      update() {
        $entryBox.triggerHandler('calculate')
      },
    })
    $table.on('change', '.round', () => {
      $entryBox.triggerHandler('calculate')
    })
    $entryBox.bind('calculate', function (event, no_dom) {
      calcCmd.clearMemory()
      const finds = $(this).data('cached_finds') || generateFinds($table)
      if (options.pre_process && $.isFunction(options.pre_process)) {
        const lines = options.pre_process()
        for (const idx in lines) {
          if (!no_dom) {
            $entryBox.val(lines[idx] || '')
          }
          try {
            calcCmd.compute(lines[idx])
          } catch (e) {
            // no-op
          }
        }
      }
      finds.formula_rows.each(function () {
        const formula_text = this.formula.html()
        $entryBox.val(formula_text)
        let res = null
        try {
          const val = calcCmd.computeValue(formula_text)
          // we'll round using decimals but because of javascript imprecision
          // let's truncate with 2 extra decimals
          const decimals = parseInt(finds.round.val() || 0, 10)
          const preresult = val.toFixed(decimals + 2)
          // then replace the last decimal with number 1
          res =
            '= ' +
            I18n.n(parseFloat(preresult.substr(0, preresult.length - 1) + '1').toFixed(decimals), {
              precision: 5,
              strip_insignificant_zeros: true,
            })
        } catch (e) {
          res = e.toString()
        }
        this.status.attr('data-res', res)
        if (!no_dom) {
          this.status.text(res)
        }
      })
      if (!no_dom) {
        if (finds.formula_rows.length > 1) {
          finds.formula_rows.removeClass('last_row').filter(':last').addClass('last_row')
        }
        finds.last_row_details.showIf(finds.formula_rows.length > 1)
        finds.status
          .removeAttr('title')
          .filter(':last')
          .attr(
            'title',
            I18n.t(
              'sample_final_answer',
              'This value is an example final answer for this question type'
            )
          )
        $entryBox.val('')
      }
    })
    $displayBox.bind('keypress', (event, enter) => {
      $entryBox.val($displayBox.val())
      if (event.keyCode === 13 || (enter && $displayBox.val())) {
        event.preventDefault()
        event.stopPropagation()
        const $tr = $(
          "<tr class='formula_row'><td class='formula' aria-labelledby='headings.formula' title='" +
            htmlEscape(I18n.t('drag_to_reorder', 'Drag to reorder')) +
            "'></td><td class='status' aria-labelledby='headings.result'></td><td><a href='#' class='delete_formula_row_link no-hover'><img src='/images/delete_circle.png' alt='" +
            htmlEscape(I18n.t('delete_formula', 'Delete Formula')) +
            "'/></a></td></tr>"
        )
        $tr.find('td:first').text($entryBox.val())
        $entryBox.val('')
        $displayBox.val('')
        $table.find('tbody').append($tr)
        $entryBox.triggerHandler('calculate')
        $displayBox.focus()
        if (options && options.formula_added && $.isFunction(options.formula_added)) {
          options.formula_added.call($entryBox)
        }
      }
    })
  }
}
