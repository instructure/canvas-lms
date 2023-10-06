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
import {useScope as useI18nScope} from '@canvas/i18n'
import {bool, string} from 'prop-types'
import React from 'react'

import {Pill} from '@instructure/ui-pill'

const I18n = useI18nScope('assignments_2')

export const isStatusPillPresent = submission => {
  return (
    submission &&
    (submission.customGradeStatus ||
      submission.excused ||
      submission.submissionStatus === 'missing' ||
      submission.submissionStatus === 'late' ||
      submission.submissionStatus === 'extended')
  )
}

const StatusPill = ({label, testId, color = 'primary'}) => {
  return window.ENV.FEATURES.instui_nav ? (
    <Pill data-testid={testId} color={color}>
      {label}
    </Pill>
  ) : (
    <Pill data-testid={testId} color={color}>
      {label}
    </Pill>
  )
}

export default function SubmissionStatusPill(props) {
  if (props.customGradeStatus) {
    return (
      <StatusPill
        label={props.customGradeStatus}
        testId={`custom-grade-pill-${props.customGradeStatus}`}
      />
    )
  } else if (props.excused) {
    return <StatusPill label={I18n.t('Excused')} testId="excused-pill" />
  } else if (props.submissionStatus === 'missing') {
    return <StatusPill label={I18n.t('Missing')} testId="missing-pill" color="danger" />
  } else if (props.submissionStatus === 'late') {
    return <StatusPill label={I18n.t('Late')} testId="late-pill" color="info" />
  } else if (props.submissionStatus === 'extended') {
    return <StatusPill label={I18n.t('Extended')} testId="extended-pill" color="info" />
  } else {
    return null
  }
}

SubmissionStatusPill.propTypes = {
  excused: bool,
  submissionStatus: string,
  customGradeStatus: string,
}
