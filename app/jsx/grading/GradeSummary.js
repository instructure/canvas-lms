/*
 * Copyright (C) 2017 - present Instructure, Inc.
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

import _ from 'underscore'
import $ from 'jquery'
import 'jquery.ajaxJSON'
import 'jquery.instructure_misc_helpers'  /* replaceTags */
import 'jquery.instructure_misc_plugins' /* showIf */
import 'jquery.templateData'
import 'compiled/jquery/mediaCommentThumbnail'
import 'media_comments' /* mediaComment */
import axios from 'axios'
import { camelize } from 'convert_case'
import React from 'react'
import ReactDOM from 'react-dom'
import gradingPeriodSetsApi from 'compiled/api/gradingPeriodSetsApi'
import htmlEscape from 'str/htmlEscape'
import I18n from 'i18n!gradebook'
import round from 'compiled/util/round'
import numberHelper from '../shared/helpers/numberHelper'
import CourseGradeCalculator from '../gradebook/CourseGradeCalculator'
import {scopeToUser} from '../gradebook/EffectiveDueDates'
import {gradeToScoreLowerBound, scoreToGrade} from '../gradebook/GradingSchemeHelper'
import GradeFormatHelper from '../gradebook/shared/helpers/GradeFormatHelper'
import StatusPill from '../grading/StatusPill'
import SelectMenuGroup from '../grade_summary/SelectMenuGroup'
import {scoreToPercentage} from '../gradebook/shared/helpers/GradeCalculationHelper'

