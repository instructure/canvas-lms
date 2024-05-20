/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import React, {useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {DeprecatedGradingScheme, FinalGradeOverride} from '@canvas/grading/grading.d'
import {updateFinalGradeOverride} from '@canvas/grading/FinalGradeOverrideApi'
import {ApiCallStatus} from '../../../types'
import {FinalGradeOverrideTextBox} from '@canvas/final-grade-override'
import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'

const I18n = useI18nScope('enhanced_individual_gradebook')
type Props = {
  finalGradeOverride?: FinalGradeOverride
  gradingScheme?: DeprecatedGradingScheme | null
  enrollmentId: string
  onSubmit: (finalGradeOverride: FinalGradeOverride) => void
  gradingPeriodId?: string
}
function FinalGradeOverrideContainer({
  finalGradeOverride,
  gradingScheme,
  enrollmentId,
  onSubmit,
  gradingPeriodId,
}: Props) {
  const [apiCallStatus, setApiCallStatus] = useState<ApiCallStatus>(ApiCallStatus.NOT_STARTED)

  const handleFinalGradeOverrideChange = async (grade: GradeOverrideInfo) => {
    if (grade.grade?.percentage == null) {
      return
    }
    const castedEnteredGrade = {percentage: grade.grade.percentage}
    setApiCallStatus(ApiCallStatus.PENDING)
    const updatedScore = await updateFinalGradeOverride(
      enrollmentId,
      gradingPeriodId,
      castedEnteredGrade
    )
    setApiCallStatus(ApiCallStatus.COMPLETED)
    if (updatedScore) {
      if (gradingPeriodId) {
        onSubmit({
          ...finalGradeOverride,
          gradingPeriodGrades: {
            ...finalGradeOverride?.gradingPeriodGrades,
            [gradingPeriodId]: updatedScore,
          },
        })
      } else {
        onSubmit({...finalGradeOverride, courseGrade: updatedScore})
      }
    }
  }
  return (
    <>
      <View as="div">
        <label htmlFor="final-grade-override-input">
          <strong>{I18n.t('Final Grade Override')}</strong>
        </label>
      </View>
      <FinalGradeOverrideTextBox
        finalGradeOverride={finalGradeOverride}
        gradingScheme={gradingScheme}
        gradingPeriodId={gradingPeriodId}
        onGradeChange={handleFinalGradeOverrideChange}
        disabled={apiCallStatus === ApiCallStatus.PENDING}
        showPercentageLabel={true}
      />
    </>
  )
}

export default FinalGradeOverrideContainer
