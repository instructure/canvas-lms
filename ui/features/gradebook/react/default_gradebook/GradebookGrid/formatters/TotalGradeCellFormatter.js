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

import $ from 'jquery'
import _ from 'underscore'
import round from 'round'
import I18n from 'i18n!gradebook'
import {scoreToGrade} from '@canvas/grading/GradingSchemeHelper'
import {scoreToPercentage} from '@canvas/grading/GradeCalculationHelper'
import htmlEscape from 'html-escape'
import '@canvas/jquery/jquery.instructure_misc_helpers' // $.toSentence

function getGradePercentage(score, pointsPossible) {
  const grade = scoreToPercentage(score, pointsPossible)
  return round(grade, round.DEFAULT)
}

function buildHiddenAssignmentsWarning() {
  return {
    icon: 'icon-off',
    warningText: I18n.t(
      "This grade differs from the student's view of the grade because some assignment grades are not yet posted"
    )
  }
}

function buildInvalidAssignmentGroupsWarning(invalidAssignmentGroups) {
  const names = invalidAssignmentGroups.map(group => htmlEscape(group.name))
  const warningText = I18n.t(
    {
      one: 'Score does not include %{groups} because it has no points possible',
      other: 'Score does not include %{groups} because they have no points possible'
    },
    {
      count: names.length,
      groups: $.toSentence(names)
    }
  )

  return {
    icon: 'icon-warning final-warning',
    warningText
  }
}

function buildNoPointsPossibleWarning() {
  return {
    icon: 'icon-warning final-warning',
    warningText: I18n.t("Can't compute score until an assignment has points possible")
  }
}

// xsslint safeString.property score possible warningText icon letterGrade
function render(options) {
  let tooltip = ''
  let warningIcon = ''
  let grade
  let letterGrade = ''

  if (!options.hideTooltip) {
    let tooltipContent = '–'

    if (options.warning) {
      tooltipContent = `<div class="total-column-tooltip">${options.warning.warningText}</div>`
    } else if (!options.showPointsNotPercent) {
      tooltipContent = `${options.score} / ${options.possible}`
    } else if (options.possible) {
      tooltipContent = options.percentage
    }

    // xsslint safeString.identifier tooltipContent
    tooltip = `<div class="gradebook-tooltip">${tooltipContent}</div>`
  }

  if (options.warning) {
    warningIcon = `<i class="${options.warning.icon}"></i>`
  }

  if (options.showPointsNotPercent) {
    grade = options.score
  } else {
    grade = options.possible ? options.percentage : '–'
  }

  if (options.letterGrade) {
    const escapedGrade = _.escape(options.letterGrade)

    // xsslint safeString.identifier escapedGrade
    letterGrade = `<span class="letter-grade-points">${escapedGrade}</span>`
  }

  // xsslint safeString.identifier tooltip warningIcon grade letterGrade
  return `
    <div class="gradebook-cell">
      ${tooltip}
      <span class="grades">
        <span class="percentage">
          ${warningIcon}
          ${grade}
        </span>
        ${letterGrade}
      </span>
    </div>
  `
}

export default class TotalGradeCellFormatter {
  constructor(gradebook) {
    this.options = {
      getTotalPointsPossible() {
        return gradebook.getTotalPointsPossible()
      },
      gradesAreWeighted: gradebook.weightedGrades(),
      getGradingStandard() {
        return gradebook.options.grading_standard
      },
      listInvalidAssignmentGroups() {
        return gradebook.listInvalidAssignmentGroups()
      },
      listHiddenAssignments(studentId) {
        return gradebook.listHiddenAssignments(studentId)
      },
      shouldShowPoints() {
        return gradebook.options.show_total_grade_as_points
      }
    }
  }

  render = (_row, _cell, grade /* value */, _columnDef, student /* dataContext */) => {
    if (grade == null) {
      return ''
    }

    let percentage = getGradePercentage(grade.score, grade.possible)
    percentage = Number.isFinite(percentage) ? percentage : 0

    let possible = round(grade.possible, round.DEFAULT)
    possible = possible ? I18n.n(possible) : possible

    let letterGrade
    if (grade.possible && this.options.getGradingStandard()) {
      letterGrade = scoreToGrade(percentage, this.options.getGradingStandard())
    }

    let warning
    if (this.options.listHiddenAssignments(student.id).length > 0) {
      warning = buildHiddenAssignmentsWarning()
    }

    if (!warning) {
      const invalidAssignmentGroups = this.options.listInvalidAssignmentGroups()
      if (invalidAssignmentGroups.length > 0) {
        warning = buildInvalidAssignmentGroupsWarning(invalidAssignmentGroups)
      }
    }

    if (!warning && this.options.getTotalPointsPossible() === 0) {
      warning = buildNoPointsPossibleWarning()
    }

    const options = {
      hideTooltip: this.options.gradesAreWeighted && !warning,
      letterGrade,
      percentage: I18n.n(round(percentage, round.DEFAULT), {percentage: true}),
      possible,
      score: I18n.n(round(grade.score, round.DEFAULT)),
      showPointsNotPercent: this.options.shouldShowPoints(),
      warning
    }

    return render(options)
  }
}