const GradeSummary = {
  getSelectedGradingPeriodId () {
    const currentGradingPeriodId = ENV.current_grading_period_id

    if (!currentGradingPeriodId || currentGradingPeriodId === '0') {
      return null;
    }

    return currentGradingPeriodId
  },

  getAssignmentId ($assignment) {
    return $assignment.getTemplateData({ textValues: ['assignment_id'] }).assignment_id
  },

  parseScoreText (text, numericalDefault, formattedDefault) {
    const defaultNumericalValue = (typeof numericalDefault === 'number') ? numericalDefault : null
    const defaultFormattedValue = (typeof formattedDefault === 'string') ? formattedDefault : '-'
    let numericalValue = numberHelper.parse(text)
    numericalValue = isNaN(numericalValue) ? defaultNumericalValue : numericalValue
    return {
      numericalValue,
      formattedValue: GradeFormatHelper.formatGrade(numericalValue, { defaultValue: defaultFormattedValue })
    }
  },

  getOriginalScore ($assignment) {
    let numericalValue = parseFloat($assignment.find('.original_points').text())
    numericalValue = isNaN(numericalValue) ? null : numericalValue
    return {
      numericalValue,
      formattedValue: $assignment.find('.original_score').text()
    }
  },

  onEditWhatIfScore ($assignmentScore, $ariaAnnouncer) {
      // Store the original score so that it can be restored when the "What-If" score is reverted.
    if (!$assignmentScore.find('.grade').data('originalValue')) {
      $assignmentScore.find('.grade').data('originalValue', $assignmentScore.find('.grade').html())
    }

    const $screenreaderLinkClone = $assignmentScore.find('.screenreader-only').clone(true)
    $assignmentScore.find('.grade').data('screenreader_link', $screenreaderLinkClone)
    $assignmentScore.find('.grade').empty().append($('#grade_entry'))
    $assignmentScore.find('.score_value').hide()
    $ariaAnnouncer.text(I18n.t('Enter a What-If score.'))

      // Get the current shown score (possibly a "What-If" score)
      // and use it as the default value in the text entry field
    const whatIfScoreText = $assignmentScore.parents('.student_assignment').find('.what_if_score').text()
    const score = GradeSummary.parseScoreText(whatIfScoreText, 0, '0')
    $('#grade_entry').val(score.formattedValue)
        .show()
        .focus()
        .select()
  },

  onScoreChange ($assignment, options) {
    const originalScore = GradeSummary.getOriginalScore($assignment)

      // parse the score entered by the user
    const enteredScoreText = $assignment.find('#grade_entry').val()
    let score = GradeSummary.parseScoreText(enteredScoreText)

      // if the user cleared the score, use the previous What-If score
    if (score.numericalValue == null) {
      const previousWhatIfScore = $assignment.find('.what_if_score').text()
      score = GradeSummary.parseScoreText(previousWhatIfScore)
    }

      // if there is no What-If score, use the original score
    if (score.numericalValue == null) {
      score = originalScore
    }

      // set 'isChanged' to true if the user entered the score already on the submission
    const isChanged = score.numericalValue != originalScore.numericalValue // eslint-disable-line eqeqeq

      // update '.what_if_score' with the parsed value from '#grade_entry'
    $assignment.find('.what_if_score').text(score.formattedValue)

    let shouldUpdate = options.update
    if ($assignment.hasClass('dont_update')) {
      shouldUpdate = false
      $assignment.removeClass('dont_update')
    }

    const assignmentId = GradeSummary.getAssignmentId($assignment)

    if (shouldUpdate) {
      const url = $.replaceTags($('.update_submission_url').attr('href'), 'assignment_id', assignmentId)
        // if the original score was entered, remove the student entered score
      const scoreForUpdate = isChanged ? score.numericalValue : null
      $.ajaxJSON(url, 'PUT', { 'submission[student_entered_score]': scoreForUpdate },
          (data) => {
            const updatedData = {student_entered_score: data.submission.student_entered_score}
            $assignment.fillTemplateData({ data: updatedData })
          },
          $.noop
        )
    }

    $('#grade_entry').hide().appendTo($('body'))

    const $assignmentScore = $assignment.find('.assignment_score')
    const $scoreTeaser = $assignmentScore.find('.score_teaser')
    const $grade = $assignment.find('.grade')

    if (isChanged) {
      $assignmentScore.attr('title', '')
      $scoreTeaser.text(I18n.t('This is a What-If score'))
      const $revertScore = $('#revert_score_template').clone(true).attr('id', '').show()
      $assignmentScore.find('.score_holder').append($revertScore)
      $grade.addClass('changed')

        // this is to distinguish between the revert_all_scores_link in the right nav and
        // the revert arrows within the grade_summary page grid
      if (options.refocus) {
        setTimeout(() => { $assignment.find('.revert_score_link').focus() }, 0)
      }
    } else {
      const tooltip = $assignment.data('muted') ?
          I18n.t('Instructor is working on grades') :
          I18n.t('Click to test a different score')
      $assignmentScore.attr('title', I18n.t('Click to test a different score'))
      $scoreTeaser.text(tooltip)
      $grade.removeClass('changed')
      $assignment.find('.revert_score_link').remove()

      if (options.refocus) {
        setTimeout(() => { $assignment.find('.grade').focus() }, 0)
      }
    }

    if (score.numericalValue == null) {
      $grade.html($grade.data('originalValue'))
    } else {
      $grade.html(htmlEscape(score.formattedValue))
    }

    if (!isChanged) {
      const $screenreaderLinkClone = $assignment.find('.grade').data('screenreader_link')
      $assignment.find('.grade').prepend($screenreaderLinkClone)
    }

    GradeSummary.updateScoreForAssignment(assignmentId, score.numericalValue)
    GradeSummary.updateStudentGrades()
  },

  onScoreRevert ($assignment, options) {
    const opts = { refocus: true, skipEval: false, ...options }
    const score = GradeSummary.getOriginalScore($assignment)
    let tooltip

    if ($assignment.data('muted')) {
      tooltip = I18n.t('Instructor is working on grades')
    } else {
      tooltip = I18n.t('Click to test a different score')
    }

    const $assignmentScore = $assignment.find('.assignment_score')
    $assignment.find('.what_if_score').text(score.formattedValue)
    $assignmentScore.attr('title', I18n.t('Click to test a different score'))
    $assignmentScore.find('.score_teaser').text(tooltip)
    $assignmentScore.find('.grade').removeClass('changed')
    $assignment.find('.revert_score_link').remove()
    $assignment.find('.score_value').text(score.formattedValue)

    if ($assignment.data('muted')) {
      $assignment.find('.grade').html('<i class="icon-muted muted_icon" aria-hidden="true"></i>')
    } else {
      $assignment.find('.grade').text(score.formattedValue)
    }

    const assignmentId = $assignment.getTemplateValue('assignment_id')
    GradeSummary.updateScoreForAssignment(assignmentId, score.numericalValue)
    if (!opts.skipEval) {
      GradeSummary.updateStudentGrades()
    }

    const $screenreaderLinkClone = $assignment.find('.grade').data('screenreader_link')
    $assignment.find('.grade').prepend($screenreaderLinkClone)

    if (opts.refocus) {
      setTimeout(() => { $assignment.find('.grade').focus() }, 0)
    }
  }
}

