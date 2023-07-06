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
import React, {useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  DeprecatedGradingScheme,
  FinalGradeOverride,
  GradeEntryOptions,
} from '@canvas/grading/grading'
import {TextInput} from '@instructure/ui-text-input'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import {updateFinalGradeOverride} from '@canvas/grading/FinalGradeOverrideApi'
import {ApiCallStatus} from '../../../types'
import {scoreToGrade} from '@canvas/grading/GradingSchemeHelper'

const I18n = useI18nScope('enhanced_individual_gradebook')
type Props = {
  finalGradeOverride?: FinalGradeOverride
  gradingScheme?: DeprecatedGradingScheme | null
  enrollmentId: string
  onSubmit: (finalGradeOverride: FinalGradeOverride) => void
  gradingPeriodId?: string
  pointsBasedGradingSchemesFeatureEnabled: boolean
}
function FinalGradeOverrideTextBox({
  finalGradeOverride,
  gradingScheme,
  enrollmentId,
  onSubmit,
  gradingPeriodId,
  pointsBasedGradingSchemesFeatureEnabled,
}: Props) {
  const [inputValue, setInputValue] = useState<string>('')
  const [finalGradeOverridePercentage, setFinalGradeOverridePercentage] = useState<string>('')
  const [apiCallStatus, setApiCallStatus] = useState<ApiCallStatus>(ApiCallStatus.NOT_STARTED)

  useEffect(() => {
    const percentage = gradingPeriodId
      ? finalGradeOverride?.gradingPeriodGrades?.[gradingPeriodId]?.percentage
      : finalGradeOverride?.courseGrade?.percentage
    if (percentage == null) {
      setFinalGradeOverridePercentage('')
      setInputValue('')
    } else if (gradingScheme && gradingScheme.data.length > 0) {
      const inputVal = scoreToGrade(percentage, gradingScheme.data)
      setInputValue(inputVal || '')
      if (!gradingScheme.pointsBased) {
        // hide all percentages if this scheme is points based
        setFinalGradeOverridePercentage(
          GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'})
        )
      }
    } else {
      setInputValue(GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'}))
      setFinalGradeOverridePercentage('')
    }
  }, [finalGradeOverride, gradingPeriodId, gradingScheme])

  const handleFinalGradeOverrideChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(event.target.value)
  }
  const handleFinalGradeOverrideBlur = async () => {
    const options: GradeEntryOptions = {pointsBasedGradingSchemesFeatureEnabled}
    if (gradingScheme) {
      options.gradingScheme = gradingScheme
    }
    const percentage = gradingPeriodId
      ? finalGradeOverride?.gradingPeriodGrades?.[gradingPeriodId]?.percentage
      : finalGradeOverride?.courseGrade?.percentage
    const gradeOverrideEntry = new GradeOverrideEntry(options)
    const enteredGrade = gradeOverrideEntry.parseValue(inputValue)
    const existingGrade = gradeOverrideEntry.parseValue(percentage != null ? percentage : {})
    if (
      !enteredGrade.valid ||
      !gradeOverrideEntry.hasGradeChanged(existingGrade, enteredGrade) ||
      enteredGrade.grade?.percentage == null
    ) {
      if (existingGrade.grade?.schemeKey) {
        setInputValue(existingGrade.grade?.schemeKey)
      } else {
        setInputValue(
          existingGrade.grade?.percentage ? String(existingGrade.grade?.percentage) : ''
        )
      }
      return
    }
    const castedEnteredGrade = {percentage: enteredGrade.grade.percentage}
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
      <TextInput
        display="inline-block"
        renderLabel={<ScreenReaderContent>{I18n.t('Final Grade Override')}</ScreenReaderContent>}
        value={inputValue}
        onChange={handleFinalGradeOverrideChange}
        onBlur={handleFinalGradeOverrideBlur}
        width="14rem"
        disabled={apiCallStatus === ApiCallStatus.PENDING}
      />
      <View as="span" margin="0 0 0 xx-small">
        {finalGradeOverridePercentage}
      </View>
    </>
  )
}

export default FinalGradeOverrideTextBox
