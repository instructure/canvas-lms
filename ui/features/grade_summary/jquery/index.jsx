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

import {forEach, find, extend as lodashExtend} from 'lodash'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_misc_helpers' /* replaceTags */
import '@canvas/jquery/jquery.instructure_misc_plugins' /* showIf */
import '@canvas/util/templateData'
import '@canvas/media-comments/jquery/mediaCommentThumbnail'
import '@canvas/media-comments' /* mediaComment */
import axios from '@canvas/axios'
import {camelizeProperties} from '@canvas/convert-case'
import React from 'react'
import ReactDOM from 'react-dom'
import gradingPeriodSetsApi from '@canvas/grading/jquery/gradingPeriodSetsApi'
import htmlEscape from '@instructure/html-escape'
import {useScope as useI18nScope} from '@canvas/i18n'
import round from '@canvas/round'
import numberHelper from '@canvas/i18n/numberHelper'
import CourseGradeCalculator from '@canvas/grading/CourseGradeCalculator'
import {scopeToUser} from '@canvas/grading/EffectiveDueDates'
import {scoreToLetterGrade} from '@instructure/grading-utils'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import StatusPill from '@canvas/grading-status-pill'
import GradeSummaryManager from '../react/GradeSummary/GradeSummaryManager'
import SelectMenuGroup from '../react/SelectMenuGroup'
import SubmissionCommentsTray from '../react/SubmissionCommentsTray'
import ClearBadgeCountsButton from '../react/ClearBadgeCountsButton'
import {scoreToPercentage, scoreToScaledPoints} from '@canvas/grading/GradeCalculationHelper'
import useStore from '../react/stores'
import replaceTags from '@canvas/util/replaceTags'

const I18n = useI18nScope('gradingGradeSummary')

const SUBMISSION_UNREAD_PREFIX = 'submission_unread_dot_'

