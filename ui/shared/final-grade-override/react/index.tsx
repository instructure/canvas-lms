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

import React, {useState, useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {
  DeprecatedGradingScheme,
  FinalGradeOverride,
  GradeEntryOptions,
} from '@canvas/grading/grading.d'
import {TextInput} from '@instructure/ui-text-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import GradeOverrideInfo from '@canvas/grading/GradeEntry/GradeOverrideInfo'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {scoreToGrade} from '@instructure/grading-utils'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('enhanced_individual_gradebook')

export type FinalGradeOverrideTextBoxProps = {
  finalGradeOverride?: FinalGradeOverride
  gradingScheme?: DeprecatedGradingScheme | null
  width?: string
  onGradeChange: (grade: GradeOverrideInfo) => void
  gradingPeriodId?: string | null
  disabled?: boolean
  showPercentageLabel?: boolean
}
export function FinalGradeOverrideTextBox({
  finalGradeOverride,
  gradingScheme,
  onGradeChange,
  width = '14rem',
  gradingPeriodId,
  disabled = false,
  showPercentageLabel = false,
}: FinalGradeOverrideTextBoxProps) {
  const [inputValue, setInputValue] = useState<string>('')
  const [finalGradeOverridePercentage, setFinalGradeOverridePercentage] = useState<string>('')

  useEffect(() => {
    const percentage = gradingPeriodId
      ? finalGradeOverride?.gradingPeriodGrades?.[gradingPeriodId]?.percentage
      : finalGradeOverride?.courseGrade?.percentage
    if (percentage == null) {
      setFinalGradeOverridePercentage('')
      setInputValue('')
    } else if (gradingScheme && gradingScheme.data.length > 0) {
      const grade = scoreToGrade(percentage, gradingScheme.data)
      const inputVal = GradeFormatHelper.replaceDashWithMinus(grade)
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
    const options: GradeEntryOptions = {}
    if (gradingScheme?.data && gradingScheme.data.length > 0) {
      options.gradingScheme = gradingScheme
    }
    const percentage = gradingPeriodId
      ? finalGradeOverride?.gradingPeriodGrades?.[gradingPeriodId]?.percentage
      : finalGradeOverride?.courseGrade?.percentage
    const gradeOverrideEntry = new GradeOverrideEntry(options)
    const oldGrade = gradeOverrideEntry.parseValue(percentage, false)
    const newGrade = gradeOverrideEntry.parseValue(inputValue, true)

    const gradeHasChanged = gradeOverrideEntry.hasGradeChanged(oldGrade, newGrade)
    if (!newGrade.valid || newGrade.grade?.percentage == null || !gradeHasChanged) {
      if (oldGrade.grade?.schemeKey) {
        setInputValue(oldGrade.grade?.schemeKey)
      } else {
        setInputValue(
          oldGrade.grade?.percentage
            ? GradeFormatHelper.formatGrade(oldGrade.grade.percentage, {gradingType: 'percent'})
            : ''
        )
      }
      return
    }
    onGradeChange(newGrade)
  }
  return (
    <>
      <TextInput
        display="inline-block"
        renderLabel={<ScreenReaderContent>{I18n.t('Final Grade Override')}</ScreenReaderContent>}
        value={inputValue}
        onChange={handleFinalGradeOverrideChange}
        onBlur={handleFinalGradeOverrideBlur}
        width={width}
        disabled={disabled}
        data-testid="final-grade-override-textbox"
      />
      {showPercentageLabel && (
        <View as="span" margin="0 0 0 xx-small">
          {finalGradeOverridePercentage}
        </View>
      )}
    </>
  )
}

export default FinalGradeOverrideTextBox
