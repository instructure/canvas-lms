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

import React, {Component} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import {Text} from '@instructure/ui-text'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {PendingGradeInfo} from '../gradebook.d'
import type {
  CamelizedAssignment,
  GradeEntryMode,
  GradeResult,
  SubmissionData,
} from '@canvas/grading/grading.d'
import type {GradingStandard} from '@instructure/grading-utils'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {parseTextValue} from '@canvas/grading/GradeInputHelper'
import {isUnusuallyHigh} from '@canvas/grading/OutlierScoreHelper'
import CompleteIncompleteGradeInput from './GradeInput/CompleteIncompleteGradeInput'
import type {TextInputProps} from '@instructure/ui-text-input'

const I18n = useI18nScope('gradebook')

type Message = {
  text: string
  type: 'error' | 'hint'
}

function normalizeSubmissionGrade(props: Props) {
  const {submission, assignment, enterGradesAs: formatType, gradingScheme} = props
  const gradeToNormalize = submission.enteredGrade

  if (props.pendingGradeInfo && props.pendingGradeInfo.excused) {
    return GradeFormatHelper.excused()
  } else if (props.pendingGradeInfo) {
    return GradeFormatHelper.formatGradeInfo(props.pendingGradeInfo, {defaultValue: ''})
  }

  if (!gradeToNormalize) {
    return ''
  }

  const formatOptions = {
    defaultValue: '',
    formatType,
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'entered',
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function hasGradeChanged(props: Props, state: {grade: string}) {
  if (props.pendingGradeInfo) {
    if (props.pendingGradeInfo.valid) {
      return false
    }

    return state.grade !== props.pendingGradeInfo.grade
  }

  const normalizedEnteredGrade = normalizeSubmissionGrade(props)
  return normalizedEnteredGrade !== state.grade && props.submission.enteredGrade !== state.grade
}

function assignmentLabel(assignment: CamelizedAssignment, formatType: GradeEntryMode) {
  switch (formatType) {
    case 'points': {
      const points = I18n.n(assignment.pointsPossible, {
        strip_insignificant_zeros: true,
        precision: 2,
      })
      return I18n.t('Grade out of %{points}', {points})
    }
    case 'percent': {
      const percentage = I18n.n(100, {
        percentage: true,
        precision: 2,
        strip_insignificant_zeros: true,
      })
      return I18n.t('Grade out of %{percentage}', {percentage})
    }
    case 'gradingScheme': {
      return I18n.t('Letter Grade')
    }
    default: {
      return I18n.t('Grade')
    }
  }
}

function stateFromProps(props: Props) {
  let normalizedGrade

  if (props.enterGradesAs === 'passFail') {
    normalizedGrade = props.assignment.anonymizeStudents ? null : props.submission.enteredGrade
  } else {
    const propsCopy = {...props}

    if (props.assignment.anonymizeStudents) {
      const submission = {...props.submission, enteredScore: null}
      propsCopy.submission = submission
    }

    normalizedGrade = normalizeSubmissionGrade(propsCopy)
  }

  return {
    formattedGrade: normalizedGrade,
    grade: normalizedGrade,
  }
}

type Props = {
  assignment: CamelizedAssignment
  disabled: boolean
  enterGradesAs: GradeEntryMode
  gradingScheme: GradingStandard[] | null
  onSubmissionUpdate: (submission: SubmissionData, gradeInfo: GradeResult) => void
  pendingGradeInfo: PendingGradeInfo
  submission: SubmissionData
  submissionUpdating: boolean
}

type State = {
  formattedGrade: string
  grade: string
}

export default class GradeInput extends Component<Props, State> {
  static defaultProps = {
    disabled: false,
    gradingScheme: null,
    onSubmissionUpdate() {},
    pendingGradeInfo: null,
    submissionUpdating: false,
  }

  constructor(props: Props) {
    super(props)

    this.handleSelectChange = this.handleSelectChange.bind(this)
    this.handleTextChange = this.handleTextChange.bind(this)
    this.handleTextBlur = this.handleTextBlur.bind(this)
    this.handleGradeChange = this.handleGradeChange.bind(this)

    this.state = stateFromProps(props)
  }

  UNSAFE_componentWillReceiveProps(nextProps: Props) {
    const submissionChanged = this.props.submission.id !== nextProps.submission.id
    const submissionUpdated = this.props.submissionUpdating && !nextProps.submissionUpdating

    if (submissionChanged || submissionUpdated) {
      this.setState(stateFromProps(nextProps))
    }
  }

  handleTextBlur() {
    this.setState(
      state => {
        const enteredGrade = state.grade.trim()

        return {
          formattedGrade: GradeFormatHelper.isExcused(enteredGrade)
            ? GradeFormatHelper.excused()
            : enteredGrade,
          grade: enteredGrade,
        }
      },

      () => {
        if (hasGradeChanged(this.props, this.state)) {
          this.handleGradeChange()
        }
      }
    )
  }

  handleTextChange(event: any) {
    this.setState({
      formattedGrade: event.target.value,
      grade: event.target.value,
    })
  }

  handleSelectChange(grade: string) {
    this.setState({grade}, this.handleGradeChange)
  }

  handleGradeChange() {
    const gradeInfo = parseTextValue(this.state.grade, {
      enterGradesAs: this.props.enterGradesAs,
      gradingScheme: this.props.gradingScheme,
      pointsPossible: this.props.assignment.pointsPossible,
    })

    this.props.onSubmissionUpdate(this.props.submission, gradeInfo)
  }

  render() {
    if (this.props.assignment.gradingType === 'not_graded') {
      return (
        <Text size="small" weight="bold">
          {I18n.t('This assignment is not graded.')}
        </Text>
      )
    }

    const isDisabled = this.props.disabled
    const isBusy = this.props.submissionUpdating

    let currentGradeInfo: PendingGradeInfo
    if (this.props.pendingGradeInfo) {
      currentGradeInfo = this.props.pendingGradeInfo
    } else if (this.props.submission.excused) {
      currentGradeInfo = {
        enteredAs: 'excused',
        excused: true,
        grade: null,
        score: null,
        valid: true,
      }
    } else {
      currentGradeInfo = parseTextValue(this.state.grade, {
        enterGradesAs: this.props.enterGradesAs,
        gradingScheme: this.props.gradingScheme,
        pointsPossible: this.props.assignment.pointsPossible,
      })
    }

    if (this.props.enterGradesAs === 'passFail') {
      return (
        <CompleteIncompleteGradeInput
          anonymizeStudents={this.props.assignment.anonymizeStudents}
          gradeInfo={currentGradeInfo}
          isBusy={isBusy}
          isDisabled={isDisabled}
          onChange={this.handleSelectChange}
        />
      )
    }

    let interaction: TextInputProps['interaction'] = 'enabled'
    if (!isDisabled && isBusy) {
      interaction = 'readonly'
    } else if (isDisabled || currentGradeInfo.excused) {
      interaction = 'disabled'
    }

    const messages: Message[] = []
    const score = this.props.submission.enteredScore
    if (this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid) {
      messages.push({type: 'error', text: I18n.t('This is not a valid grade')})
    } else if (typeof score === 'number' && score < 0) {
      messages.push({type: 'hint', text: I18n.t('This grade has negative points')})
    } else if (isUnusuallyHigh(score, this.props.assignment.pointsPossible)) {
      messages.push({type: 'hint', text: I18n.t('This grade is unusually high')})
    }

    return (
      <TextInput
        display="inline-block"
        id="grade-detail-tray--grade-input"
        interaction={interaction}
        messages={messages}
        onInput={this.handleTextChange}
        onChange={this.handleTextChange}
        onBlur={this.handleTextBlur}
        placeholder="–"
        renderLabel={() => assignmentLabel(this.props.assignment, this.props.enterGradesAs)}
        value={this.state.formattedGrade}
      />
    )
  }
}