const GradeSummary = {
  getSelectedGradingPeriodId() {
    const currentGradingPeriodId = ENV.current_grading_period_id

    if (!currentGradingPeriodId || currentGradingPeriodId === '0') {
      return null
    }

    return currentGradingPeriodId
  },

  getAssignmentId($assignment) {
    return $assignment.getTemplateData({textValues: ['assignment_id']}).assignment_id
  },

  parseScoreText(text, numericalDefault, formattedDefault) {
    const defaultNumericalValue = typeof numericalDefault === 'number' ? numericalDefault : null
    const defaultFormattedValue = typeof formattedDefault === 'string' ? formattedDefault : '-'
    let numericalValue = numberHelper.parse(text)
    numericalValue =
      numericalValue === undefined || Number.isNaN(numericalValue)
        ? defaultNumericalValue
        : numericalValue
    return {
      numericalValue,
      formattedValue: GradeFormatHelper.formatGrade(numericalValue, {
        defaultValue: defaultFormattedValue,
      }),
    }
  },

  getOriginalScore($assignment) {
    let numericalValue = parseFloat($assignment.find('.original_points').text())
    numericalValue =
      numericalValue === undefined || Number.isNaN(numericalValue) ? null : numericalValue
    return {
      numericalValue,
      formattedValue: $assignment.find('.original_score').text(),
    }
  },

  getOriginalWorkflowState($assignment) {
    return $assignment.find('.submission_status').text().trim()
  },

  onEditWhatIfScore($assignmentScore, $ariaAnnouncer) {
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
    const whatIfScoreText = $assignmentScore
      .parents('.student_assignment')
      .find('.what_if_score')
      .text()
    const score = GradeSummary.parseScoreText(whatIfScoreText, 0, '0')
    $('#grade_entry').val(score.formattedValue).show().focus().select()
  },

  onScoreChange($assignment, options) {
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
      const url = replaceTags(
        $('.update_submission_url').attr('href'),
        'assignment_id',
        assignmentId
      )
      // if the original score was entered, remove the student entered score
      const scoreForUpdate = isChanged ? score.numericalValue : null
      $.ajaxJSON(
        url,
        'PUT',
        {'submission[student_entered_score]': scoreForUpdate},
        data => {
          const updatedData = {student_entered_score: data.submission.student_entered_score}
          $assignment.fillTemplateData({data: updatedData})
        },
        $.noop
      )
    }

    $('#grade_entry').hide().appendTo($('body'))

    const $grade = $assignment.find('.grade')

    if (score.numericalValue == null) {
      $grade.html($grade.data('originalValue'))
    } else {
      $grade.html(htmlEscape(score.formattedValue))
    }

    addTooltipElementForAssignment($assignment)
    const $assignmentScore = $assignment.find('.assignment_score')
    const $scoreTeaser = $assignmentScore.find('.score_teaser')

    if (isChanged) {
      $assignmentScore.attr('title', '')
      $scoreTeaser.text(I18n.t('This is a What-If score'))
      const $revertScore = $('#revert_score_template').clone(true).attr('id', '').show()
      $assignmentScore.find('.score_holder').append($revertScore)
      $grade.addClass('changed')

      // this is to distinguish between the revert_all_scores_link in the right nav and
      // the revert arrows within the grade_summary page grid
      if (options.refocus) {
        setTimeout(() => {
          $assignment.find('.revert_score_link').focus()
        }, 0)
      }
    } else {
      setTooltipForScore($assignment)
      $assignmentScore.attr('title', I18n.t('Click to test a different score'))
      $grade.removeClass('changed')
      $assignment.find('.revert_score_link').remove()

      if (options.refocus) {
        setTimeout(() => {
          $assignment.find('.grade').focus()
        }, 0)
      }
    }

    if (!isChanged) {
      const $screenreaderLinkClone = $assignment.find('.grade').data('screenreader_link')
      $assignment.find('.grade').prepend($screenreaderLinkClone)
    }

    GradeSummary.updateScoreForAssignment(assignmentId, score.numericalValue, 'graded')
    GradeSummary.updateStudentGrades()
  },

  onScoreRevert($assignment, options) {
    const $assignmentScore = $assignment.find('.assignment_score')
    const $grade = $assignmentScore.find('.grade')
    const opts = {refocus: true, skipEval: false, ...options}
    const score = GradeSummary.getOriginalScore($assignment)
    let title

    if (score.numericalValue == null) {
      score.formattedValue = GradeSummary.parseScoreText(null).formattedValue
    }

    if ($assignment.data('muted')) {
      title = I18n.t('Instructor has not posted this grade')
      // xsslint safeString.identifier title
      $grade.html(`<i class="icon-off" aria-hidden="true" title="${title}"></i>`)
    } else if ($assignment.data('pending_quiz')) {
      title = I18n.t('Instructor has not posted this grade')
      // xsslint safeString.identifier title
      $grade.html(`<i class="icon-quiz" aria-hidden="true" title="${title}"></i>`)
    } else {
      title = I18n.t('Click to test a different score')
      $grade.text(score.formattedValue)
    }

    setTooltipForScore($assignment)

    $assignment.find('.what_if_score').text(score.formattedValue)
    $assignment.find('.revert_score_link').remove()
    $assignment.find('.score_value').text(score.formattedValue)
    $assignmentScore.attr('title', title)
    $grade.removeClass('changed')

    const assignmentId = $assignment.getTemplateValue('assignment_id')
    const workflowState = GradeSummary.getOriginalWorkflowState($assignment)
    GradeSummary.updateScoreForAssignment(assignmentId, score.numericalValue, workflowState)
    if (!opts.skipEval) {
      GradeSummary.updateStudentGrades()
    }

    const $screenreaderLinkClone = $assignment.find('.grade').data('screenreader_link')
    $grade.prepend($screenreaderLinkClone)

    if (opts.refocus) {
      setTimeout(() => {
        $assignment.find('.grade').focus()
      }, 0)
    }
  },
}