function getGradingPeriodSet () {
  if (ENV.grading_period_set) {
    return gradingPeriodSetsApi.deserializeSet(ENV.grading_period_set)
  }
  return null
}

function calculateGrades () {
  let grades

  if (ENV.effective_due_dates && ENV.grading_period_set) {
    grades = CourseGradeCalculator.calculate(
        ENV.submissions,
        ENV.assignment_groups,
        ENV.group_weighting_scheme,
        getGradingPeriodSet(),
        scopeToUser(ENV.effective_due_dates, ENV.student_id)
      )
  } else {
    grades = CourseGradeCalculator.calculate(
        ENV.submissions,
        ENV.assignment_groups,
        ENV.group_weighting_scheme
      )
  }

  const selectedGradingPeriodId = GradeSummary.getSelectedGradingPeriodId()
  if (selectedGradingPeriodId) {
    return grades.gradingPeriods[selectedGradingPeriodId]
  }

  return grades
}

function canBeConvertedToGrade (score, possible) {
  return possible > 0 && !isNaN(score)
}

function calculatePercentGrade (score, possible) {
  const percentGrade = scoreToPercentage(score, possible)
  return round(percentGrade, round.DEFAULT)
}

function formatPercentGrade (percentGrade) {
  return I18n.n(percentGrade, {percentage: true})
}

function calculateGrade (score, possible) {
  if (canBeConvertedToGrade(score, possible)) {
    return formatPercentGrade(calculatePercentGrade(score, possible))
  }

  return I18n.t('N/A')
}

function subtotalByGradingPeriod () {
  const gpset = ENV.grading_period_set
  const gpselected = GradeSummary.getSelectedGradingPeriodId()
  return ((!gpselected || gpselected === 0) && gpset && gpset.weighted)
}

function calculateSubtotals (byGradingPeriod, calculatedGrades, currentOrFinal) {
  const subtotals = []
  let params
  if (byGradingPeriod) {
    params = {
      bins: ENV.grading_periods,
      grades: calculatedGrades.gradingPeriods,
      elementIdPrefix: '#submission_period'
    }
  } else {
    params = {
      bins: ENV.assignment_groups,
      grades: calculatedGrades.assignmentGroups,
      elementIdPrefix: '#submission_group'
    }
  }
  if (params.grades) {
    for (let i = 0; i < params.bins.length; i++) {
      const binId = params.bins[i].id
      let grade = params.grades[binId]
      if (grade) {
        grade = grade[currentOrFinal]
      } else {
        grade = {score: 0, possible: 0}
      }
      const scoreText = I18n.n(grade.score, {precision: round.DEFAULT})
      const possibleText = I18n.n(grade.possible, {precision: round.DEFAULT})
      const subtotal = {
        teaserText: `${scoreText} / ${possibleText}`,
        gradeText: calculateGrade(grade.score, grade.possible),
        rowElementId: `${params.elementIdPrefix}-${binId}`
      }
      subtotals.push(subtotal)
    }
  }
  return subtotals
}

function finalGradePointsPossibleText (groupWeightingScheme, scoreWithPointsPossible) {
  if (groupWeightingScheme === "percent") {
    return "";
  }

  const gradingPeriodId = GradeSummary.getSelectedGradingPeriodId();
  const gradingPeriodSet = getGradingPeriodSet();
  if (gradingPeriodId == null && gradingPeriodSet && gradingPeriodSet.weighted) {
    return "";
  }

  return scoreWithPointsPossible;
}

