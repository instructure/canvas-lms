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

import React, {useEffect, useState} from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import SubmissionTrayRadioInput from './SubmissionTrayRadioInput'
import {statusesTitleMap} from '../constants/statuses'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {CamelizedSubmission} from '@canvas/grading/grading.d'
import type {GradeStatus} from '@canvas/grading/accountGradingStatus'

const I18n = useI18nScope('gradebook')

type SubmissionPartialProp = Pick<
  CamelizedSubmission,
  'excused' | 'missing' | 'late' | 'latePolicyStatus' | 'customGradeStatusId' | 'secondsLate'
>

function checkedValue(submission: SubmissionPartialProp, anonymizeStudents: boolean) {
  // If students are anonymized we don't want to leak any information about the submission
  if (anonymizeStudents) {
    return 'none'
  } else if (submission.customGradeStatusId) {
    return submission.customGradeStatusId
  } else if (submission.excused) {
    return 'excused'
  } else if (submission.missing) {
    return 'missing'
  } else if (submission.late) {
    return 'late'
  } else if (submission.latePolicyStatus === 'extended') {
    return 'extended'
  }

  return 'none'
}

type ColorValues = 'late' | 'missing' | 'excused' | 'extended'

type StandardOptions = ColorValues | 'none'

export type SubmissionTrayRadioInputGroupProps = {
  assignment: {
    anonymizeStudents: boolean
  }
  colors: Record<ColorValues, string>
  customGradeStatuses?: GradeStatus[]
  customGradeStatusesEnabled: boolean
  disabled: boolean
  locale: string
  submission: SubmissionPartialProp
  submissionUpdating: boolean
  updateSubmission: (arg0: PendingUpdateData) => void
  latePolicy: {
    lateSubmissionInterval: string
  }
}

export type PendingUpdateData = {
  excuse?: boolean
  latePolicyStatus?: string
  secondsLateOverride?: number
  customGradeStatusId?: string
}

type RadioInputOption = {
  name: string
  checked: boolean
  color?: string
  isCustom: boolean
  key: string
}

export default function SubmissionTrayRadioInputGroup({
  submissionUpdating,
  assignment,
  colors,
  customGradeStatuses = [],
  customGradeStatusesEnabled,
  disabled,
  latePolicy,
  locale,
  submission,
  updateSubmission,
}: SubmissionTrayRadioInputGroupProps) {
  const [pendingUpdateData, setPendingUpdateData] = useState<PendingUpdateData | null>(null)

  useEffect(() => {
    if (!submissionUpdating && pendingUpdateData) {
      updateSubmission(pendingUpdateData)
      setPendingUpdateData(null)
    }
  }, [submissionUpdating, pendingUpdateData, setPendingUpdateData, updateSubmission])

  const handleRadioInputChanged = (
    event: React.ChangeEvent<HTMLInputElement>,
    isCustom: boolean
  ) => {
    const {
      target: {value},
    } = event
    const alreadyChecked = checkedValue(submission, assignment.anonymizeStudents) === value
    if (alreadyChecked && !submissionUpdating) {
      return
    }

    let data: PendingUpdateData = {}

    if (isCustom && customGradeStatusesEnabled) {
      data.customGradeStatusId = value
    } else {
      data = value === 'excused' ? {excuse: true} : {latePolicyStatus: value}
      if (value === 'late') {
        data.secondsLateOverride = submission.secondsLate
      }
    }

    if (submissionUpdating) {
      setPendingUpdateData(data)
    } else {
      updateSubmission(data)
    }
  }

  const radioInputOptions = (): RadioInputOption[] => {
    const standardOptions: StandardOptions[] = ['none', 'late', 'missing', 'excused']

    if (ENV.FEATURES && ENV.FEATURES.extended_submission_state) {
      standardOptions.push('extended')
    }

    const optionsArray: RadioInputOption[] = standardOptions.map(status => {
      const isNone = status === 'none'
      return {
        name: isNone ? I18n.t('None') : statusesTitleMap[status],
        checked: checkedValue(submission, assignment.anonymizeStudents) === status,
        color: isNone ? undefined : colors[status],
        isCustom: false,
        key: status,
      }
    })

    const customGradingStatusOptions: RadioInputOption[] = customGradeStatusesEnabled
      ? customGradeStatuses.map(status => ({
          name: status.name,
          checked: checkedValue(submission, assignment.anonymizeStudents) === status.id,
          color: status.color,
          key: status.id,
          isCustom: true,
        }))
      : []

    return optionsArray.concat(customGradingStatusOptions)
  }

  return (
    <FormFieldGroup
      description={I18n.t('Status')}
      disabled={disabled}
      layout="stacked"
      rowSpacing="none"
    >
      {radioInputOptions().map(status => (
        <SubmissionTrayRadioInput
          key={status.name}
          checked={status.checked}
          color={status.color}
          disabled={disabled}
          latePolicy={latePolicy}
          locale={locale}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handleRadioInputChanged(e, status.isCustom)
          }
          // @ts-expect-error
          updateSubmission={updateSubmission}
          // @ts-expect-error
          submission={submission}
          text={status.name}
          value={status.key}
        />
      ))}
    </FormFieldGroup>
  )
}
