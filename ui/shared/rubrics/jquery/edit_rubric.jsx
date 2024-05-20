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

import React from 'react'
import ReactDOM from 'react-dom'
import RubricAddCriterionPopover from '../react/components/RubricAddCriterionPopover'
import RubricManagement from '../react/components/RubricManagement'
import {useScope as useI18nScope} from '@canvas/i18n'
import changePointsPossibleToMatchRubricDialog from '../jst/changePointsPossibleToMatchRubricDialog.handlebars'
import $ from 'jquery'
import {debounce} from 'lodash'
import htmlEscape from '@instructure/html-escape'
import numberHelper from '@canvas/i18n/numberHelper'
import '@canvas/outcomes/find_outcome'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms' /* formSubmit, fillFormData, getFormData */
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* confirmDelete, showIf */
import '@canvas/loading-image'
import '@canvas/util/templateData' /* fillTemplateData, getTemplateData */
import '@canvas/rails-flash-notifications'
import 'jquery-tinypubsub'
import 'jquery-scroll-to-visible/jquery.scrollTo'
import '@canvas/util/jquery/fixDialogButtons'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('edit_rubric')

const rubricEditing = {
  htmlBody: null,
  hidePoints: (...args) => {
    args.forEach($el => {
      $el.find('.toggle_for_hide_points').addClass('hidden')
    })
  },
  showPoints: (...args) => {
    args.forEach($el => {
      $el.find('.toggle_for_hide_points').removeClass('hidden')
    })
  },
  localizedPoints(points) {
    return I18n.n(points, {precision: 2, strip_insignificant_zeros: true})
  },
  updateCriteria($rubric) {
    $rubric.find('.criterion:not(.blank)').each(function (i) {
      $(this).attr('id', 'criterion_' + (i + 1))
    })
  },
  updateAddCriterionLinks($rubric, focusTarget = null) {
    if (!$rubric.is(':visible') || $rubric.find('#add_criterion_holder').length === 0) {
      return
    }
    $('#add_criterion_container').remove()
    $rubric.find('#add_criterion_holder').append($('<span/>').attr('id', 'add_criterion_container'))
    setTimeout(() => {
      ReactDOM.render(
        <RubricAddCriterionPopover
          rubric={$rubric}
          duplicateFunction={rubricEditing.copyCriterion}
        />,
        document.getElementById('add_criterion_container')
      )
      if (focusTarget) {
        $rubric.find(`#add_criterion_container ${focusTarget}:visible`).focus()
      }
    }, 0)
  },
  copyCriterion($rubric, criterion_index) {
    const $criterion = rubricEditing.addCriterion($rubric, criterion_index)
    $criterion.removeClass('new_criterion')
    $criterion.find('.criterion_id').text('blank')
    $criterion.find('.rating_id').text('blank')
    rubricEditing.editCriterion($criterion)
  },
  addCriterion($rubric, criterion_index) {
    let $blank
    if (typeof criterion_index !== 'undefined') {
      $blank = $rubric.find(`.criterion:not(.blank):eq(${criterion_index})`)
    } else {
      $blank = $rubric.find('.criterion.blank:first')
    }
    const $criterion = $blank.clone(true)
    $criterion.addClass('new_criterion')
    $criterion.removeClass('blank')
    $rubric.find('.summary').before($criterion.show())
    const focusTarget = $criterion.hasClass('learning_outcome_criterion') ? '.icon-plus' : null
    rubricEditing.updateCriteria($rubric)
    rubricEditing.sizeRatings($criterion)
    rubricEditing.updateAddCriterionLinks($rubric, focusTarget)
    return $criterion
  },
  addNewRatingColumn($this) {
    const $rubric = $this.parents('.rubric')
    $this.addClass('add_column')
    if ($rubric.hasClass('editing')) {
      const $td = $this.clone(true).removeClass('edge_rating'),
        pts = numberHelper.parse($this.find('.points').text()),
        $criterion = $this.parents('.criterion'),
        data = {description: '', rating_long_description: '', min_points: pts},
        hasClassAddLeft = $this.hasClass('add_left')
      if ($this.hasClass('add_left')) {
        const more_points = numberHelper.parse($this.prev('.rating').find('.points').text())
        data.points = Math.round((pts + more_points) / 2)
        if (data.points === pts || data.points === more_points) {
          data.points = pts
        }
      } else {
        const less_points = numberHelper.parse($this.next('.rating').find('.points').text())
        data.min_points = less_points
        data.points = Math.round((pts + less_points) / 2)
        if (data.points === pts || data.points === less_points) {
          data.points = less_points
        }
      }
      $td.fillTemplateData({
        data: {
          ...data,
          min_points: rubricEditing.localizedPoints(data.min_points),
          points: rubricEditing.localizedPoints(data.points),
        },
      })
      rubricEditing.flagInfinitesimalRating(
        $td,
        $criterion.find('.criterion_use_range').prop('checked')
      )
      if (hasClassAddLeft) {
        $this.before($td)
      } else {
        $td.addClass('new_rating')
        $this.after($td)
      }
      const $previousRating = $td.prev('.rating')
      if ($previousRating) {
        $previousRating.fillTemplateData({data: {min_points: data.points}})
      }
      rubricEditing.hideCriterionAdd($rubric)
      rubricEditing.updateCriterionPoints($criterion, true)
      rubricEditing.sizeRatings($criterion)
      setTimeout(() => {
        $.screenReaderFlashMessageExclusive(I18n.t('New Rating Created'))
        $('.new_rating').find('.edit_rating_link').click()
      }, 100)
    }
  },
  preventDuplicatedOutcome(outcome) {
    const rubric = $('#add_learning_outcome_link').closest('.rubric')
    const data = rubricEditing.rubricData(rubric)
    const id_list = Object.keys(data)
      .filter(k => /learning_outcome_id/.test(k))
      .map(k => data[k])

    if (id_list.includes(outcome.id)) {
      showFlashAlert({
        type: 'error',
        message: I18n.t(
          'rubric.import_outcome.duplicated_outcome',
          'This Outcome has not been added as it already exists in this rubric.'
        ),
      })

      return true
    }

    return false
  },
  onFindOutcome(outcome) {
    if (rubricEditing.preventDuplicatedOutcome(outcome)) {
      return
    }

    // multiple rubrics can be open for editing but only the active one will have Find Outcome link
    const $rubric = $('#add_learning_outcome_link').closest('.rubric table.rubric_table:visible')
    $rubric
      .find('.criterion.learning_outcome_' + outcome.id)
      .find('.delete_criterion_link')
      .click()
    rubricEditing.addCriterion($rubric)

    const $criterion = $rubric.find('.criterion:not(.blank):last')
    $criterion.removeClass('new_criterion')
    $criterion.toggleClass('ignore_criterion_for_scoring', !outcome.useForScoring)
    $criterion.find('.mastery_points').val(outcome.get('mastery_points'))
    $criterion.addClass('learning_outcome_criterion')
    $criterion.find('.outcome_sr_content').attr('aria-hidden', false)
    $criterion.find('.learning_outcome_id').text(outcome.id)
    $criterion.find('.hide_when_learning_outcome').hide()
    $criterion.find('.criterion_points').val(outcome.get('ratings')[0].points).blur()

    for (let i = 0; i < outcome.get('ratings').length - 2; i++) {
      $criterion.find('.rating:not(.blank):first').addClass('add_column').click()
    }

    $criterion.find('.rating:not(.blank)').each(function (i) {
      const rating = outcome.get('ratings')[i]
      $(this).fillTemplateData({data: rating})
    })

    $criterion.find('.cancel_button').click()
    const tmpEl = document.createElement('div')
    tmpEl.innerHTML = outcome.get('description')
    const outcomeDescription = tmpEl.textContent || tmpEl.innerText || ''
    $criterion.find('div.long_description').text(outcomeDescription)
    $criterion.find('.long_description_holder').toggleClass('empty', !outcome.get('description'))

    $criterion.find('.description_title').text(outcome.get('title'))
    $criterion.find('.criterion_description').val(outcome.get('title')).focus().select()

    $criterion.find('.mastery_points').text(outcome.get('mastery_points'))
    $criterion.find('.edit_criterion_link').remove()
    $criterion.find('.rating .links').remove()
    rubricEditing.updateAddCriterionLinks($rubric, '.icon-search')
    $criterion.find('.long_description_holder').show()
  },
  hideCriterionAdd($rubric) {
    $rubric.find('.add_right, .add_left, .add_column').removeClass('add_left add_right add_column')
  },
  updateRubricPoints($rubric) {
    let total = 0
    $rubric
      .find('.criterion:not(.blank):not(.ignore_criterion_for_scoring) .criterion_points')
      .each(function () {
        const points = numberHelper.parse($(this).val())
        if (!Number.isNaN(points)) {
          total += points
        }
      })
    total = round(total, 2)
    $rubric.find('.rubric_total').text(rubricEditing.localizedPoints(total))
  },
  updateCriterionPoints($criterion, baseOnRatings) {
    const ratings = $.makeArray($criterion.find('.rating')).reverse()
    let rating_points = -1
    let points = numberHelper.parse($criterion.find('.criterion_points').val())
    const use_range = $criterion.find('.criterion_use_range').prop('checked')
    if (Number.isNaN(points)) {
      points = 5
    } else {
      points = round(points, 2)
    }
    $criterion.find('.rating:first .points').text(rubricEditing.localizedPoints(points))
    // From right to left, make sure points never decrease
    // and round to 2 decimal places.
    $.each(ratings, (i, rating) => {
      const $rating = $(rating)
      const data = $rating.getTemplateData({textValues: ['points']})
      data.points = numberHelper.parse(data.points)
      if (data.points < rating_points) {
        data.points = rating_points
      }
      data.points = round(data.points, 2)
      rating_points = data.points
      data.points = rubricEditing.localizedPoints(data.points)
      $rating.fillTemplateData({data})
      rubricEditing.flagInfinitesimalRating($rating, use_range)
    })
    if (baseOnRatings && rating_points > points) {
      points = rating_points
    }
    $criterion.find('.criterion_points').val(rubricEditing.localizedPoints(points))
    $criterion.find('.display_criterion_points').text(rubricEditing.localizedPoints(points))
    if (
      !$criterion.data('criterion_points') ||
      numberHelper.parse($criterion.data('criterion_points')) !== points
    ) {
      if (!$criterion.data('criterion_points')) {
        let max = $criterion.find('.criterion_points').prop('defaultValue')
        if (baseOnRatings) {
          max = $criterion.find('.rating:first .points').text()
        }
        $criterion.data('criterion_points', numberHelper.parse(max))
      }
      const oldMax = $criterion.data('criterion_points')
      const newMax = points

      const $ratingList = $criterion.find('.rating')
      $($ratingList[0]).find('.points').text(rubricEditing.localizedPoints(points))
      let lastPts = points
      // From left to right, scale points proportionally to new range.
      // So if originally they were 3,2,1 and now we increased the
      // total possible to 9, they'd be 9,6,3
      for (let i = 1; i < $ratingList.length; i++) {
        const pts = numberHelper.parse($($ratingList[i]).find('.points').text())
        let newPts = (pts / oldMax) * newMax
        // if an element between [1, length - 1]
        // is adjusting up from 0, evenly divide it within the range
        if (Number.isNaN(pts) || (pts === 0 && lastPts > 0 && i < $ratingList.length - 1)) {
          newPts = lastPts - Math.round(lastPts / ($ratingList.length - i))
        }
        if (Number.isNaN(newPts)) {
          newPts = 0
        } else if (newPts > lastPts) {
          newPts = lastPts - 1
        }
        newPts = rubricEditing.localizedPoints(Math.max(0, newPts))
        lastPts = newPts
        $($ratingList[i]).find('.points').text(newPts)
        rubricEditing.flagInfinitesimalRating($($ratingList[i]), use_range)
        if (i > 0) {
          $($ratingList[i - 1])
            .find('.min_points')
            .text(newPts)
          rubricEditing.flagInfinitesimalRating($($ratingList[i - 1]), use_range)
        }
      }
      $criterion.data('criterion_points', numberHelper.parse(points))
    }
    rubricEditing.updateRubricPoints($criterion.parents('.rubric'))
  },
  flagInfinitesimalRating($rating, use_range) {
    const data = $rating.getTemplateData({textValues: ['points', 'min_points']})
    if (numberHelper.parse(data.min_points) === numberHelper.parse(data.points)) {
      $rating.addClass('infinitesimal')
      $rating.find('.range_rating').hide()
    } else {
      $rating.removeClass('infinitesimal')
      $rating.find('.range_rating').showIf(use_range)
    }
  },
  capPointChange(points, $neighbor, action, compare_target) {
    const data = $neighbor.getTemplateData({textValues: [compare_target]})
    return rubricEditing.localizedPoints(action(points, numberHelper.parse(data[compare_target])))
  },
  editCriterion($criterion) {
    if (!$criterion.parents('.rubric').hasClass('editing')) {
      return
    }
    if ($criterion.hasClass('learning_outcome_criterion')) {
      return
    }
    $criterion.find('.edit_criterion_link').click()
  },
  originalSizeRatings() {
    const $visibleCriteria = $('.rubric:not(.rubric_summary) .criterion:visible')
    if ($visibleCriteria.length) {
      const scrollTop = window.scrollY
      $visibleCriteria.each(function () {
        const $this = $(this),
          $ratings = $this.find('.ratings:visible')
        if ($ratings.length) {
          const $ratingsContainers = $ratings.find('.rating .container').css('height', ''),
            maxHeight = Math.max(
              $ratings.height(),
              $this.find('.criterion_description .container .description_content').height()
            )
          // the -10 here is the padding on the .container.
          $ratingsContainers.css('height', maxHeight - 10 + 'px')
        }
      })
      rubricEditing.htmlBody.scrollTop(scrollTop)
    }
  },

  rubricData($rubric) {
    $rubric = $rubric.filter(':first')
    if (!$rubric.hasClass('editing')) {
      $rubric = $rubric.next('.editing')
    }
    $rubric.find('.criterion_points').each(function () {
      const val = $(this).val()
      $(this).parents('.criterion').find('.display_criterion_points').text(val)
    })
    let vals = $rubric.getFormData()
    $rubric.find('.rubric_title .title').text(vals.title)
    $rubric.find('.rubric_table caption .title').text(vals.title)
    vals = $rubric.getTemplateData({
      textValues: ['title', 'description', 'rubric_total', 'rubric_association_id'],
    })
    let data = {}
    data['rubric[title]'] = vals.title
    data['rubric[points_possible]'] = vals.rubric_total
    data['rubric_association[use_for_grading]'] = $rubric
      .find('.grading_rubric_checkbox')
      .prop('checked')
      ? '1'
      : '0'
    data['rubric_association[hide_score_total]'] = '0'
    if (data['rubric_association[use_for_grading]'] === '0') {
      data['rubric_association[hide_score_total]'] = $rubric
        .find('.totalling_rubric_checkbox')
        .prop('checked')
        ? '1'
        : '0'
    }
    data['rubric_association[hide_points]'] = $rubric.find('.hide_points_checkbox').prop('checked')
      ? '1'
      : '0'
    data['rubric_association[hide_outcome_results]'] = $rubric
      .find('.hide_outcome_results_checkbox')
      .prop('checked')
      ? '1'
      : '0'
    data['rubric[free_form_criterion_comments]'] = $rubric
      .find('.rubric_custom_rating')
      .prop('checked')
      ? '1'
      : '0'
    data['rubric_association[id]'] = vals.rubric_association_id
    // make sure the association is always updated, see the comment on
    // RubricsController#update
    data.rubric_association_id = vals.rubric_association_id
    let criterion_idx = 0
    $rubric.find('.criterion:not(.blank)').each(function () {
      const $criterion = $(this)
      const use_range = !!$criterion.find('.criterion_use_range').prop('checked')
      if (!$criterion.hasClass('learning_outcome_criterion')) {
        const masteryPoints = $criterion.find('input.mastery_points').val()
        $criterion
          .find('span.mastery_points')
          .text(numberHelper.validate(masteryPoints) ? masteryPoints : 0)
      }
      const vals = $criterion.getTemplateData({
        textValues: [
          'description',
          'display_criterion_points',
          'learning_outcome_id',
          'mastery_points',
          'long_description',
          'criterion_id',
        ],
      })
      if ($criterion.hasClass('learning_outcome_criterion')) {
        vals.long_description = $criterion.find('div.long_description').val()
      }
      vals.mastery_points = $criterion.find('span.mastery_points').text()
      const pre_criterion = 'rubric[criteria][' + criterion_idx + ']'
      data[pre_criterion + '[description]'] = vals.description
      data[pre_criterion + '[points]'] = vals.display_criterion_points
      data[pre_criterion + '[learning_outcome_id]'] = vals.learning_outcome_id
      data[pre_criterion + '[long_description]'] = vals.long_description
      data[pre_criterion + '[id]'] = vals.criterion_id
      data[pre_criterion + '[criterion_use_range]'] = use_range
      if ($criterion.hasClass('ignore_criterion_for_scoring')) {
        data[pre_criterion + '[ignore_for_scoring]'] = '1'
      }
      if (vals.learning_outcome_id) {
        data[pre_criterion + '[mastery_points]'] = vals.mastery_points
      }
      let rating_idx = 0
      $criterion.find('.rating').each(function () {
        const $rating = $(this)
        const rating_vals = $rating.getTemplateData({
          textValues: ['description', 'rating_long_description', 'points', 'rating_id'],
        })
        const pre_rating = pre_criterion + '[ratings][' + rating_idx + ']'
        data[pre_rating + '[description]'] = rating_vals.description
        data[pre_rating + '[long_description]'] = rating_vals.rating_long_description
        data[pre_rating + '[points]'] = numberHelper.parse(rating_vals.points)
        data[pre_rating + '[id]'] = rating_vals.rating_id
        rating_idx++
      })
      criterion_idx++
    })
    data.title = data['rubric[title]']
    data.points_possible = numberHelper.parse(data['rubric[points_possible]'])

    data.rubric_id = $rubric.attr('id') ? $rubric.attr('id').substring(7) : undefined
    data = $.extend(data, $('#rubrics #rubric_parameters').getFormData())
    return data
  },
  addRubric() {
    const $rubric = $('#default_rubric').clone(true).attr('id', 'rubric_new').addClass('editing')
    $rubric.find('.edit_rubric').remove()
    const $tr = $('#edit_rubric').clone(true).show().removeAttr('id').addClass('edit_rubric')
    const $form = $tr.find('#edit_rubric_form')
    $rubric.find('.rubric_table').append($tr)
    $form.attr('method', 'POST').attr('action', $('#add_rubric_url').attr('href'))
    // I believe this should only be visible on the assignment page (not
    // rubric page or quiz page) but we need to audit uses of the add rubric
    // dialog before we make it that restrictive
    const $assignPoints = $(
      '#assignment_show, #assignment_show .points_possible,#rubrics.rubric_dialog .assignment_points_possible'
    )
    const $quizPage = $('#quiz_show,#quiz_edit_wrapper')
    $form.find('.rubric_grading').showIf($assignPoints.length > 0 && $quizPage.length === 0)
    return $rubric
  },
  updateMasteryScale($rubric) {
    if (!ENV.MASTERY_SCALE?.outcome_proficiency) {
      return
    }
    const mastery_scale = ENV.MASTERY_SCALE.outcome_proficiency.ratings
    const mastery_points = mastery_scale.find(r => r.mastery).points
    const points_possible = mastery_scale[0].points
    $rubric.find('.criterion:not(.blank)').each(function () {
      const $criterion = $(this)
      if (!$criterion.hasClass('learning_outcome_criterion')) {
        return
      }

      $criterion.find('.criterion_points').val(points_possible).blur()
      $criterion.find('.mastery_points').text(mastery_points)

      const old_ratings = $criterion.find('.rating:not(.blank)')
      if (old_ratings.length < mastery_scale.length) {
        for (let i = old_ratings.length; i < mastery_scale.length; i++) {
          $criterion.find('.rating:not(.blank):first').addClass('add_column').click()
        }
      }

      $criterion.find('.rating:not(.blank)').each(function (i) {
        const rating = ENV.MASTERY_SCALE.outcome_proficiency.ratings[i]
        if (!rating) {
          $(this).remove()
        } else {
          $(this).fillTemplateData({data: rating})
        }
      })
    })
  },
  editRubric($original_rubric, url, useMasteryScale = false) {
    $('#add_criterion_container').remove()
    rubricEditing.isEditing = true

    const $rubric = $original_rubric.clone(true).addClass('editing')
    $rubric.find('.edit_rubric').remove()

    const data = $rubric.getTemplateData({
      textValues: [
        'use_for_grading',
        'free_form_criterion_comments',
        'hide_score_total',
        'hide_points',
        'hide_outcome_results',
      ],
    })
    $original_rubric.hide().after($rubric.show())

    if (useMasteryScale) {
      rubricEditing.updateMasteryScale($rubric)
    }

    const $tr = $('#edit_rubric').clone(true).show().removeAttr('id').addClass('edit_rubric')
    const $form = $tr.find('#edit_rubric_form')
    $rubric.find('.rubric_table').append($tr)

    $rubric.find(':text:first').focus().select()
    $form
      .find('.grading_rubric_checkbox')
      .prop('checked', data.use_for_grading === 'true')
      .triggerHandler('change')
    $form
      .find('.rubric_custom_rating')
      .prop('checked', data.free_form_criterion_comments === 'true')
      .triggerHandler('change')
    $form
      .find('.totalling_rubric_checkbox')
      .prop('checked', data.hide_score_total === 'true')
      .triggerHandler('change')
    $form
      .find('.hide_points_checkbox')
      .prop('checked', data.hide_points === 'true')
      .triggerHandler('change')
    $form
      .find('.hide_outcome_results_checkbox')
      .prop('checked', data.hide_outcome_results === 'true')
      .triggerHandler('change')
    const createText = I18n.t('buttons.create_rubric', 'Create Rubric')
    const updateText = I18n.t('buttons.update_rubric', 'Update Rubric')
    $form.find('.save_button').text($rubric.attr('id') === 'rubric_new' ? createText : updateText)
    $form.attr('method', 'PUT').attr('action', url)
    rubricEditing.sizeRatings()
    rubricEditing.updateAddCriterionLinks($rubric)

    return $rubric
  },
  hideEditRubric($rubric, remove) {
    rubricEditing.isEditing = false
    $rubric = $rubric.filter(':first')
    if (!$rubric.hasClass('editing')) {
      $rubric = $rubric.next('.editing')
    }
    $rubric.removeClass('editing')
    $rubric.find('.edit_rubric').remove()
    if (remove) {
      if ($rubric.attr('id') !== 'rubric_new') {
        const $display_rubric = $rubric.prev('.rubric')
        $display_rubric.show()
        $display_rubric.find('.rubric_title .title').focus()
      } else {
        $('.add_rubric_link').show().focus()
      }
      $rubric.remove()
    } else {
      $rubric.find('.rubric_title .links').show()
    }
  },
  updateRubric($rubric, rubric) {
    $rubric.find('.criterion:not(.blank)').remove()
    const $rating_template = $rubric.find('.rating:first').clone(true).removeAttr('id')
    $rubric.fillTemplateData({
      data: rubric,
      id: 'rubric_' + rubric.id,
      hrefValues: ['id', 'rubric_association_id'],
      avoid: '.criterion',
    })
    $rubric.fillFormData(rubric)
    rubricEditing.isEditing = false

    let url = replaceTags($rubric.find('.edit_rubric_url').attr('href'), 'rubric_id', rubric.id)
    $rubric
      .find('.edit_rubric_link')
      .attr('href', url)
      .showIf(rubric.permissions.update_association)

    url = replaceTags(
      $rubric.find('.delete_rubric_url').attr('href'),
      'association_id',
      rubric.rubric_association_id
    )
    $rubric
      .find('.delete_rubric_link')
      .attr('href', url)
      .showIf(rubric.permissions.delete_association)

    $rubric
      .find('.find_rubric_link')
      .showIf(rubric.permissions.update_association && !$('#rubrics').hasClass('raw_listing'))

    $rubric.find('.criterion:not(.blank) .ratings').empty()
    rubric.criteria.forEach(criterion => {
      criterion.display_criterion_points = rubricEditing.localizedPoints(criterion.points)
      criterion.criterion_id = criterion.id
      const $criterion = $rubric.find('.criterion.blank:first').clone(true).show().removeAttr('id')
      $criterion.removeClass('blank')
      $criterion.fillTemplateData({data: criterion, htmlValues: ['long_description']})
      $criterion.find('.long_description_holder').toggleClass('empty', !criterion.long_description)
      $criterion
        .find('.criterion_use_range')
        .prop('checked', criterion.criterion_use_range === true)
      $criterion.find('.ratings').empty()
      $criterion.find('.hide_when_learning_outcome').showIf(!criterion.learning_outcome_id)
      $criterion.toggleClass('learning_outcome_criterion', !!criterion.learning_outcome_id)
      $criterion.toggleClass('ignore_criterion_for_scoring', !!criterion.ignore_for_scoring)
      $criterion.find('.outcome_sr_content').attr('aria-hidden', !criterion.learning_outcome_id)
      if (criterion.learning_outcome_id) {
        $criterion.find('.long_description_holder').show()
        if (criterion.long_description) {
          $criterion.find('.long_description_link').removeClass('hidden')
        }
      }
      let count = 0
      criterion.ratings.forEach(rating => {
        count++
        rating.rating_id = rating.id
        rating.rating_long_description = rating.long_description
        rating.min_points = 0
        if (count < criterion.ratings.length) {
          rating.min_points = criterion.ratings[count].points
        }
        const $rating = $rating_template.clone(true)
        $rating.toggleClass('edge_rating', count === 1 || count === criterion.ratings.length)
        if (count === criterion.ratings.length) {
          $rating.find('.add_rating_link').remove()
        }
        $rating.fillTemplateData({
          data: {
            ...rating,
            min_points: rubricEditing.localizedPoints(rating.min_points),
            points: rubricEditing.localizedPoints(rating.points),
          },
        })
        $rating
          .find('.range_rating')
          .showIf(
            criterion.criterion_use_range === true &&
              numberHelper.parse(rating.min_points) !== numberHelper.parse(rating.points)
          )
        $criterion.find('.ratings').append($rating)
      })
      if (criterion.learning_outcome_id) {
        $criterion.find('.edit_criterion_link').remove()
        $criterion.find('.rating .links').remove()
      }
      $rubric.find('.summary').before($criterion)
      $criterion.find('.criterion_points').val(rubricEditing.localizedPoints(criterion.points))
      $criterion.data('criterion_points', numberHelper.parse(criterion.points))
    })
    $rubric
      .find('.criterion:not(.blank)')
      .find('.ratings')
      .showIf(!rubric.free_form_criterion_comments)
      .end()
      .find('.custom_ratings')
      .showIf(rubric.free_form_criterion_comments)
    $rubric.find('.rubric_title .title').focus()
  },
}
rubricEditing.sizeRatings = debounce(rubricEditing.originalSizeRatings, 10)

