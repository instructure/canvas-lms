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

import React, {Component} from 'react'
import {TextInput} from '@instructure/ui-text-input'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'
import {hasGradeChanged, parseTextValue} from '@canvas/grading/GradeInputHelper'
import type {PendingGradeInfo} from '../../../gradebook.d'
import type {DeprecatedGradingScheme} from '@canvas/grading/grading.d'

function formatGrade(
  submission,
  assignment,
  gradingScheme,
  enterGradesAs,
  pendingGradeInfo: PendingGradeInfo
) {
  if (pendingGradeInfo) {
    return GradeFormatHelper.formatGradeInfo(pendingGradeInfo, {defaultValue: ''})
  }

  const formatOptions = {
    defaultValue: '',
    formatType: enterGradesAs,
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'entered',
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function getGradeInfo(value, props) {
  return parseTextValue(value, {
    enterGradesAs: props.enterGradesAs,
    gradingScheme: props.gradingScheme,
    pointsPossible: props.assignment.pointsPossible,
  })
}

type Props = {
  assignment: {
    pointsPossible: number
  }
  disabled: boolean
  enterGradesAs: 'gradingScheme' | 'passFail' | 'percent' | 'points'
  gradingScheme: DeprecatedGradingScheme[]
  label: React.ReactElement
  messages: Array<{
    text: string
    type: string
  }>
  pendingGradeInfo: PendingGradeInfo
  submission: {
    enteredGrade: string
    enteredScore: number
    excused: boolean
    id: string
  }
}

type State = {
  gradeInfo: {
    excused: boolean
    grade: string | null
    valid: boolean
  }
  grade: string
}

export default class TextGradeInput extends Component<Props, State> {
  textInput: HTMLInputElement | null = null

  static defaultProps = {
    disabled: false,
    pendingGradeInfo: null,
  }

  constructor(props: Props) {
    super(props)

    this.bindTextInput = ref => {
      this.textInput = ref
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleTextChange = this.handleTextChange.bind(this)

    const {assignment, enterGradesAs, gradingScheme, pendingGradeInfo, submission} = props
    const value = formatGrade(
      submission,
      assignment,
      gradingScheme,
      enterGradesAs,
      pendingGradeInfo
    )

    this.state = {
      gradeInfo: pendingGradeInfo || getGradeInfo(submission.excused ? 'EX' : value, this.props),
      grade: formatGrade(submission, assignment, gradingScheme, enterGradesAs, pendingGradeInfo),
    }
  }

  UNSAFE_componentWillReceiveProps(nextProps: Props) {
    if (!this.isFocused()) {
      const {assignment, enterGradesAs, gradingScheme, pendingGradeInfo, submission} = nextProps

      this.setState({
        grade: formatGrade(submission, assignment, gradingScheme, enterGradesAs, pendingGradeInfo),
      })
    }
  }

  get gradeInfo() {
    return this.state.gradeInfo
  }

  focus() {
    this.textInput.focus()
    this.textInput.setSelectionRange(0, this.textInput.value.length)
  }

  hasGradeChanged() {
    if (this.props.pendingGradeInfo) {
      if (this.props.pendingGradeInfo.valid) {
        // the pending grade is currently being submitted
        // changes are not allowed
        return false
      }

      // the pending grade is invalid
      // return true only when the input value differs from the invalid grade
      return this.state.grade.trim() !== this.props.pendingGradeInfo.grade
    }

    const {assignment, enterGradesAs, gradingScheme, submission} = this.props
    const formattedGrade = formatGrade(submission, assignment, gradingScheme, enterGradesAs)

    if (formattedGrade === this.state.grade.trim()) {
      return false
    }

    const gradeInfo = getGradeInfo(this.state.grade, this.props)
    return hasGradeChanged(this.props.submission, gradeInfo, {
      enterGradesAs: this.props.enterGradesAs,
      gradingScheme: this.props.gradingScheme,
      pointsPossible: this.props.assignment.pointsPossible,
    })
  }

  handleKeyDown(/* event */) {
    return undefined
  }

  handleTextChange(event) {
    this.setState({
      gradeInfo: getGradeInfo(event.target.value, this.props),
      grade: event.target.value,
    })
  }

  isFocused() {
    return this.textInput === document.activeElement
  }

  render() {
    return (
      <TextInput
        disabled={this.props.disabled}
        inputRef={this.bindTextInput}
        renderLabel={this.props.label}
        messages={this.props.messages}
        onChange={this.handleTextChange}
        size="small"
        textAlign="center"
        value={this.state.grade}
      />
    )
  }
}