function calculateTotals (calculatedGrades, currentOrFinal, groupWeightingScheme) {
  const gradeChanged = $('.grade.changed').length > 0
  const showTotalGradeAsPoints = ENV.show_total_grade_as_points

  const subtotals = calculateSubtotals(subtotalByGradingPeriod(), calculatedGrades, currentOrFinal)
  for (let i = 0; i < subtotals.length; i++) {
    const $row = $(subtotals[i].rowElementId)
    $row.find('.grade').text(subtotals[i].gradeText)
    $row.find('.score_teaser').text(subtotals[i].teaserText)
    $row.find('.points_possible').text(subtotals[i].teaserText)
  }

  const finalScore = calculatedGrades[currentOrFinal].score
  const finalPossible = calculatedGrades[currentOrFinal].possible
  const scoreAsPoints = `${I18n.n(finalScore, {precision: round.DEFAULT})} / ${I18n.n(finalPossible, {precision: round.DEFAULT})}`
  const scoreAsPercent = calculateGrade(finalScore, finalPossible)

  let finalGrade
  let teaserText

  if (!gradeChanged && ENV.grading_scheme && ENV.effective_final_grade) {
    finalGrade = formatPercentGrade(gradeToScoreLowerBound(ENV.effective_final_grade, ENV.grading_scheme))
    teaserText = scoreAsPoints
  } else if (showTotalGradeAsPoints && groupWeightingScheme !== 'percent') {
    finalGrade = scoreAsPoints
    teaserText = scoreAsPercent
  } else {
    finalGrade = scoreAsPercent
    teaserText = scoreAsPoints
  }

  const $finalGradeRow = $('.student_assignment.final_grade')
  $finalGradeRow.find('.grade').text(finalGrade)
  $finalGradeRow.find('.score_teaser').text(teaserText)

  const pointsPossibleText = finalGradePointsPossibleText(groupWeightingScheme, scoreAsPoints);
  $finalGradeRow.find('.points_possible').text(pointsPossibleText);

  if (groupWeightingScheme === 'percent') {
    $finalGradeRow.find('.score_teaser').hide()
  }

  if (gradeChanged) {
      // User changed their points for an assignment => let's let them know their updated points
    const msg = I18n.t('Based on What-If scores, the new total is now %{grade}', {grade: finalGrade})
    $.screenReaderFlashMessageExclusive(msg)
  }

  if (ENV.grading_scheme) {
    $('.final_letter_grade .grade').text(
      ENV.effective_final_grade || scoreToGrade(calculatePercentGrade(finalScore, finalPossible), ENV.grading_scheme)
    )
  }

  $('.revert_all_scores').showIf($('#grades_summary .revert_score_link').length > 0)
}

function updateStudentGrades () {
  const droppedMessage = I18n.t('This assignment is dropped and will not be considered in the total calculation')
  const ignoreUngradedSubmissions = $('#only_consider_graded_assignments').attr('checked')
  const currentOrFinal = ignoreUngradedSubmissions ? 'current' : 'final'
  const groupWeightingScheme = ENV.group_weighting_scheme
  const includeTotal = !ENV.exclude_total

  const calculatedGrades = calculateGrades()

  $('.dropped').attr('aria-label', '')
  $('.dropped').attr('title', '')

    // mark dropped assignments
  $('.student_assignment').find('.points_possible').attr('aria-label', '')

  _.forEach(calculatedGrades.assignmentGroups, (grades) => {
    _.forEach(grades[currentOrFinal].submissions, (submission) => {
      $(`#submission_${submission.submission.assignment_id}`).toggleClass('dropped', !!submission.drop)
    })
  })

  $('.dropped').attr('aria-label', droppedMessage)
  $('.dropped').attr('title', droppedMessage)

  if (includeTotal) {
    calculateTotals(calculatedGrades, currentOrFinal, groupWeightingScheme)
  }
}

function updateScoreForAssignment (assignmentId, score) {
  const submission = _.find(ENV.submissions, s => (`${s.assignment_id}`) === (`${assignmentId}`))

  if (submission) {
    submission.score = score
  } else {
    ENV.submissions.push({assignment_id: assignmentId, score})
  }
}

