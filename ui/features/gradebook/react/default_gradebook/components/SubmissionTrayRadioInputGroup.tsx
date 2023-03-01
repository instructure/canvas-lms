// @ts-nocheck
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

import React from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import SubmissionTrayRadioInput from './SubmissionTrayRadioInput'
import {statusesTitleMap} from '../constants/statuses'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('gradebook')

function checkedValue(submission, assignment) {
  // If students are anonymized we don't want to leak any information about the submission
  if (assignment.anonymizeStudents) {
    return 'none'
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

type Props = {
  assignment: {
    anonymizeStudents: boolean
  }
  colors: {
    late: string
    missing: string
    excused: string
    extended: string
  }
  disabled: boolean
  locale: string
  submission: {
    excused: boolean
    late: boolean
    missing: boolean
    secondsLate: number
    latePolicyStatus: string
  }
  submissionUpdating: boolean
  updateSubmission: (arg0: PendingUpdateData) => void
  latePolicy: {
    lateSubmissionInterval: string
  }
  excuse?: boolean
}

type PendingUpdateData = {
  excuse?: boolean
  latePolicyStatus?: string
  secondsLateOverride?: number
}

type State = {
  pendingUpdateData: null | PendingUpdateData
}

export default class SubmissionTrayRadioInputGroup extends React.Component<Props, State> {
  state = {pendingUpdateData: null}

  UNSAFE_componentWillReceiveProps(nextProps: Props) {
    if (
      this.props.submissionUpdating &&
      !nextProps.submissionUpdating &&
      this.state.pendingUpdateData
    ) {
      this.props.updateSubmission(this.state.pendingUpdateData)
      this.setState({pendingUpdateData: null})
    }
  }

  handleRadioInputChanged = ({target: {value}}) => {
    const alreadyChecked = checkedValue(this.props.submission, this.props.assignment) === value
    if (alreadyChecked && !this.props.submissionUpdating) {
      return
    }

    const data: PendingUpdateData = value === 'excused' ? {excuse: true} : {latePolicyStatus: value}
    if (value === 'late') {
      data.secondsLateOverride = this.props.submission.secondsLate
    }

    if (this.props.submissionUpdating) {
      this.setState({pendingUpdateData: data})
    } else {
      this.props.updateSubmission(data)
    }
  }

  render() {
    const optionValues = ['none', 'late', 'missing', 'excused']
    if (ENV.FEATURES && ENV.FEATURES.extended_submission_state) optionValues.push('extended')
    const radioOptions = optionValues.map(status => (
      <SubmissionTrayRadioInput
        key={status}
        checked={checkedValue(this.props.submission, this.props.assignment) === status}
        color={this.props.colors[status]}
        disabled={this.props.disabled}
        latePolicy={this.props.latePolicy}
        locale={this.props.locale}
        onChange={this.handleRadioInputChanged}
        updateSubmission={this.props.updateSubmission}
        submission={this.props.submission}
        text={statusesTitleMap[status] || I18n.t('None')}
        value={status}
      />
    ))

    return (
      <FormFieldGroup
        description={I18n.t('Status')}
        disabled={this.props.disabled}
        layout="stacked"
        rowSpacing="none"
      >
        {radioOptions}
      </FormFieldGroup>
    )
  }
}