const round = function (number, precision) {
  precision = Math.pow(10, precision || 0).toFixed(precision < 0 ? -precision : 0)
  return Math.round(number * precision) / precision
}

rubricEditing.init = function () {
  const limitToOneRubric = !$('#rubrics').hasClass('raw_listing')
  const $rubric_dialog = $('#rubric_dialog'),
    $rubric_long_description_dialog = $('#rubric_long_description_dialog'),
    $rubric_rating_dialog = $('#rubric_rating_dialog')

  rubricEditing.htmlBody = $('html,body')

  $('#rubrics')
    .on('click', '.edit_criterion_link, .long_description_link', function (event) {
      event.preventDefault()
      let title = I18n.t('Edit Criterion')
      const editing = $(this).parents('.rubric').hasClass('editing'),
        $criterion = $(this).parents('.criterion'),
        isLearningOutcome = $(this).parents('.criterion').hasClass('learning_outcome_criterion'),
        data = $criterion.getTemplateData({textValues: ['long_description', 'description']})

      if (editing && !isLearningOutcome) {
        // Override the default description if this is a new criterion.
        if ($criterion.hasClass('new_criterion')) {
          data.description = ''
          title = I18n.t('Add Criterion')
          $rubric_long_description_dialog.find('.save_button').text(I18n.t('Create Criterion'))
        } else {
          $rubric_long_description_dialog.find('.save_button').text(I18n.t('Update Criterion'))
        }
        $rubric_long_description_dialog
          .fillFormData(data)
          .fillTemplateData({data})
          .hideErrors()
          .find('.editing')
          .show()
          .end()
          .find('.displaying')
          .hide()
          .end()
      } else {
        if (!isLearningOutcome) {
          // We want to prevent XSS in this dialog but users expect to have line
          // breaks preserved when they view the long description. Previously we
          // were letting fillTemplateData do the htmlEscape dance but that
          // wouldn't let us preserve the line breaks because it munged the <br>
          // tags we were inserting.
          //
          // Finally, we're not making any changes in the case of this being a
          // learning outcome criterion because they come from elsewhere in the
          // app and may have legitimate markup in the text (at least according
          // to the tests that broke while putting this together).
          data.long_description = htmlEscape(data.long_description).replace(/(\r?\n)/g, '<br>$1')
        }
        title = I18n.t('Criterion Long Description')
        $rubric_long_description_dialog
          .fillTemplateData({
            data,
            htmlValues: ['description', 'long_description'],
            avoid: 'textarea',
          })
          .find('.displaying')
          .show()
          .end()
          .find('.editing')
          .hide()
          .end()
      }

      const closeFunction = function () {
        // If the criterion is still in the new state (user either canceled or closed dialog)
        // delete the criterion.
        if ($criterion.hasClass('new_criterion')) {
          setTimeout(() => {
            $.screenReaderFlashMessageExclusive(I18n.t('New Criterion Canceled'))
          }, 100)
          $criterion.find('.delete_criterion_link').click()
        }
      }

      const beforeCloseFunction = function () {
        if ($criterion.hasClass('new_criterion')) {
          $criterion
            .parents('.rubric_container')
            .first()
            .find('#add_criterion_container .icon-plus')
            .focus()
        } else {
          $criterion.find('.edit_criterion_link').focus()
        }
      }

      $rubric_long_description_dialog.data('current_criterion', $criterion).dialog({
        title,
        width: 416,
        buttons: [],
        close: closeFunction,
        beforeClose: beforeCloseFunction,
        modal: true,
        zIndex: 1000,
      })

      if (editing && !isLearningOutcome) {
        $rubric_long_description_dialog.fixDialogButtons()
      }
    })
    .on('click', '.edit_rating_link', function (event) {
      event.preventDefault()
      const $criterion = $(this).parents('.criterion')
      const $rating = $(this).parents('.rating')
      const data = $rating.getTemplateData({
        textValues: ['description', 'points', 'min_points', 'rating_long_description'],
      })
      const criterion_data = $criterion.getTemplateData({textValues: ['description']})

      if (!$rating.parents('.rubric').hasClass('editing')) {
        return
      }
      if ($rating.parents('.criterion').hasClass('learning_outcome_criterion')) {
        return
      }
      const $nextRating = $rating.closest('td').next('.rating')
      const use_range = $rating.parents('.criterion').find('.criterion_use_range').prop('checked')
      $rubric_rating_dialog.find('.range_rating').showIf(use_range)
      $rubric_rating_dialog.find('.min_points').prop('disabled', !$nextRating.length)
      rubricEditing.hideCriterionAdd($rating.parents('.rubric'))
      $rubric_rating_dialog
        .find('#edit_rating_form_criterion_description')
        .text(criterion_data.description)
      const points_element = $rubric_rating_dialog.find('#points')
      if (use_range) {
        points_element.attr('aria-labelledby', 'rating_form_max_score_label')
        points_element.attr('placeholder', I18n.t('max'))
      } else {
        points_element.attr('aria-labelledby', 'rating_form_score_label')
        points_element.removeAttr('placeholder')
      }
      const close_function = function () {
        const $current_rating = $rubric_rating_dialog.data('current_rating')
        // If the rating is still in the new state (user either canceled or closed dialog)
        // delete the rating.
        if ($current_rating.hasClass('new_rating')) {
          setTimeout(() => {
            $.screenReaderFlashMessageExclusive(I18n.t('New Rating Canceled'))
          }, 100)
          $current_rating.find('.delete_rating_link').click()
        }
      }
      $rubric_rating_dialog
        .fillFormData(data)
        .find('.editing')
        .show()
        .end()
        .find('.displaying')
        .hide()
        .end()
      $rubric_rating_dialog
        .data('current_criterion', $criterion)
        .data('current_rating', $rating)
        .hideErrors()
        .dialog({
          title: I18n.t('titles.edit_rubric_rating', 'Edit Rating'),
          width: 400,
          buttons: [],
          close: close_function,
          modal: true,
          zIndex: 1000,
        })
      $rubric_rating_dialog.fixDialogButtons()
    })
    .on('click', '.find_rubric_link', event => {
      event.preventDefault()
      $rubric_dialog.dialog({
        width: 800,
        height: 380,
        resizable: true,
        title: I18n.t('titles.find_existing_rubric', 'Find Existing Rubric'),
        modal: true,
        zIndex: 1000,
      })
      if (!$rubric_dialog.hasClass('loaded')) {
        $rubric_dialog
          .find('.loading_message')
          .text(I18n.t('messages.loading_rubric_groups', 'Loading rubric groups...'))
        const url = $rubric_dialog.find('.grading_rubrics_url').attr('href')
        $.ajaxJSON(
          url,
          'GET',
          {},
          data => {
            data.forEach(context => {
              const $context = $rubric_dialog
                .find('.rubrics_dialog_context_select.blank:first')
                .clone(true)
                .removeClass('blank')
              $context.fillTemplateData({
                data: {
                  name: context.name,
                  context_code: context.context_code,
                  rubrics: context.rubrics + ' rubrics',
                },
              })
              $rubric_dialog.find('.rubrics_dialog_contexts_select').append($context.show())
            })
            if (data.length === 0) {
              $rubric_dialog.find('.loading_message').text('No rubrics found')
            } else {
              $rubric_dialog.find('.loading_message').remove()
            }
            $rubric_dialog.find('.rubrics_dialog_rubrics_holder').slideDown()
            $rubric_dialog
              .find('.rubrics_dialog_contexts_select .rubrics_dialog_context_select:visible:first')
              .click()
            $rubric_dialog.addClass('loaded')
          },
          () => {
            $rubric_dialog
              .find('.loading_message')
              .text(
                I18n.t('errors.load_rubrics_failed', 'Loading rubrics failed, please try again')
              )
          }
        )
      }
    })
    .on('click', '.edit_rubric_link', function (event) {
      event.preventDefault()

      const $link = $(this),
        $rubric = $link.parents('.rubric'),
        useMasteryScale = shouldUseMasteryScale($rubric)

      if (rubricEditing.isEditing) return false
      // eslint-disable-next-line no-restricted-globals, no-alert
      if (!$link.hasClass('copy_edit') || confirm(getEditRubricPrompt(useMasteryScale))) {
        rubricEditing.editRubric($rubric, $link.attr('href'), useMasteryScale)
      }
    })

  // cant use delegate because events bound to a .delegate wont get triggered when you do .triggerHandler('click') because it wont bubble up.
  // TODO is this still true at jQuery 3.0?
  $('.rubric .delete_rubric_link').on('click', function (event, callback) {
    event.preventDefault()
    let message = I18n.t('prompts.confirm_delete', 'Are you sure you want to delete this rubric?')
    if (callback && callback.confirmationMessage) {
      message = callback.confirmationMessage
    }
    $(this)
      .parents('.rubric')
      .confirmDelete({
        url: $(this).attr('href'),
        message,
        success() {
          $(this).fadeOut(() => {
            $('.add_rubric_link').show().focus()
            if (callback && $.isFunction(callback)) {
              callback()
            }
          })
        },
      })
  })

  $rubric_long_description_dialog.find('.save_button').click(() => {
    const long_description = $rubric_long_description_dialog
        .find('textarea.long_description')
        .val(),
      description = $rubric_long_description_dialog.find('textarea.description').val(),
      $criterion = $rubric_long_description_dialog.data('current_criterion')
    const valid = $rubric_long_description_dialog.validateForm({
      required: ['description'],
      labels: {description: I18n.t('Description')},
    })
    if (!valid) {
      return
    }
    if ($criterion) {
      $criterion.fillTemplateData({data: {long_description, description_title: description}})
      $criterion.find('textarea.long_description').val(long_description)
      $criterion.find('textarea.description').val(description)
      $criterion.find('.long_description_holder').toggleClass('empty', !long_description)
      let screenreaderMessage = I18n.t('Criterion Updated')
      if ($criterion.hasClass('new_criterion')) {
        screenreaderMessage = I18n.t('Criterion Created')
      }
      $criterion.removeClass('new_criterion')
      $criterion.show()
      const $rubric = $criterion.parents('.rubric')
      rubricEditing.updateCriteria($rubric)
      rubricEditing.updateRubricPoints($rubric)
      rubricEditing.updateAddCriterionLinks($rubric)
      setTimeout(() => {
        $.screenReaderFlashMessageExclusive(screenreaderMessage)
        $criterion.find('.edit_criterion_link').focus()
      }, 100)
    }
    $rubric_long_description_dialog.dialog('close')
  })
  $rubric_long_description_dialog.find('.cancel_button').click(() => {
    $rubric_long_description_dialog.dialog('close')
  })

  $rubric_rating_dialog.find('.save_button').click(event => {
    event.preventDefault()
    event.stopPropagation()
    const data = $rubric_rating_dialog.find('#edit_rating_form').getFormData()
    const valid = $rubric_rating_dialog.find('#edit_rating_form').validateForm({
      data,
      required: ['description'],
      labels: {description: I18n.t('Rating Title')},
    })
    if (!valid) {
      return
    }
    const $rating = $rubric_rating_dialog.data('current_rating')
    const $criterion = $rubric_rating_dialog.data('current_criterion')
    const $target = $rating.find('.edit_rating_link')
    const use_range = $criterion.find('.criterion_use_range').prop('checked')
    const $nextRating = $rating.next('.rating')
    const $previousRating = $rating.prev('.rating')
    data.points = round(numberHelper.parse(data.points), 2)
    if (Number.isNaN(data.points)) {
      data.points = numberHelper.parse($criterion.find('.criterion_points').val())
      if (Number.isNaN(data.points)) {
        data.points = 5
      }
      if (data.points < 0) {
        data.points = 0
      }
    }
    data.min_points = round(numberHelper.parse(data.min_points), 2)
    if (Number.isNaN(data.min_points) || data.min_points < 0) {
      data.min_points = 0
    }
    if (use_range) {
      // Fix up min and max if the user reversed them.
      if (data.points < data.min_points) {
        const tmp_points = data.points
        data.points = data.min_points
        data.min_points = tmp_points
      }
      if ($previousRating && $previousRating.length !== 0) {
        data.points = rubricEditing.capPointChange(data.points, $previousRating, Math.min, 'points')
      }
      if ($nextRating && $nextRating.length !== 0) {
        data.min_points = rubricEditing.capPointChange(
          data.min_points,
          $nextRating,
          Math.max,
          'min_points'
        )
      }
    }
    $rating.fillTemplateData({data})
    rubricEditing.flagInfinitesimalRating($rating, use_range)
    if ($rating.prev('.rating').length === 0) {
      $criterion.find('.criterion_points').val(rubricEditing.localizedPoints(data.points))
      $criterion.data('criterion_points', data.points)
    }
    if ($nextRating) {
      $nextRating.fillTemplateData({data: {points: data.min_points}})
      rubricEditing.flagInfinitesimalRating($nextRating, use_range)
    }
    if ($previousRating) {
      $previousRating.fillTemplateData({data: {min_points: data.points}})
      rubricEditing.flagInfinitesimalRating($previousRating, use_range)
    }
    rubricEditing.updateCriterionPoints($criterion, true)
    rubricEditing.originalSizeRatings()
    $rating.removeClass('new_rating')
    $rubric_rating_dialog.dialog('close')
    setTimeout(() => {
      $.screenReaderFlashMessageExclusive(I18n.t('Rating Updated'))
      $target.focus()
    }, 100)
  })
  $rubric_rating_dialog.find('.cancel_button').click(() => {
    $rubric_rating_dialog.dialog('close')
  })

  $('.add_rubric_link').click(event => {
    event.preventDefault()
    if ($('#rubric_new').length > 0) {
      return
    }
    if (limitToOneRubric && $('#rubrics .rubric:visible').length > 0) {
      return
    }
    const $rubric = rubricEditing.addRubric()
    $('#rubrics').append($rubric.show())
    $('.add_rubric_link').hide()
    rubricEditing.updateAddCriterionLinks($rubric)
    const $target = $rubric.find('.find_rubric_link:visible:first')
    if ($target.length > 0) {
      $target.focus()
    } else {
      $rubric.find(':text:first').focus().select()
    }
  })

  $('#rubric_dialog')
    .on('click', '.rubrics_dialog_context_select', function (event) {
      event.preventDefault()
      $('.rubrics_dialog_contexts_select .selected_side_tab').removeClass('selected_side_tab')
      const $link = $(this)
      $link.addClass('selected_side_tab')
      const context_code = $link.getTemplateData({textValues: ['context_code']}).context_code
      if ($link.hasClass('loaded')) {
        $rubric_dialog.find('.rubrics_loading_message').hide()
        $rubric_dialog.find('.rubrics_dialog_rubrics,.rubrics_dialog_rubrics_select').show()
        $rubric_dialog.find('.rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select').hide()
        $rubric_dialog
          .find('.rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select.' + context_code)
          .show()
        $rubric_dialog
          .find('.rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select:visible:first')
          .click()
      } else {
        $rubric_dialog
          .find('.rubrics_loading_message')
          .text(I18n.t('messages.loading_rubrics', 'Loading rubrics...'))
          .show()
        $rubric_dialog.find('.rubrics_dialog_rubrics,.rubrics_dialog_rubrics_select').hide()
        const url =
          $rubric_dialog.find('.grading_rubrics_url').attr('href') + '?context_code=' + context_code
        $.ajaxJSON(
          url,
          'GET',
          {},
          data => {
            $link.addClass('loaded')
            $rubric_dialog.find('.rubrics_loading_message').hide()
            $rubric_dialog.find('.rubrics_dialog_rubrics,.rubrics_dialog_rubrics_select').show()
            data.forEach(item => {
              const association = item.rubric_association
              const rubric = association.rubric
              const $rubric_select = $rubric_dialog
                .find('.rubrics_dialog_rubric_select.blank:first')
                .clone(true)
              $rubric_select.addClass(association.context_code)
              rubric.criterion_count = rubric.data.length
              $rubric_select.fillTemplateData({data: rubric}).removeClass('blank')
              $rubric_dialog.find('.rubrics_dialog_rubrics_select').append($rubric_select.show())
              const $rubric = $rubric_dialog.find('.rubrics_dialog_rubric.blank:first').clone(true)
              $rubric.removeClass('blank')
              $rubric.find('.criterion.blank').hide()
              rubric.rubric_total = rubric.points_possible
              $rubric.fillTemplateData({
                data: rubric,
                id: 'rubric_dialog_' + rubric.id,
              })
              rubric.data.forEach(criterion => {
                criterion.criterion_points = criterion.points
                criterion.criterion_points_possible = criterion.points
                criterion.criterion_description = criterion.description
                const ratings = criterion.ratings
                delete criterion.ratings
                const $criterion = $rubric
                  .find('.criterion.blank:first')
                  .clone()
                  .removeClass('blank')
                $criterion.fillTemplateData({
                  data: criterion,
                })
                $criterion.find('.rating_holder').addClass('blank')
                ratings.forEach(rating => {
                  const $rating = $criterion
                    .find('.rating_holder.blank:first')
                    .clone()
                    .removeClass('blank')
                  rating.rating = rating.description
                  $rating.fillTemplateData({
                    data: rating,
                  })
                  $criterion.find('.ratings').append($rating.show())
                })
                $criterion.find('.rating_holder.blank').remove()
                $rubric.find('.rubric.rubric_summary tr.summary').before($criterion.show())
              })
              $rubric_dialog.find('.rubrics_dialog_rubrics').append($rubric)
            })
            $rubric_dialog
              .find('.rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select')
              .hide()
            $rubric_dialog
              .find('.rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select.' + context_code)
              .show()
            $rubric_dialog
              .find('.rubrics_dialog_rubrics_select .rubrics_dialog_rubric_select:visible:first')
              .click()
          },
          () => {
            $rubric_dialog
              .find('.rubrics_loading_message')
              .text('Loading rubrics failed, please try again')
          }
        )
      }
    })
    .on('click', '.rubrics_dialog_rubric_select', function (event) {
      event.preventDefault()
      const $select = $(this)
      $select.find('a').focus()
      const id = $select.getTemplateData({textValues: ['id']}).id
      $('.rubric_dialog .rubrics_dialog_rubric_select').removeClass('selected_side_tab') // .css('fontWeight', 'normal');
      $select.addClass('selected_side_tab')
      $('.rubric_dialog .rubrics_dialog_rubric').hide()
      $('.rubric_dialog #rubric_dialog_' + id).show()
    })
    .on('click', '.select_rubric_link', function (event) {
      event.preventDefault()
      const data = {}
      const params = $rubric_dialog.getTemplateData({
        textValues: [
          'rubric_association_type',
          'rubric_association_id',
          'rubric_association_purpose',
        ],
      })
      data['rubric_association[association_type]'] = params.rubric_association_type
      data['rubric_association[association_id]'] = params.rubric_association_id
      data['rubric_association[rubric_id]'] = $(this)
        .parents('.rubrics_dialog_rubric')
        .getTemplateData({textValues: ['id']}).id
      data['rubric_association[purpose]'] = params.rubric_association_purpose
      $rubric_dialog.loadingImage()
      const url = window.ENV.context_rubric_associations_url
      if (!url) throw new Error('Rubric Associations URL is undefined')
      $.ajaxJSON(
        url,
        'POST',
        data,
        res => {
          $rubric_dialog.loadingImage('remove')
          let $rubric = $('#rubrics .rubric:visible:first')
          if ($rubric.length === 0) {
            $rubric = rubricEditing.addRubric()
          }
          const rubric = res.rubric
          rubric.rubric_association_id = res.rubric_association.id
          rubric.use_for_grading = res.rubric_association.use_for_grading
          rubric.permissions = rubric.permissions || {}
          if (res.rubric_association.permissions) {
            rubric.permissions.update_association = res.rubric_association.permissions.update
            rubric.permissions.delete_association = res.rubric_association.permissions.delete
          }
          rubricEditing.updateRubric($rubric, rubric)
          rubricEditing.updateRubricPoints($rubric)
          rubricEditing.hideEditRubric($rubric, false)
          $rubric_dialog.dialog('close')
          // equivalent check in _rubric.html.erb
          if (!rubric.permissions?.update) {
            $rubric.find('.edit_rubric_link').addClass('copy_edit')
          }
        },
        () => {
          $rubric_dialog.loadingImage('remove')
        }
      )
    })

  $rubric_dialog.find('.cancel_find_rubric_link').click(event => {
    event.preventDefault()
    $rubric_dialog.dialog('close')
  })
  $rubric_dialog
    .find('.rubric_brief')
    .find('.expand_data_link,.collapse_data_link')
    .click(function (event) {
      event.preventDefault()
      $(this)
        .parents('.rubric_brief')
        .find('.expand_data_link,.collapse_data_link')
        .toggle()
        .end()
        .find('.details')
        .slideToggle()
    })

  let forceSubmit = false,
    skipPointsUpdate = false
  $('#edit_rubric_form').formSubmit({
    processData() {
      const $rubric = $(this).parents('.rubric')
      if (!$rubric.find('.criterion:not(.blank)').length) return false
      const data = rubricEditing.rubricData($rubric)
      if (
        ENV.MASTER_COURSE_DATA &&
        ENV.MASTER_COURSE_DATA.restricted_by_master_course &&
        ENV.MASTER_COURSE_DATA.is_master_course_child_content &&
        ENV.MASTER_COURSE_DATA.master_course_restrictions.points
      ) {
        skipPointsUpdate = true
      } else if (data['rubric_association[use_for_grading]'] === '1') {
        const toolFormId = ENV.LTI_TOOL_FORM_ID
          ? `#tool_form_${ENV.LTI_TOOL_FORM_ID}`
          : '#tool_form'
        const externalToolPoints = $(
          `${toolFormId} #custom_canvas_assignment_points_possible`
        ).val()
        let assignmentPoints
        if (externalToolPoints) {
          assignmentPoints = numberHelper.parse(externalToolPoints)
        } else {
          assignmentPoints = numberHelper.parse(
            $(
              '#assignment_show .points_possible, #rubrics.rubric_dialog .assignment_points_possible'
            ).text()
          )
        }

        if (Number.isNaN(assignmentPoints)) {
          // For N.Q assignments, we show the rubric from the assignment edit screen instead of
          // the show screen used for other assignments.
          assignmentPoints = numberHelper.parse(
            $('#edit_assignment_header input[id="assignment_points_possible"]').val()
          )
        }

        if (Number.isNaN(assignmentPoints) && ENV.ASSIGNMENT_POINTS_POSSIBLE) {
          // For 1.3 external tool assignments, we grab the points from an env variable
          assignmentPoints = numberHelper.parse(ENV.ASSIGNMENT_POINTS_POSSIBLE)
        }
        const rubricPoints = parseFloat(data.points_possible)
        if (
          assignmentPoints !== null &&
          assignmentPoints !== undefined &&
          rubricPoints !== assignmentPoints &&
          !forceSubmit
        ) {
          const pointRatio = assignmentPoints === 0 ? rubricPoints : rubricPoints / assignmentPoints
          const $confirmDialog = $(
            changePointsPossibleToMatchRubricDialog({
              assignmentPoints,
              rubricPoints,
              pointRatio,
            })
          )
          const closeDialog = function (skip) {
            forceSubmit = true
            skipPointsUpdate = skip === true
            $confirmDialog.remove()
            $('#edit_rubric_form').submit()
          }
          $confirmDialog.dialog({
            dialogClass: 'edit-rubric-confirm-points-change',
            buttons: [
              {
                text: I18n.t('change', 'Change'),
                click: closeDialog,
              },
              {
                text: I18n.t('leave_different', 'Leave different'),
                click() {
                  closeDialog(true)
                },
              },
            ],
            width: 400,
            resizable: false,
            close: $confirmDialog.remove,
            modal: true,
            zIndex: 1000,
          })
          return false
        }
      }
      data.skip_updating_points_possible = skipPointsUpdate
      skipPointsUpdate = false
      forceSubmit = false
      return data
    },
    beforeSubmit(data) {
      const $rubric = $(this).parents('.rubric')
      $rubric.find('.rubric_title .title').text(data['rubric[title]'])
      $rubric.find('.rubric_table caption .title').text(data['rubric[title]'])
      $rubric.find('.rubric_total').text(rubricEditing.localizedPoints(data.points_possible))
      $rubric.loadingImage()
      return $rubric
    },
    success(data, $rubric) {
      $rubric.loadingImage('remove')

      if (data.error) {
        $(':submit.save_button:visible').errorBox(data.messages.join('\n'))
      } else {
        $rubric.removeClass('editing')
        if ($rubric.attr('id') === 'rubric_new') {
          $rubric.attr('id', 'rubric_adding')
        } else {
          $rubric.prev('.rubric').remove()
        }
        $(this).parents('tr').hide()

        const rubric = data.rubric

        rubric.rubric_association_id = data.rubric_association.id
        rubric.use_for_grading = data.rubric_association.use_for_grading
        rubric.hide_points = data.rubric_association.hide_points
        rubric.hide_outcome_results = data.rubric_association.hide_outcome_results
        rubric.permissions = rubric.permissions || {}
        if (data.rubric_association.permissions) {
          rubric.permissions.update_association = data.rubric_association.permissions.update
          rubric.permissions.delete_association = data.rubric_association.permissions.delete
        }
        rubricEditing.updateRubric($rubric, rubric)
        if (
          data.rubric_association &&
          data.rubric_association.use_for_grading &&
          !data.rubric_association.skip_updating_points_possible
        ) {
          $('#assignment_show .points_possible').text(rubric.points_possible)
          const discussion_points_text = I18n.t(
            'discussion_points_possible',
            {one: '%{count} point possible', other: '%{count} points possible'},
            {
              count: rubric.points_possible || 0,
              precision: 2,
              strip_insignificant_zeros: true,
            }
          )
          $('.discussion-title .discussion-points').text(discussion_points_text)
        }
        if (!limitToOneRubric) {
          $('.add_rubric_link').show()
        }
        $rubric.find('.rubric_title .links:not(.locked)').show()
      }
    },
  })

  $('#edit_rubric_form .cancel_button').click(function () {
    $('.errorBox').not('#error_box_template').remove()
    rubricEditing.hideEditRubric($(this).parents('.rubric'), true)
  })

  $('#rubrics')
    .on('click', '.add_criterion_link', function () {
      const $criterion = rubricEditing.addCriterion($(this).parents('.rubric')) // "#default_rubric"));
      $criterion.hide()
      rubricEditing.editCriterion($criterion)
      return false
    })
    .on('click', '.description_title', function () {
      const $criterion = $(this).parents('.criterion')
      rubricEditing.editCriterion($criterion)
      return false
    })
    .on('click', '.delete_criterion_link', function () {
      const $criterion = $(this).parents('.criterion')

      // this is annoying, but the current code doesn't care where in the list
      // of rows the "blank" template element is, so we have to account for the
      // fact that it could be the previous row
      const $prevCriterion = $criterion.prevAll('.criterion:not(.blank)').first()
      let $target = $prevCriterion.find('.edit_criterion_link')
      if ($prevCriterion.length === 0) {
        $target = $criterion.parents('.rubric_container').find('.rubric_title input')
      }
      const $rubric = $criterion.parents('.rubric')
      if ($criterion.hasClass('new_criterion')) {
        $criterion.remove()
        rubricEditing.updateAddCriterionLinks($rubric, '.icon-plus')
      } else {
        // focusing before the fadeOut so safari
        // screenreader can handle focus properly
        $target.focus()

        $criterion.fadeOut(() => {
          $criterion.remove()
          rubricEditing.updateCriteria($rubric)
          rubricEditing.updateRubricPoints($rubric)
          rubricEditing.updateAddCriterionLinks($rubric)
        })
      }
      return false
    })
    .on('click', '.rating_description_value', () => false)
    .on('mouseover', event => {
      const $target = $(event.target)
      if (!$target.closest('.ratings').length) {
        rubricEditing.hideCriterionAdd($target.parents('.rubric'))
      }
    })
    .on('click', '.delete_rating_link', function (event) {
      const $rating_cell = $(this).closest('td')
      const $target = $rating_cell.prev().find('.add_rating_link_after')
      const $previousRating = $rating_cell.prev('.rating')
      const previous_data = {
        min_points: $rating_cell.next('.rating').find('.points').text(),
      }
      $previousRating.fillTemplateData({data: previous_data})
      event.preventDefault()
      rubricEditing.hideCriterionAdd($(this).parents('.rubric'))
      $(this)
        .parents('.rating')
        .fadeOut(function () {
          const $criterion = $(this).parents('.criterion')
          rubricEditing.flagInfinitesimalRating(
            $previousRating,
            $criterion.find('.criterion_use_range').prop('checked')
          )
          $(this).remove()
          rubricEditing.sizeRatings($criterion)
          $target.focus()
        })
    })
    .on('click', '.add_rating_link_after', function (event) {
      event.preventDefault()
      const $this = $(this).parents('td.rating')
      $this.addClass('add_right')
      rubricEditing.addNewRatingColumn($this)
    })
    .on('click', '.add_column', function () {
      const $this = $(this)
      rubricEditing.addNewRatingColumn($this)
    })
  $('.criterion_points')
    .on('keydown', function (event) {
      if (event.keyCode === 13) {
        rubricEditing.updateCriterionPoints($(this).parents('.criterion'))
      }
    })
    .on('blur', function () {
      rubricEditing.updateCriterionPoints($(this).parents('.criterion'))
    })
  $('#edit_rating').on('click', '.cancel_button', function () {
    $(this).closest('td.rating').find('.edit_rating_link')
  })
  $('#edit_rubric_form .rubric_custom_rating')
    .change(function () {
      $(this)
        .parents('.rubric')
        .find('tr.criterion')
        .find('.ratings')
        .showIf(!$(this).prop('checked'))
        .end()
        .find('.criterion_use_range_div')
        .showIf(!$(this).prop('checked'))
        .end()
        .find('.custom_ratings')
        .showIf($(this).prop('checked'))
    })
    .triggerHandler('change')
  $('#edit_rubric_form #totalling_rubric').change(function () {
    $(this).parents('.rubric').find('.total_points_holder').showIf(!$(this).prop('checked'))
  })
  $('#edit_rubric_form #hide_points').change(function (e) {
    if (e.target.checked) {
      rubricEditing.hidePoints($(this).parents('.rubric'), $('#rubric_rating_dialog'))
    } else {
      rubricEditing.showPoints($(this).parents('.rubric'), $('#rubric_rating_dialog'))
    }
  })
  $('#edit_rubric_form .hide_points_checkbox').change(function () {
    if ($(this).is(':visible')) {
      const checked = $(this).prop('checked')
      if (checked) {
        $(this).parents('.rubric').find('.grading_rubric_checkbox').prop('checked', false)
        $(this).parents('.rubric').find('.grading_rubric_checkbox').triggerHandler('change')
      }
      $(this)
        .parents('.rubric')
        .find('.rubric_grading')
        .css('display', checked ? 'none' : '')
      $(this)
        .parents('.rubric')
        .find('.totalling_rubric')
        .css('display', checked ? 'none' : '')
    }
  })
  $('#edit_rubric_form .grading_rubric_checkbox')
    .on('change', function () {
      if ($(this).is(':visible')) {
        $(this)
          .parents('.rubric')
          .find('.totalling_rubric')
          .css('visibility', $(this).prop('checked') ? 'hidden' : 'visible')
        $(this).parents('.rubric').find('.totalling_rubric_checkbox').prop('checked', false)
      }
    })
    .triggerHandler('change')
  $('.criterion_use_range')
    .on('change', function () {
      const checked = $(this).prop('checked')
      $(this)
        .parents('tr.criterion')
        .find('.rating')
        .each(function () {
          const use_range =
            checked &&
            !$(this).hasClass('infinitesimal') &&
            numberHelper.parse($(this).find('.points').text()) !==
              numberHelper.parse($(this).find('.min_points').text())
          $(this).find('.range_rating').showIf(use_range)
        })
    })
    .triggerHandler('change')

  const firstRating = $('#criterion_blank').find('.ratings .points')[0]?.innerHTML
  $('#criterion_blank')
    .find('.criterion_points')
    .val(firstRating || '5')

  if ($('#default_rubric').find('.criterion').length <= 1) {
    rubricEditing.addCriterion($('#default_rubric'))
    $('#default_rubric').find('.criterion').removeClass('new_criterion')
  }
  setInterval(rubricEditing.sizeRatings, 10000)
  $.publish('edit_rubric/initted')
}