function bindShowAllDetailsButton ($ariaAnnouncer) {
  $('#show_all_details_button').click((event) => {
    event.preventDefault()
    const $button = $('#show_all_details_button')
    $button.toggleClass('showAll')

    if ($button.hasClass('showAll')) {
      $button.text(I18n.t('Hide All Details'))
      $('tr.student_assignment.editable').each(function () {
        const assignmentId = $(this).getTemplateValue('assignment_id')
        const muted = $(this).data('muted')
        if (!muted) {
          $(`#comments_thread_${assignmentId}`).show()
          $(`#rubric_${assignmentId}`).show()
          $(`#grade_info_${assignmentId}`).show()
          $(`#final_grade_info_${assignmentId}`).show()
        }
      })
      $ariaAnnouncer.text(I18n.t('assignment details expanded'))
    } else {
      $button.text(I18n.t('Show All Details'))
      $('tr.rubric_assessments').hide()
      $('tr.comments').hide()
      $ariaAnnouncer.text(I18n.t('assignment details collapsed'))
    }
  })
}

function displayPageContent() {
  document.getElementById('grade-summary-content').style.display = ''
  document.getElementById('student-grades-right-content').style.display = ''
}

function goToURL(url) {
  window.location.href = url
}

function saveAssignmentOrder(order) {
  return axios.post(ENV.save_assignment_order_url, { assignment_order: order })
}

function coursesWithGrades() {
  return ENV.courses_with_grades.map((course) => camelize(course))
}

function getSelectMenuGroupProps() {
  return {
    assignmentSortOptions: ENV.assignment_sort_options,
    courses: coursesWithGrades(),
    currentUserID: ENV.current_user.id,
    displayPageContent,
    goToURL,
    gradingPeriods: ENV.grading_periods || [],
    saveAssignmentOrder,
    selectedAssignmentSortOrder: ENV.current_assignment_sort_order,
    selectedCourseID: ENV.context_asset_string.match(/.*_(\d+)$/)[1],
    selectedGradingPeriodID: ENV.current_grading_period_id,
    selectedStudentID: ENV.student_id,
    students: ENV.students
  }
}

function renderSelectMenuGroup() {
  ReactDOM.render(
    <SelectMenuGroup {...GradeSummary.getSelectMenuGroupProps()} />,
    document.getElementById('GradeSummarySelectMenuGroup')
  )
}