function addTooltipElementForAssignment($assignment) {
  const $grade = $assignment.find('.grade')
  let $tooltipWrapRight
  let $tooltipScoreTeaser

  $tooltipWrapRight = $grade.find('.tooltip_wrap right')

  if ($tooltipWrapRight.length === 0) {
    $tooltipWrapRight = $('<span class="tooltip_wrap right"></span>')
    $grade.append($tooltipWrapRight)

    $tooltipScoreTeaser = $tooltipWrapRight.find('.tooltip_text score_teaser')

    if ($tooltipScoreTeaser.length === 0) {
      $tooltipScoreTeaser = $('<span class="tooltip_text score_teaser"></span>')
      $tooltipWrapRight.append($tooltipScoreTeaser)
    }
  }
}

function setTooltipForScore($assignment) {
  let tooltipText

  if ($assignment.data('muted')) {
    tooltipText = I18n.t('Instructor has not posted this grade')
  } else {
    tooltipText = I18n.t('Click to test a different score')
  }

  addTooltipElementForAssignment($assignment)
  const $tooltipScoreTeaser = $assignment.find('.tooltip_text.score_teaser')
  $tooltipScoreTeaser.text(tooltipText)
}

function getGradingPeriodSet() {
  if (ENV.grading_period_set) {
    return gradingPeriodSetsApi.deserializeSet(ENV.grading_period_set)
  }
  return null
}

function calculateGrades() {
  let grades

  if (ENV.effective_due_dates && ENV.grading_period_set) {
    grades = CourseGradeCalculator.calculate(
      ENV.submissions,
      ENV.assignment_groups,
      ENV.group_weighting_scheme,
      ENV.grade_calc_ignore_unposted_anonymous_enabled,
      getGradingPeriodSet(),
      scopeToUser(ENV.effective_due_dates, ENV.student_id)
    )
  } else {
    grades = CourseGradeCalculator.calculate(
      ENV.submissions,
      ENV.assignment_groups,
      ENV.group_weighting_scheme,
      ENV.grade_calc_ignore_unposted_anonymous_enabled
    )
  }

  const selectedGradingPeriodId = GradeSummary.getSelectedGradingPeriodId()
  if (selectedGradingPeriodId) {
    return grades.gradingPeriods[selectedGradingPeriodId]
  }

  return grades
}

function canBeConvertedToGrade(score, possible) {
  return possible > 0 && score !== undefined && !Number.isNaN(score)
}

function calculatePercentGrade(score, possible) {
  const percentGrade = scoreToPercentage(score, possible)
  return round(percentGrade, round.DEFAULT)
}

function formatPercentGrade(percentGrade) {
  return I18n.n(percentGrade, {percentage: true})
}

function calculateGrade(score, possible) {
  if (canBeConvertedToGrade(score, possible)) {
    return formatPercentGrade(calculatePercentGrade(score, possible))
  }

  return I18n.t('N/A')
}

function subtotalByGradingPeriod() {
  const gpset = ENV.grading_period_set
  const gpselected = GradeSummary.getSelectedGradingPeriodId()
  return (!gpselected || gpselected === 0) && gpset && gpset.weighted
}

function calculateSubtotals(byGradingPeriod, calculatedGrades, currentOrFinal) {
  const subtotals = []
  let params
  if (byGradingPeriod) {
    params = {
      bins: ENV.grading_periods,
      grades: calculatedGrades.gradingPeriods,
      elementIdPrefix: '#submission_period',
    }
  } else {
    params = {
      bins: ENV.assignment_groups,
      grades: calculatedGrades.assignmentGroups,
      elementIdPrefix: '#submission_group',
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
      let subtotal
      if (ENV.course_active_grading_scheme && ENV.course_active_grading_scheme.points_based) {
        const scoreText = I18n.n(grade.score, {precision: round.DEFAULT})
        const possibleText = I18n.n(grade.possible, {precision: round.DEFAULT})

        subtotal = {
          teaserText: `${scoreText} / ${possibleText}`,
          gradeText: formatScaledPointsGrade(
            scoreToScaledPoints(
              grade.score,
              grade.possible,
              ENV.course_active_grading_scheme.scaling_factor
            ),
            ENV.course_active_grading_scheme.scaling_factor
          ),
          rowElementId: `${params.elementIdPrefix}-${binId}`,
        }
      } else {
        const scoreText = I18n.n(grade.score, {precision: round.DEFAULT})
        const possibleText = I18n.n(grade.possible, {precision: round.DEFAULT})
        subtotal = {
          teaserText: `${scoreText} / ${possibleText}`,
          gradeText: calculateGrade(grade.score, grade.possible),
          rowElementId: `${params.elementIdPrefix}-${binId}`,
        }
      }
      subtotals.push(subtotal)
    }
  }
  return subtotals
}

