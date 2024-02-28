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
import {truncateText} from '@canvas/util/TextHelper'
import '@canvas/jquery/jquery.ajaxJSON'
import 'jqueryui/dialog'
import '@canvas/util/templateData'

const I18n = useI18nScope('find_outcome')
/* fillTemplateData, getTemplateData */

const find_outcome = (function () {
  return {
    find(callback, options) {
      options = options || {}
      find_outcome.callback = callback
      const $dialog = $('#find_outcome_criterion_dialog')
      if (!$dialog.hasClass('loaded')) {
        $dialog
          .find('.loading_message')
          .text(I18n.t('messages.loading_outcomes', 'Loading Outcomes...'))
        $.ajaxJSON(
          $dialog.find('.outcomes_list_url').attr('href'),
          'GET',
          {},
          data => {
            const valids = []
            for (const idx in data) {
              const outcome = data[idx].learning_outcome
              if (!options.for_rubric || (outcome.data && outcome.data.rubric_criterion)) {
                valids.push(outcome)
              }
            }
            if (valids.length === 0) {
              let message
              if (options.for_rubric) {
                message = I18n.t(
                  'messages.no_rubric_outcomes_found',
                  'No Rubric-Configured Outcomes found'
                )
              } else {
                message = I18n.t('messages.no_outcomes_found', 'No Outcomes found')
              }
              $dialog.find('.loading_message').text(message)
            } else {
              $dialog.find('.loading_message').hide()
              $dialog.addClass('loaded')
              for (const idx in valids) {
                const outcome = valids[idx]
                outcome.name = outcome.short_description
                outcome.mastery_points =
                  outcome.data.rubric_criterion.mastery_points ||
                  outcome.data.rubric_criterion.points_possible
                const $name = $dialog
                  .find('.outcomes_select.blank:first')
                  .clone(true)
                  .removeClass('blank')
                outcome.title = outcome.short_description
                const $text = $('<div/>')
                $text.text(outcome.short_description)
                outcome.title = truncateText($.trim($text.text()), {max: 35})
                outcome.display_name = outcome.cached_context_short_name || ''
                $name.fillTemplateData({data: outcome})
                $dialog.find('.outcomes_selects').append($name.show())
                const $outcome = $dialog
                  .find('.outcome.blank:first')
                  .clone(true)
                  .removeClass('blank')
                $outcome
                  .find('.mastery_level')
                  .attr('id', 'outcome_question_bank_mastery_' + outcome.id)
                  .end()
                  .find('.mastery_level_text')
                  .attr('for', 'outcome_question_bank_mastery_' + outcome.id)
                outcome.learning_outcome_id = outcome.id
                const criterion = outcome.data && outcome.data.rubric_criterion
                let pct =
                  (criterion.points_possible &&
                    criterion.mastery_points != null &&
                    criterion.mastery_points / criterion.points_possible) ||
                  0
                pct = Math.round(pct * 10000) / 100.0 || ''
                $outcome.find('.mastery_level').val(pct)
                $outcome.fillTemplateData({data: outcome, htmlValues: ['description']})
                $outcome.addClass('outcome_' + outcome.id)
                if (outcome.data && outcome.data.rubric_criterion) {
                  for (const jdx in outcome.data.rubric_criterion.ratings) {
                    const rating = outcome.data.rubric_criterion.ratings[jdx]
                    const $rating = $outcome.find('.rating.blank').clone(true).removeClass('blank')
                    $rating.fillTemplateData({data: rating})
                    $outcome.find('tr').append($rating.show())
                  }
                }
                $dialog.find('.outcomes_list').append($outcome)
              }
              $dialog.find('.outcomes_select:not(.blank):first').click()
            }
          },
          _data => {
            $dialog
              .find('.loading_message')
              .text(
                I18n.t(
                  'errors.outcome_retrieval_failed',
                  'Outcomes Retrieval failed unexpected.  Please try again.'
                )
              )
          }
        )
      }
      $dialog.dialog({
        modal: true,
        title: I18n.t('titles.find_outcome', 'Find Outcome'),
        width: 700,
        height: 400,
        zIndex: 1000,
      })
    },
  }
})()
window.find_outcome = find_outcome
$(document).ready(function () {
  $('#find_outcome_criterion_dialog .outcomes_select').click(function (event) {
    event.preventDefault()
    $('#find_outcome_criterion_dialog .outcomes_select.selected_side_tab').removeClass(
      'selected_side_tab'
    )
    $(this).addClass('selected_side_tab')
    const id = $(this).getTemplateData({textValues: ['id']}).id
    $('#find_outcome_criterion_dialog .outcomes_list .outcome').hide()
    $('#find_outcome_criterion_dialog .outcomes_list .outcome_' + id).show()
  })
  $('#find_outcome_criterion_dialog .select_outcome_link').click(function (event) {
    event.preventDefault()
    const $outcome = $(this).parents('.outcome')
    $('#find_outcome_criterion_dialog').dialog('close')
    if ($.isFunction(find_outcome.callback)) {
      find_outcome.callback($outcome)
    }
  })
})

export default find_outcome
