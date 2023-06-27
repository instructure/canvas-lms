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
import {FinalGradeOverride, GradeEntryOptions, GradingStandard} from '@canvas/grading/grading'
import {TextInput} from '@instructure/ui-text-input'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import GradeOverrideEntry from '@canvas/grading/GradeEntry/GradeOverrideEntry'
import {updateFinalGradeOverride} from '@canvas/grading/FinalGradeOverrideApi'
import {ApiCallStatus} from '../../../types'

const I18n = useI18nScope('enhanced_individual_gradebook')
type Props = {
  finalGradeOverride?: FinalGradeOverride
  gradingStandard?: GradingStandard[] | null
  enrollmentId: string
  onSubmit: (finalGradeOverride: FinalGradeOverride) => void
}
function FinalGradeOverrideTextBox({
  finalGradeOverride,
  gradingStandard,
  enrollmentId,
  onSubmit,
}: Props) {
  const [inputValue, setInputValue] = useState<string>('')
  const [apiCallStatus, setApiCallStatus] = useState<ApiCallStatus>(ApiCallStatus.NOT_STARTED)
  useEffect(() => {
    const percentage = finalGradeOverride?.courseGrade?.percentage
    if (percentage == null) {
      setInputValue('')
      return
    }
    if (gradingStandard) {
      setInputValue('')
      // TODO: handle grading scheme and grading periods
    } else {
      const ret = GradeFormatHelper.formatGrade(percentage, {gradingType: 'percent'})
      setInputValue(ret)
    }
  }, [finalGradeOverride, gradingStandard])

  const handleFinalGradeOverrideChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setInputValue(event.target.value)
  }
  const handleFinalGradeOverrideBlur = async () => {
    const options: GradeEntryOptions = {}
    if (gradingStandard) {
      options.gradingScheme = {data: gradingStandard}
    }
    const gradeOverrideEntry = new GradeOverrideEntry(options)
    const enteredGrade = gradeOverrideEntry.parseValue(inputValue)
    const existingGrade = gradeOverrideEntry.parseValue(
      finalGradeOverride?.courseGrade?.percentage ?? {}
    )
    if (
      !enteredGrade.valid ||
      !gradeOverrideEntry.hasGradeChanged(existingGrade, enteredGrade) ||
      !enteredGrade.grade?.percentage
    ) {
      return
    }
    const gradingPeriodId = null
    const gradingPeriodIdProp =
      gradingPeriodId === '0' || gradingPeriodId == null ? undefined : gradingPeriodId
    const castedEnteredGrade = {percentage: enteredGrade.grade.percentage}
    setApiCallStatus(ApiCallStatus.PENDING)
    const updatedScore = await updateFinalGradeOverride(
      enrollmentId,
      gradingPeriodIdProp,
      castedEnteredGrade
    )
    setApiCallStatus(ApiCallStatus.COMPLETED)
    if (updatedScore) {
      onSubmit({courseGrade: updatedScore})
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
        renderLabel={<ScreenReaderContent>{I18n.t('Final Grade Override')}</ScreenReaderContent>}
        value={inputValue}
        onChange={handleFinalGradeOverrideChange}
        onBlur={handleFinalGradeOverrideBlur}
        width="14rem"
        disabled={apiCallStatus === ApiCallStatus.PENDING}
      />
    </>
  )
}

export default FinalGradeOverrideTextBox
