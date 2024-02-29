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
import React from 'react'
import ReactDOM from 'react-dom'
import htmlEscape from '@instructure/html-escape'
import {truncateText} from '@canvas/util/TextHelper'
import round from '@canvas/round'
import numberHelper from '@canvas/i18n/numberHelper'
import '@canvas/jquery/jquery.instructure_forms' /* fillFormData */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/util/templateData'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import '@canvas/rails-flash-notifications'
import Rubric from '../react/Rubric'
import {fillAssessment, updateAssociationData} from '../react/helpers'

const I18n = useI18nScope('rubric_assessment')

// TODO: stop managing this in the view and get it out of the global scope submissions/show.html.erb
/* global rubricAssessment */
window.rubricAssessment = {
  init() {
    const $rubric_criterion_comments_dialog = $('#rubric_criterion_comments_dialog')

    $('.rubric')
      .on('click', '.rating', function (_event) {
        $(this)
          .parents('.criterion')
          .find('.criterion_points')
          .val($(this).find('.points').text())
          .change()
      })
      .on('click', '.long_description_link', function (event) {
        event.preventDefault()
        if (!$(this).parents('.rubric').hasClass('editing')) {
          const data = $(this)
              .parents('.criterion')
              .getTemplateData({textValues: ['long_description', 'description']}),
            is_learning_outcome = $(this)
              .parents('.criterion')
              .hasClass('learning_outcome_criterion')
          $('#rubric_long_description_dialog')
            .fillTemplateData({data, htmlValues: is_learning_outcome ? ['long_description'] : []})
            .find('.editing')
            .hide()
            .end()
            .find('.displaying')
            .show()
            .end()
            .dialog({
              title: I18n.t('Criterion Long Description'),
              width: 400,
              modal: true,
              zIndex: 1000,
            })
        }
      })
      .on('change', '.criterion .saved_custom_rating', function () {
        if ($(this).parents('.rubric').hasClass('assessing')) {
          const val = $(this).val()
          if (val && val.length > 0) {
            $(this).parents('.custom_ratings_entry').find('.custom_rating_field').val(val)
          }
        }
      })
      .on('click', '.criterion_comments_link', function (event) {
        event.preventDefault()
        const $rubric_criterion_comments_link = $(this)
        const $criterion = $(this).parents('.criterion')
        const comments = $criterion.getTemplateData({textValues: ['custom_rating']}).custom_rating
        const editing = $(this).parents('.rubric.assessing').length > 0
        const data = {
          criterion_comments: comments,
          criterion_description: $criterion.find('.description:first').text(),
        }

        $rubric_criterion_comments_dialog.data('current_rating', $criterion)
        $rubric_criterion_comments_dialog.fillTemplateData({data})
        $rubric_criterion_comments_dialog.fillFormData(data)
        $rubric_criterion_comments_dialog.find('.editing').showIf(editing)
        $rubric_criterion_comments_dialog.find('.displaying').showIf(!editing)
        $rubric_criterion_comments_dialog.dialog({
          title: I18n.t('Additional Comments'),
          width: 400,
          close() {
            $rubric_criterion_comments_link.focus()
          },
          modal: true,
          zIndex: 1000,
        })
        $rubric_criterion_comments_dialog.find('textarea.criterion_comments').focus()
      })
      // cant use a .delegate because up above when we delegate '.rating' 'click' it calls .change() and that doesnt bubble right so it doesen't get caught
      .find('.criterion_points')
      .on('keyup change blur', function (event) {
        const $obj = $(event.target)
        if ($obj.parents('.rubric').hasClass('assessing')) {
          let val = numberHelper.parse($obj.val())
          if (Number.isNaN(Number(val))) {
            val = null
          }
          const $criterion = $obj.parents('.criterion')
          $criterion.find('.rating.selected').removeClass('selected')
          if (val || val === 0) {
            $criterion.find('.criterion_description').addClass('completed')
            rubricAssessment.highlightCriterionScore($criterion, val)
          } else {
            $criterion.find('.criterion_description').removeClass('completed')
          }
          let total = 0
          $obj
            .parents('.rubric')
            .find('.criterion:visible:not(.ignore_criterion_for_scoring) .criterion_points')
            .each(function () {
              let criterionPoints = numberHelper.parse($(this).val(), 10)
              if (Number.isNaN(Number(criterionPoints))) {
                criterionPoints = 0
              }
              total += criterionPoints
            })
          total = window.rubricAssessment.roundAndFormat(total)
          $obj.parents('.rubric').find('.rubric_total').text(total)
        }
      })

    $('.rubric_summary').on('click', '.rating_comments_dialog_link', function (event) {
      event.preventDefault()
      const $rubric_rating_comments_link = $(this)
      const $criterion = $(this).parents('.criterion')
      const comments = $criterion.getTemplateData({textValues: ['rating_custom']}).rating_custom
      const data = {
        criterion_comments: comments,
        criterion_description: $criterion.find('.description_title:first').text(),
      }

      $rubric_criterion_comments_dialog.data('current_rating', $criterion)
      $rubric_criterion_comments_dialog.fillTemplateData({data})
      $rubric_criterion_comments_dialog.fillFormData(data)
      $rubric_criterion_comments_dialog.find('.editing').hide()
      $rubric_criterion_comments_dialog.find('.displaying').show()
      $rubric_criterion_comments_dialog.dialog({
        title: I18n.t('Additional Comments'),
        width: 400,
        close() {
          $rubric_rating_comments_link.focus()
        },
        modal: true,
        zIndex: 1000,
      })
      $rubric_criterion_comments_dialog.find('.criterion_description').focus()
    })

    $rubric_criterion_comments_dialog.find('.save_button').click(() => {
      const comments = $rubric_criterion_comments_dialog.find('textarea.criterion_comments').val(),
        $criterion = $rubric_criterion_comments_dialog.data('current_rating')
      if ($criterion) {
        $criterion.find('.custom_rating').text(comments)
        $criterion.find('.criterion_comments').toggleClass('empty', !comments)
      }
      $rubric_criterion_comments_dialog.dialog('close')
    })

    $rubric_criterion_comments_dialog.find('.cancel_button').click(_event => {
      $rubric_criterion_comments_dialog.dialog('close')
    })

    setInterval(rubricAssessment.sizeRatings, 2500)
  },

  checkScoreAdjustment: ($criterion, rating, rawData) => {
    const rawPoints = rawData[`rubric_assessment[criterion_${rating.criterion_id}][points]`]
    const points = rubricAssessment.roundAndFormat(rating.points)
    if (rawPoints > points) {
      const criterionDescription = htmlEscape($criterion.find('.description_title').text())
      $.flashWarning(
        I18n.t(
          'Extra credit not permitted on outcomes, ' +
            'score adjusted to maximum possible for %{outcome}',
          {outcome: criterionDescription}
        )
      )
    }
  },

  highlightCriterionScore($criterion, val) {
    $criterion.find('.rating').each(function () {
      const rating_val = numberHelper.parse($(this).find('.points').text())
      const use_range = $criterion.find('.criterion_use_range').prop('checked')
      if (rating_val === val) {
        $(this).addClass('selected')
      } else if (use_range) {
        const $nextRating = $(this).next('.rating')
        let min_value = 0
        if ($nextRating.find('.points').text()) {
          min_value = numberHelper.parse($nextRating.find('.points').text())
        }
        if (rating_val > val && min_value < val) {
          $(this).addClass('selected')
        }
      }
    })
  },

  sizeRatings() {
    const $visibleCriteria = $('.rubric .criterion:visible')
    if ($visibleCriteria.length) {
      const scrollTop = window.scrollY
      $('.rubric .criterion:visible').each(function () {
        const $this = $(this),
          $ratings = $this.find('.ratings:visible')
        if ($ratings.length) {
          const $ratingsContainers = $ratings.find('.rating .container').css('height', ''),
            maxHeight = Math.max(
              $ratings.height(),
              $this.find('.criterion_description .container').height()
            )
          // the -10 here is the padding on the .container.
          $ratingsContainers.css('height', maxHeight - 10 + 'px')
        }
      })
      $('html,body').scrollTop(scrollTop)
    }
  },

  // Ideally, we should investigate why criteriaAssessment id ends up being "null" string
  // Due to the complexity of the code, this method is used to handle the situation and to
  // test the change properly.
  //
  // For reference, see bug EVAL-1621
  getCriteriaAssessmentId(criteriaAssessmentId) {
    return ['null', null].includes(criteriaAssessmentId) ? undefined : criteriaAssessmentId
  },

  assessmentData($rubric) {
    $rubric = rubricAssessment.findRubric($rubric)
    const data = {}
    if (ENV.RUBRIC_ASSESSMENT.assessment_user_id || $rubric.find('.user_id').length > 0) {
      data['rubric_assessment[user_id]'] =
        ENV.RUBRIC_ASSESSMENT.assessment_user_id || $rubric.find('.user_id').text()
    } else {
      data['rubric_assessment[anonymous_id]'] =
        ENV.RUBRIC_ASSESSMENT.anonymous_id || $rubric.find('.anonymous_id').text()
    }
    data['rubric_assessment[assessment_type]'] =
      ENV.RUBRIC_ASSESSMENT.assessment_type || $rubric.find('.assessment_type').text()
    if (ENV.nonScoringRubrics && this.currentAssessment !== undefined) {
      const assessment = this.currentAssessment
      assessment.data.forEach(criteriaAssessment => {
        const pre = `rubric_assessment[criterion_${criteriaAssessment.criterion_id}]`
        const section = key => `${pre}${key}`
        const points = criteriaAssessment.points.value
        data[section('[rating_id]')] = rubricAssessment.getCriteriaAssessmentId(
          criteriaAssessment.id
        )
        data[section('[points]')] = !Number.isNaN(points) ? points : undefined
        data[section('[description]')] = criteriaAssessment.description
          ? criteriaAssessment.description
          : I18n.t('No Details')
        data[section('[comments]')] = criteriaAssessment.comments || ''
        data[section('[save_comment]')] =
          criteriaAssessment.saveCommentsForLater === true ? '1' : '0'
      })
    } else {
      $rubric.find('.criterion:not(.blank)').each(function () {
        const id = $(this).attr('id')
        const pre = 'rubric_assessment[' + id + ']'
        const points = numberHelper.parse($(this).find('.criterion_points').val())
        data[pre + '[points]'] = !Number.isNaN(Number(points)) ? points : undefined
        if ($(this).find('.rating.selected')) {
          data[pre + '[description]'] = $(this).find('.rating.selected .description').text()
          data[pre + '[comments]'] = $(this).find('.custom_rating').text()
        }
        if ($(this).find('.custom_rating_field:visible').length > 0) {
          data[pre + '[comments]'] = $(this).find('.custom_rating_field:visible').val()
          data[pre + '[save_comment]'] = $(this).find('.save_custom_rating').prop('checked')
            ? '1'
            : '0'
        }
      })
    }
    return data
  },

  findRubric($rubric) {
    if (!$rubric.hasClass('rubric')) {
      let $new_rubric = $rubric.closest('.rubric')
      if ($new_rubric.length === 0) {
        $new_rubric = $rubric.find('.rubric:first')
      }
      $rubric = $new_rubric
    }
    return $rubric
  },

  updateRubricAssociation($rubric, data) {
    const summary_data = data.summary_data
    if (ENV.nonScoringRubrics && this.currentAssessment !== undefined) {
      const assessment = this.currentAssessment
      updateAssociationData(this.currentAssociation, assessment)
    } else if (summary_data && summary_data.saved_comments) {
      for (const id in summary_data.saved_comments) {
        const comments = summary_data.saved_comments[id],
          $holder = $rubric
            .find('#criterion_' + id)
            .find('.saved_custom_rating_holder')
            .hide(),
          $saved_custom_rating = $holder.find('.saved_custom_rating')

        $saved_custom_rating.find('.comment').remove()
        $saved_custom_rating
          .empty()
          .append('<option value="">' + htmlEscape(I18n.t('[ Select ]')) + '</option>')
        for (const jdx in comments) {
          if (comments[jdx]) {
            $saved_custom_rating.append(
              '<option value="' +
                htmlEscape(comments[jdx]) +
                '">' +
                htmlEscape(truncateText(comments[jdx], {max: 50})) +
                '</option>'
            )
            $holder.show()
          }
        }
      }
    }
  },

  fillAssessment,

  populateNewRubric(container, assessment, rubricAssociation) {
    if (ENV.nonScoringRubrics && ENV.rubric) {
      const assessing = container.hasClass('assessing')
      const setCurrentAssessment = currentAssessment => {
        rubricAssessment.currentAssessment = currentAssessment
        render(currentAssessment)
      }

      const association = rubricAssessment.currentAssociation || rubricAssociation
      rubricAssessment.currentAssociation = association

      const render = currentAssessment => {
        ReactDOM.render(
          <Rubric
            allowExtraCredit={ENV.outcome_extra_credit_enabled}
            onAssessmentChange={assessing ? setCurrentAssessment : null}
            rubric={ENV.rubric}
            rubricAssessment={currentAssessment}
            customRatings={ENV.outcome_proficiency ? ENV.outcome_proficiency.ratings : []}
            rubricAssociation={rubricAssociation}
          >
            {null}
          </Rubric>,
          container.get(0)
        )
      }

      setCurrentAssessment(
        rubricAssessment.fillAssessment(ENV.rubric, assessment || {}, ENV.RUBRIC_ASSESSMENT)
      )
      const header = container.find('th').first()
      header.attr('tabindex', -1).focus()
    } else {
      rubricAssessment.populateRubric(container, assessment)
    }
  },

  populateRubric($rubric, data, submitted_data = null) {
    $rubric = rubricAssessment.findRubric($rubric)
    if (ENV.RUBRIC_ASSESSMENT.assessment_user_id || data.user_id) {
      $rubric.find('.user_id').text(ENV.RUBRIC_ASSESSMENT.assessment_user_id || data.user_id)
    } else {
      $rubric.find('.anonymous_id').text(ENV.RUBRIC_ASSESSMENT.anonymous_id || data.anonymous_id)
    }
    $rubric
      .find('.assessment_type')
      .text(ENV.RUBRIC_ASSESSMENT.assessment_type || data.assessment_type)

    $rubric
      .find('.criterion_description')
      .removeClass('completed')
      .removeClass('original_completed')
      .end()
      .find('.rating')
      .removeClass('selected')
      .removeClass('original_selected')
      .end()
      .find('.custom_rating_field')
      .val('')
      .end()
      .find('.custom_rating_comments')
      .text('')
      .end()
      .find('.criterion_points')
      .val('')
      .change()
      .end()
      .find('.criterion_rating_points')
      .text('')
      .end()
      .find('.custom_rating')
      .text('')
      .end()
      .find('.save_custom_rating')
      .prop('checked', false)
    $rubric.find('.criterion_comments').addClass('empty')
    if (data) {
      const assessment = data
      let total = 0
      for (const idx in assessment.data) {
        const rating = assessment.data[idx]
        const comments = rating.comments_enabled ? rating.comments : rating.description
        let comments_html
        if (rating.comments_enabled && rating.comments_html) {
          comments_html = rating.comments_html
        } else {
          comments_html = htmlEscape(comments)
        }
        const $criterion = $rubric.find('#criterion_' + rating.criterion_id)
        if (!rating.id) {
          $criterion.find('.rating').each(function () {
            const rating_val = parseFloat($(this).find('.points').text(), 10)
            if (rating_val == rating.points) {
              rating.id = $(this).find('.rating_id').text()
            }
          })
        }
        if (submitted_data && $criterion.hasClass('learning_outcome_criterion')) {
          rubricAssessment.checkScoreAdjustment($criterion, rating, submitted_data)
        }
        $criterion
          .find('.custom_rating_field')
          .val(comments)
          .end()
          .find('.custom_rating_comments')
          .html(comments_html)
          .end()
          .find('.criterion_points')
          .val(window.rubricAssessment.roundAndFormat(rating.points))
          .change()
          .end()
          .find('.criterion_rating_points_holder')
          .showIf(rating.points || rating.points === 0)
          .end()
          .find('.criterion_rating_points')
          .text(window.rubricAssessment.roundAndFormat(rating.points))
          .end()
          .find('.custom_rating')
          .text(comments)
          .end()
          .find('.criterion_comments')
          .toggleClass('empty', !comments)
          .end()
          .find('.save_custom_rating')
          .prop('checked', false)
        if (ratingHasScore(rating)) {
          $criterion
            .find('.criterion_description')
            .addClass('original_completed')
            .end()
            .find('#rating_' + rating.id)
            .addClass('original_selected')
            .addClass('selected')
            .end()
          rubricAssessment.highlightCriterionScore($criterion, rating.points)
          if (!rating.ignore_for_scoring) {
            total += rating.points
          }
        }
        if (comments) $criterion.find('.criterion_comments').show()
      }
      total = window.rubricAssessment.roundAndFormat(total)
      $rubric.find('.rubric_total').text(total)
    }
  },

  populateNewRubricSummary(container, assessment, rubricAssociation, editData) {
    const el = container.get(0)
    if (ENV.nonScoringRubrics && ENV.rubric) {
      ReactDOM.unmountComponentAtNode(el)
      if (assessment) {
        const filled = rubricAssessment.fillAssessment(
          ENV.rubric,
          assessment || {},
          ENV.RUBRIC_ASSESSMENT
        )
        ReactDOM.render(
          <Rubric
            customRatings={ENV.outcome_proficiency ? ENV.outcome_proficiency.ratings : []}
            rubric={ENV.rubric}
            rubricAssessment={filled}
            rubricAssociation={rubricAssociation}
            isSummary={true}
          >
            {null}
          </Rubric>,
          el
        )
      } else {
        el.innerHTML = ''
      }
    } else {
      rubricAssessment.populateRubricSummary(container, assessment, editData)
    }
  },

  populateRubricSummary($rubricSummary, data, editing_data) {
    $rubricSummary.find('.criterion_points').text('').end().find('.rating_custom').text('')

    if (data) {
      const assessment = data
      let total = 0
      let $criterion = null
      for (let idx = 0; idx < assessment.data.length; idx++) {
        const rating = assessment.data[idx]
        $criterion = $rubricSummary.find('#criterion_' + rating.criterion_id)
        if (editing_data && $criterion.hasClass('learning_outcome_criterion')) {
          rubricAssessment.checkScoreAdjustment($criterion, rating, editing_data)
        }
        $criterion
          .find('.rating')
          .hide()
          .end()
          .find('.rating_' + rating.id)
          .show()
          .end()
          .find('.criterion_points')
          .text(window.rubricAssessment.roundAndFormat(rating.points))
          .end()
          .find('.ignore_for_scoring')
          .showIf(rating.ignore_for_scoring)
        if (ratingHasScore(rating) && !$rubricSummary.hasClass('free_form')) {
          $criterion.find('.rating.description').show().text(rating.description).end()
        }
        if (rating.comments_enabled && rating.comments) {
          $criterion.find('.rating_custom').show().text(rating.comments)
        }
        if (rating.points && !rating.ignore_for_scoring) {
          total += rating.points
        }
      }
      total = window.rubricAssessment.roundAndFormat(total, round.DEFAULT)
      $rubricSummary.show().find('.rubric_total').text(total)
      $rubricSummary.closest('.edit').show()
    } else {
      $rubricSummary.hide()
    }
  },

  /**
   * Returns n rounded and formatted with I18n.n.
   * If n is null, undefined or empty string, empty string is returned.
   */
  roundAndFormat(n) {
    if (n == null || n === '') {
      return ''
    }

    return I18n.n(round(n, round.DEFAULT))
  },
}

function ratingHasScore(rating) {
  return rating.points || rating.points === 0
}

$(rubricAssessment.init)

export default rubricAssessment