if (
  document.getElementById('rubric_management') &&
  ENV.NON_SCORING_RUBRICS &&
  ENV.PERMISSIONS.manage_outcomes &&
  !ENV.ACCOUNT_LEVEL_MASTERY_SCALES
) {
  $('h1').hide()
  const contextId = ENV.context_asset_string.split('_')[1]
  ReactDOM.render(
    <RubricManagement accountId={contextId} />,
    document.getElementById('rubric_management')
  )
}

const getEditRubricPrompt = useMasteryScale => {
  if (!useMasteryScale) {
    return I18n.t(
      "You can't edit this " +
        "rubric, either because you don't have permission " +
        "or it's being used in more than one place. Any " +
        'changes you make will result in a new rubric based on the old rubric. Continue anyway?'
    )
  }
  if (ENV.context_asset_string.includes('course')) {
    return I18n.t(
      "You can't edit this " +
        "rubric, either because you don't have permission " +
        "or it's being used in more than one place. Any " +
        'changes you make will result in a new rubric. Any associated outcome criteria will use the course mastery scale. Continue anyway?'
    )
  } else {
    return I18n.t(
      "You can't edit this " +
        "rubric, either because you don't have permission " +
        "or it's being used in more than one place. Any " +
        'changes you make will result in a new rubric. Any associated outcome criteria will use the account mastery scale. Continue anyway?'
    )
  }
}

const shouldUseMasteryScale = $rubric => {
  if (!ENV.ACCOUNT_LEVEL_MASTERY_SCALES) {
    return false
  }
  return $rubric.find('.criterion').hasClass('learning_outcome_criterion')
}

export default rubricEditing