function finalGradePointsPossibleText(groupWeightingScheme, scoreWithPointsPossible) {
  if (groupWeightingScheme === 'percent') {
    return ''
  }

  const gradingPeriodId = GradeSummary.getSelectedGradingPeriodId()
  const gradingPeriodSet = getGradingPeriodSet()
  if (gradingPeriodId == null && gradingPeriodSet && gradingPeriodSet.weighted) {
    return ''
  }

  return scoreWithPointsPossible
}

function formatScaledPointsGrade(scaledPointsEarned, scaledPointsPossible) {
  return canBeConvertedToGrade(scaledPointsEarned, scaledPointsPossible)
    ? `${I18n.n(scaledPointsEarned, {precision: 1})} / ${I18n.n(scaledPointsPossible, {
        precision: 1,
      })}`
    : I18n.t('N/A')
}

function calculateTotals(calculatedGrades, currentOrFinal, groupWeightingScheme) {
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
  const scoreAsPoints = `${I18n.n(finalScore, {precision: round.DEFAULT})} / ${I18n.n(
    finalPossible,
    {precision: round.DEFAULT}
  )}`
  const scoreAsPercent = calculateGrade(finalScore, finalPossible)

  let finalGrade
  let teaserText

  if (gradingSchemeEnabled() || ENV.restrict_quantitative_data) {
    const scoreToUse = overrideScorePresent()
      ? ENV.effective_final_score
      : calculatePercentGrade(finalScore, finalPossible)

    const grading_scheme = ENV.course_active_grading_scheme?.data
    const letterGrade = scoreToLetterGrade(scoreToUse, grading_scheme) || I18n.t('N/A')

    $('.final_grade .letter_grade').text(GradeFormatHelper.replaceDashWithMinus(letterGrade))
  }

  if (!gradeChanged && overrideScorePresent()) {
    if (gradingSchemeEnabled() && ENV.course_active_grading_scheme?.points_based) {
      const scaledPointsPossible = ENV.course_active_grading_scheme.scaling_factor
      const scaledPointsOverride = scoreToScaledPoints(
        (ENV.effective_final_score / 100.0) * finalPossible,
        finalPossible,
        ENV.course_active_grading_scheme.scaling_factor
      )
      finalGrade = formatScaledPointsGrade(scaledPointsOverride, scaledPointsPossible)
      teaserText = scoreAsPoints
    } else {
      finalGrade = formatPercentGrade(ENV.effective_final_score)
      teaserText = scoreAsPoints
    }
  } else if (gradingSchemeEnabled() && ENV.course_active_grading_scheme?.points_based) {
    const scaledPointsEarned = scoreToScaledPoints(
      finalScore,
      finalPossible,
      ENV.course_active_grading_scheme.scaling_factor
    )
    const scaledPointsPossible = ENV.course_active_grading_scheme.scaling_factor
    finalGrade = formatScaledPointsGrade(scaledPointsEarned, scaledPointsPossible)
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

  if (ENV?.final_override_custom_grade_status_id) {
    $finalGradeRow
      .find('.status')
      .html('')
      .append(
        `<span class='submission-custom-grade-status-pill-${ENV.final_override_custom_grade_status_id}'></span>`
      )

    const matchingCustomStatus = ENV?.custom_grade_statuses?.find(
      status => status.id === ENV.final_override_custom_grade_status_id
    )
    if (matchingCustomStatus?.allow_final_grade_value === false) {
      $finalGradeRow.find('.grade').text('-')
    }
  }

  const pointsPossibleText = finalGradePointsPossibleText(groupWeightingScheme, scoreAsPoints)
  $finalGradeRow.find('.points_possible').text(pointsPossibleText)

  if (groupWeightingScheme === 'percent') {
    $finalGradeRow.find('.score_teaser').hide()
  }

  if (gradeChanged) {
    // User changed their points for an assignment => let's let them know their updated points
    const msg = I18n.t('Based on What-If scores, the new total is now %{grade}', {
      grade: finalGrade,
    })
    $.screenReaderFlashMessageExclusive(msg)
  }

  $('.revert_all_scores').showIf($('#grades_summary .revert_score_link').length > 0)
}

// This element is only rendered by the erb if the course has enabled grading
// schemes.
function gradingSchemeEnabled() {
  return ENV.course_active_grading_scheme
}

function overrideScorePresent() {
  return ENV.effective_final_score != null
}

function updateStudentGrades() {
  const droppedMessage = I18n.t(
    'This assignment is dropped and will not be considered in the total calculation'
  )
  const ignoreUngradedSubmissions = $('#only_consider_graded_assignments').prop('checked')
  const currentOrFinal = ignoreUngradedSubmissions ? 'current' : 'final'
  const groupWeightingScheme = ENV.group_weighting_scheme
  const includeTotal = !ENV.exclude_total

  const calculatedGrades = calculateGrades()

  $('.dropped').attr('aria-label', '')
  $('.dropped').attr('title', '')

  // mark dropped assignments
  $('.student_assignment').find('.points_possible').attr('aria-label', '')

  forEach(calculatedGrades.assignmentGroups, grades => {
    forEach(grades[currentOrFinal].submissions, submission => {
      $(`#submission_${submission.submission.assignment_id}`).toggleClass(
        'dropped',
        !!submission.drop
      )
    })
  })

  $('.dropped').attr('aria-label', droppedMessage)
  $('.dropped').attr('title', droppedMessage)

  if (includeTotal) {
    calculateTotals(calculatedGrades, currentOrFinal, groupWeightingScheme)
  }
}

function updateScoreForAssignment(assignmentId, score, workflowStateOverride) {
  const submission = find(ENV.submissions, s => `${s.assignment_id}` === `${assignmentId}`)

  if (submission) {
    submission.score = score
    submission.workflow_state = workflowStateOverride ?? submission.workflow_state
  } else {
    ENV.submissions.push({assignment_id: assignmentId, score})
  }
}

function bindShowAllDetailsButton($ariaAnnouncer) {
  $('#show_all_details_button').click(event => {
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
  return axios.post(ENV.save_assignment_order_url, {assignment_order: order})
}

function coursesWithGrades() {
  return ENV.courses_with_grades.map(course => camelizeProperties(course))
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
    selectedCourseID: getCourseId(),
    selectedGradingPeriodID: ENV.current_grading_period_id,
    selectedStudentID: ENV.student_id,
    students: ENV.students,
  }
}

function getCourseId() {
  return ENV.context_asset_string.match(/.*_(\d+)$/)[1]
}

function renderSelectMenuGroup() {
  ReactDOM.render(
    <SelectMenuGroup {...GradeSummary.getSelectMenuGroupProps()} />,
    document.getElementById('GradeSummarySelectMenuGroup')
  )
}

function renderGradeSummaryTable() {
  ReactDOM.render(<GradeSummaryManager />, document.getElementById('grade-summary-react'))
}

function handleSubmissionsCommentTray(assignmentId) {
  const {submissionTrayAssignmentId, submissionTrayOpen} = useStore.getState()

  if (submissionTrayAssignmentId === assignmentId && submissionTrayOpen) {
    useStore.setState({submissionTrayOpen: false, submissionTrayAssignmentId: undefined})
    $(`#comments_thread_${submissionTrayAssignmentId}`).removeClass('comment_thread_show_print')
    $(`#submission_${submissionTrayAssignmentId}`).removeClass('selected-assignment')
  } else {
    $(`#comments_thread_${submissionTrayAssignmentId}`).removeClass('comment_thread_show_print')
    $(`#submission_${submissionTrayAssignmentId}`).removeClass('selected-assignment')
    $(`#comments_thread_${assignmentId}`).addClass('comment_thread_show_print')
    $(`#submission_${assignmentId}`).addClass('selected-assignment')
    const {attempts, assignmentUrl} = getSubmissionCommentsTrayProps(assignmentId)
    useStore.setState({
      submissionCommentsTray: {attempts},
      submissionTrayOpen: true,
      submissionTrayAssignmentId: assignmentId,
      submissionTrayAssignmentUrl: assignmentUrl,
    })
  }
}

function getSubmissionCommentsTrayProps(assignmentId) {
  const matchingSubmission = ENV.submissions.find(x => x.assignment_id === assignmentId)
  const {submission_comments, assignment_url: assignmentUrl} = matchingSubmission
  const attempts = submission_comments.reduce((attemptsMessages, comment) => {
    const currentAttempt = comment.attempt < 1 ? 1 : comment.attempt

    if (attemptsMessages[currentAttempt]) {
      attemptsMessages[currentAttempt].push(comment)
    } else {
      attemptsMessages[currentAttempt] = [comment]
    }

    return attemptsMessages
  }, {})
  return {
    attempts,
    assignmentUrl,
  }
}

function renderSubmissionCommentsTray() {
  ReactDOM.unmountComponentAtNode(document.getElementById('GradeSummarySubmissionCommentsTray'))
  ReactDOM.render(
    <SubmissionCommentsTray
      onDismiss={() => {
        const {submissionTrayAssignmentId} = useStore.getState()
        $(`#comments_thread_${submissionTrayAssignmentId}`).removeClass('comment_thread_show_print')
        $(`#submission_${submissionTrayAssignmentId}`).removeClass('selected-assignment')
      }}
    />,
    document.getElementById('GradeSummarySubmissionCommentsTray')
  )
}

function renderClearBadgeCountsButton() {
  ReactDOM.unmountComponentAtNode(document.getElementById('ClearBadgeCountsButton'))
  const userId = ENV.student_id
  const courseId = ENV.course_id ?? ENV.context_asset_string.replace('course_', '')
  ReactDOM.render(
    <ClearBadgeCountsButton userId={userId} courseId={courseId} />,
    document.getElementById('ClearBadgeCountsButton')
  )
}

function setup() {
  $(document).ready(function () {
    GradeSummary.updateStudentGrades()
    const showAllWhatIfButton = $(this).find('#student-grades-whatif button')
    const revertButton = $(this).find('#revert-all-to-actual-score')
    const $ariaAnnouncer = $(this).find('#aria-announcer')

    $('.revert_all_scores_link').click(event => {
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
    $(
      '.toggle_comments_link, .toggle_score_details_link, ' +
        '.toggle_rubric_assessments_link, .toggle_final_grade_info'
    ).click(function (event) {
      event.preventDefault()
      const $row = $(`#${$(this).attr('aria-controls')}`)
      const originEl = this

      $(originEl).attr('aria-expanded', $row.css('display') === 'none')
      $row.toggle()

      if ($row.css('display') !== 'none') {
        $row.find('.screenreader-toggle').focus()
      }
    })

    $('.toggle_comments_link').on('click', function (event) {
      event.preventDefault()
      const $unreadIcon = $(this).find('.comment_dot')

      if ($unreadIcon.length) {
        const mark_comments_read_url = $unreadIcon.data('href')
        $.ajaxJSON(mark_comments_read_url, 'PUT', {}, () => {})
        $unreadIcon.remove()
      }

      const assignmentIdPrefix = 'assignment_comment_'
      const eventId = event.currentTarget.id
      const assignmentId = eventId.substring(assignmentIdPrefix.length)
      handleSubmissionsCommentTray(assignmentId)
    })

    $('.toggle_rubric_assessments_link').on('click', function (event) {
      event.preventDefault()
      const $unreadIcon = $(this).find('.rubric_dot')

      if ($unreadIcon.length) {
        const mark_rubric_comments_read_url = $unreadIcon.data('href')
        $.ajaxJSON(mark_rubric_comments_read_url, 'PUT', {}, () => {})
        $unreadIcon.remove()
      }
    })

    if (ENV.assignments_2_student_enabled && $('.unread_dot.grade_dot').length) {
      const unreadSubmissions = $('.unread_dot.grade_dot').toArray()
      const unreadSubmissionIds = unreadSubmissions.map(x => {
        return $(x).attr('id').substring(SUBMISSION_UNREAD_PREFIX.length)
      })
      const url = `/api/v1/courses/${getCourseId()}/submissions/bulk_mark_read`
      const data = {
        submissionIds: unreadSubmissionIds,
      }
      axios.put(url, data)
    }

    $('.screenreader-toggle').click(function (event) {
      event.preventDefault()
      const ariaControl = $(this).data('aria')
      const originEl = $(`a[aria-controls='${ariaControl}']`)

      $(originEl).attr('aria-expanded', false)
      $(originEl).focus()
      $(this).closest('.rubric_assessments, .comments').hide()
    })

    function editWhatIfScore(event) {
      if (event.type === 'click' || event.keyCode === 13) {
        if (
          $('#grades_summary.editable').length === 0 ||
          $(this).find('#grade_entry').length > 0 ||
          $(event.target).closest('.revert_score_link').length > 0
        ) {
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
        const val = $(this)
          .parents('.student_assignment')
          .addClass('dont_update')
          .find('.original_score')
          .text()
        $(this)
          .val(val || '')[0]
          .blur()
      }
    })

    $('#grades_summary .student_assignment').bind('score_change', function (_event, options) {
      GradeSummary.onScoreChange($(this), options)
    })

    $('#grade_entry').blur(function () {
      const $assignment = $(this).parents('.student_assignment')
      $assignment.triggerHandler('score_change', {update: true, refocus: true})
    })

    $('#grades_summary').on('click', '.revert_score_link', function (event, options) {
      event.preventDefault()
      event.stopPropagation()

      GradeSummary.onScoreRevert($(this).parents('.student_assignment'), options)
    })

    $('#grades_summary:not(.editable) .assignment_score').css('cursor', 'default')

    $('#grades_summary tr').hover(
      function () {
        $(this).find('th.title .context').addClass('context_hover')
      },
      function () {
        $(this).find('th.title .context').removeClass('context_hover')
      }
    )

    $('.show_guess_grades_link').click(() => {
      $('#grades_summary .student_entered_score').each(function () {
        const score = GradeSummary.parseScoreText($(this).text())
        if (score.numericalValue != null) {
          const $assignment = $(this).parents('.student_assignment')
          $assignment.find('.what_if_score').text(score.formattedValue)
          $assignment.find('.score_value').hide()
          $assignment.triggerHandler('score_change', {update: false, refocus: false})
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

    $(document).on('click', '.play_comment_link', function (event) {
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

    $('#only_consider_graded_assignments')
      .change(() => {
        GradeSummary.updateStudentGrades()
      })
      .triggerHandler('change')

    bindShowAllDetailsButton($ariaAnnouncer)
    StatusPill.renderPills(ENV.custom_grade_statuses)
  })
}

export default lodashExtend(GradeSummary, {
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
  renderGradeSummaryTable,
  getSubmissionCommentsTrayProps,
  handleSubmissionsCommentTray,
  renderSubmissionCommentsTray,
  renderClearBadgeCountsButton,
  updateScoreForAssignment,
  updateStudentGrades,
})