function setup () {
  $(document).ready(function () {
    GradeSummary.updateStudentGrades()
    const showAllWhatIfButton = $(this).find('#student-grades-whatif button')
    const revertButton = $(this).find('#revert-all-to-actual-score')
    const $ariaAnnouncer = $(this).find('#aria-announcer')

    $('.revert_all_scores_link').click((event) => {
      event.preventDefault()
        // we pass in refocus: false here so the focus won't go to the revert arrows within the grid
      $('#grades_summary .revert_score_link').each(function () {
        $(this).trigger('click', {skipEval: true, refocus: false})
      })
      $('#.show_guess_grades.exists').show()
      GradeSummary.updateStudentGrades()
      showAllWhatIfButton.focus()
      $.screenReaderFlashMessageExclusive(I18n.t('Grades are now reverted to original scores'))
    })

      // manages toggling and screenreader focus for comments, scoring, and rubric details
    $('.toggle_comments_link, .toggle_score_details_link, ' +
        '.toggle_rubric_assessments_link, .toggle_final_grade_info').click(function (event) {
          event.preventDefault()
          const $row = $(`#${$(this).attr('aria-controls')}`)
          const originEl = this

          $(originEl).attr('aria-expanded', $row.css('display') === 'none')
          $row.toggle()

          if ($row.css('display') !== 'none') {
            $row.find('.screenreader-toggle').focus()
          }
        })

    $('.screenreader-toggle').click(function (event) {
      event.preventDefault()
      const ariaControl = $(this).data('aria')
      const originEl = $(`a[aria-controls='${ariaControl}']`)

      $(originEl).attr('aria-expanded', false)
      $(originEl).focus()
      $(this).closest('.rubric_assessments, .comments').hide()
    })

    function editWhatIfScore (event) {
      if (event.type === 'click' || event.keyCode === 13) {
        if ($('#grades_summary.editable').length === 0 ||
              $(this).find('#grade_entry').length > 0 ||
              $(event.target).closest('.revert_score_link').length > 0) {
          return
        }

        GradeSummary.onEditWhatIfScore($(this), $ariaAnnouncer)
      }
    }

    $('.student_assignment.editable .assignment_score').on('click keypress', editWhatIfScore)

    $('#grade_entry').keydown(function (event) {
      if (event.keyCode === 13) {
          // Enter Key: Finish Changes
        $ariaAnnouncer.text('')
        $(this)[0].blur()
      } else if (event.keyCode === 27) {
          // Escape Key: Clear the Text Field
        $ariaAnnouncer.text('')
        const val = $(this).parents('.student_assignment')
            .addClass('dont_update')
            .find('.original_score')
            .text()
        $(this).val(val || '')[0].blur()
      }
    })

    $('#grades_summary .student_assignment').bind('score_change', function (_event, options) {
      GradeSummary.onScoreChange($(this), options)
    })

    $('#grade_entry').blur(function () {
      const $assignment = $(this).parents('.student_assignment')
      $assignment.triggerHandler('score_change', { update: true, refocus: true })
    })

    $('#grades_summary').delegate('.revert_score_link', 'click', function (event, options) {
      event.preventDefault()
      event.stopPropagation()

      GradeSummary.onScoreRevert($(this).parents('.student_assignment'), options)
    })

    $('#grades_summary:not(.editable) .assignment_score').css('cursor', 'default')

    $('#grades_summary tr').hover(function () {
      $(this).find('th.title .context').addClass('context_hover')
    }, function () {
      $(this).find('th.title .context').removeClass('context_hover')
    })

    $('.show_guess_grades_link').click(() => {
      $('#grades_summary .student_entered_score').each(function () {
        const score = GradeSummary.parseScoreText($(this).text())
        if (score.numericalValue != null) {
          const $assignment = $(this).parents('.student_assignment')
          $assignment.find('.what_if_score').text(score.formattedValue)
          $assignment.find('.score_value').hide()
          $assignment.triggerHandler('score_change', { update: false, refocus: false })
        }
      })
      $('.show_guess_grades').hide()
      revertButton.focus()
      $.screenReaderFlashMessageExclusive(I18n.t('Grades are now showing what-if scores'))
    })

    $('#grades_summary .student_entered_score').each(function () {
      const score = GradeSummary.parseScoreText($(this).text())
      if (score.numericalValue != null) {
        $('.show_guess_grades').show().addClass('exists')
      }
    })

    $('.comments .play_comment_link').mediaCommentThumbnail('normal')

    $('.play_comment_link').live('click', function (event) {
      event.preventDefault()
      const $parent = $(this).parents('.comment_media')
      const commentId = $parent.getTemplateData({textValues: ['media_comment_id']}).media_comment_id
      if (commentId) {
        let mediaType = 'any'
        if ($(this).hasClass('video_comment')) {
          mediaType = 'video'
        } else if ($(this).hasClass('audio_comment')) {
          mediaType = 'audio'
        }
        $parent.children(':not(.media_comment_content)').remove()
        $parent.find('.media_comment_content').mediaComment('show_inline', commentId, mediaType)
      }
    })

    $('#only_consider_graded_assignments').change(() => {
      GradeSummary.updateStudentGrades()
    }).triggerHandler('change')

    bindShowAllDetailsButton($ariaAnnouncer)
    StatusPill.renderPills()
  })
}

export default _.extend(GradeSummary, {
  setup,
  getGradingPeriodSet,
  canBeConvertedToGrade,
  calculateGrade,
  calculateGrades,
  calculateTotals,
  calculateSubtotals,
  calculatePercentGrade,
  finalGradePointsPossibleText,
  formatPercentGrade,
  getSelectMenuGroupProps,
  renderSelectMenuGroup,
  updateScoreForAssignment,
  updateStudentGrades
})
