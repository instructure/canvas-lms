// @ts-nocheck
/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import I18n from '@canvas/i18n'

import round from '@canvas/round'
import GradeFormatHelper from '../GradeFormatHelper'
import {gradePointsToPercentage, gradeToScoreLowerBound} from '../GradingSchemeHelper'
import {scoreToGrade} from '@instructure/grading-utils'
import GradeOverride from '../GradeOverride'
import {parseEntryValue} from '../GradeInputHelper'
import GradeOverrideInfo from './GradeOverrideInfo'
import GradeEntry, {EnterGradesAs} from './index'
import type {GradeType, DeprecatedGradingScheme, GradeEntryMode} from '../grading.d'

function schemeKeyForPercentage(percentage, gradingScheme: DeprecatedGradingScheme) {
  if (gradingScheme) {
    const grade = scoreToGrade(percentage, gradingScheme.data)
    return GradeFormatHelper.replaceDashWithMinus(grade)
  }
  return null
}

export default class GradeOverrideEntry extends GradeEntry {
  get enterGradesAs(): GradeEntryMode {
    // TODO: GRADE-1926 Return `EnterGradesAs.GRADING_SCHEME` when a grading scheme is used
    return EnterGradesAs.PERCENTAGE
  }

  formatGradeInfoForDisplay(gradeInfo) {
    const {valid, enteredValue, grade} = gradeInfo
    if (!valid) {
      return enteredValue
    }

    if (grade == null || grade.percentage == null) {
      return GradeFormatHelper.UNGRADED
    }

    if (this.gradingScheme != null) {
      return schemeKeyForPercentage(grade.percentage, this.gradingScheme)
    }

    return I18n.n(round(grade.percentage, 2), {
      percentage: true,
      precision: 2,
      strip_insignificant_zeros: true,
    })
  }

  formatGradeInfoForInput({enteredValue, grade, valid}) {
    if (!valid) {
      return enteredValue
    }

    if (grade == null || grade.percentage == null) {
      return ''
    }

    if (this.gradingScheme != null) {
      return schemeKeyForPercentage(grade.percentage, this.gradingScheme)
    }

    return I18n.n(round(grade.percentage, 2), {
      percentage: true,
      precision: 2,
      strip_insignificant_zeros: true,
    })
  }

  gradeInfoFromGrade(grade, inputByUser: boolean) {
    if (!grade) {
      return this.parseValue(null)
    }

    const parseValue = grade.percentage == null ? grade.schemeKey : grade.percentage
    return this.parseValue(parseValue, inputByUser)
  }

  hasGradeChanged(
    assignedGradeInfo,
    currentGradeInfo,
    previousGradeInfo: null | GradeOverrideInfo = null
  ) {
    const effectiveGradeInfo = previousGradeInfo || assignedGradeInfo

    if (currentGradeInfo.grade == null && effectiveGradeInfo.grade == null) {
      return currentGradeInfo.enteredValue !== effectiveGradeInfo.enteredValue
    }

    if (currentGradeInfo.grade == null || effectiveGradeInfo.grade == null) {
      return true
    }

    if (currentGradeInfo.valid !== effectiveGradeInfo.valid) {
      return true
    }

    if (currentGradeInfo.enteredAs === EnterGradesAs.GRADING_SCHEME) {
      return currentGradeInfo.grade.schemeKey !== effectiveGradeInfo.grade.schemeKey
    }

    return currentGradeInfo.grade.percentage !== effectiveGradeInfo.grade.percentage
  }

  parseValue(value, inputByUser: boolean = true): GradeOverrideInfo {
    const gradingScheme: string | {data: DeprecatedGradingScheme[]} = this.options.gradingScheme
    const parseResult = parseEntryValue(value, gradingScheme)

    let enteredAs: null | GradeType = null
    let grade: null | {
      percentage: null | number
      schemeKey: null | string
    } = null
    let valid = parseResult.isCleared

    if (parseResult.isSchemeKey && typeof gradingScheme === 'object') {
      enteredAs = EnterGradesAs.GRADING_SCHEME
      grade = {
        percentage: gradeToScoreLowerBound(parseResult.value, gradingScheme.data),
        schemeKey: String(parseResult.value),
      }
      valid = true
      // points based grading scheme
    } else if (gradingScheme?.pointsBased) {
      // entered percentage or is from backend which should be treated as percentage
      if (parseResult.isPercentage || !inputByUser) {
        enteredAs = EnterGradesAs.PERCENTAGE
        grade = {
          percentage: parseResult.value,
          schemeKey: schemeKeyForPercentage(parseResult.value, gradingScheme),
        }
        valid = true
        // entered points
      } else if (parseResult.isPoints) {
        enteredAs = EnterGradesAs.POINTS
        grade = {
          percentage: gradePointsToPercentage(parseResult.value, gradingScheme),
          schemeKey: null,
        }
        valid = true
      }
      // percentage based grading scheme
    } else if (parseResult.isPercentage || parseResult.isPoints) {
      enteredAs = EnterGradesAs.PERCENTAGE
      grade = {
        percentage: parseResult.value,
        schemeKey: schemeKeyForPercentage(parseResult.value, gradingScheme),
      }
      valid = true
      if (gradingScheme && gradingScheme.pointsBased) {
        // points based scheme
        if (inputByUser) {
          // don't allow user to input percents or points for points based scheme
          valid = false
        } else {
          // the initial (ie, saved to server value) in percent format is valid
          valid = true
        }
      } else {
        valid = true
      }
    }

    if (grade != null) {
      grade = new GradeOverride(grade)
    }

    return new GradeOverrideInfo({enteredAs, enteredValue: parseResult.enteredValue, grade, valid})
  }
}
