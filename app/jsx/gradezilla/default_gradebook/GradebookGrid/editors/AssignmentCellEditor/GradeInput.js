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
import {bool, instanceOf, oneOf, number, shape, string} from 'prop-types'
import ScreenReaderContent from '@instructure/ui-core/lib/components/ScreenReaderContent'
import I18n from 'i18n!gradebook'
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'
import {hasGradeChanged, parseTextValue} from '../../../../../grading/helpers/GradeInputHelper'
import CellTextInput from './CellTextInput'

const CLASSNAME_FOR_ENTER_GRADES_AS = {
  gradingScheme: 'Grid__AssignmentRowCell__GradingSchemeInput',
  passFail: 'Grid__AssignmentRowCell__PassFailInput',
  percent: 'Grid__AssignmentRowCell__PercentInput',
  points: 'Grid__AssignmentRowCell__PointsInput'
}

function formatGrade(submission, assignment, gradingScheme, enterGradesAs, pendingGradeInfo) {
  if (pendingGradeInfo) {
    return GradeFormatHelper.formatPendingGradeInfo(pendingGradeInfo, {defaultValue: ''})
  }

  const formatOptions = {
    defaultValue: '',
    formatType: enterGradesAs,
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'entered'
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function getGradeInfo(value, props) {
  return parseTextValue(value, {
    enterGradesAs: props.enterGradesAs,
    gradingScheme: props.gradingScheme,
    pointsPossible: props.assignment.pointsPossible
  })
}

export default class GradeInput extends Component {
  static propTypes = {
    assignment: shape({
      pointsPossible: number
    }).isRequired,
    disabled: bool,
    enterGradesAs: oneOf(['gradingScheme', 'passFail', 'percent', 'points']).isRequired,
    gradingScheme: instanceOf(Array).isRequired,
    pendingGradeInfo: shape({
      excused: bool,
      grade: string,
      valid: bool
    }),
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
      id: string.isRequired
    }).isRequired
  }

  static defaultProps = {
    disabled: false,
    pendingGradeInfo: null
  }

  constructor(props) {
    super(props)

    this.bindTextInput = ref => {
      this.textInput = ref
    }

    this.handleTextChange = this.handleTextChange.bind(this)

    const {assignment, enterGradesAs, gradingScheme, pendingGradeInfo, submission} = props

    this.state = {
      grade: formatGrade(submission, assignment, gradingScheme, enterGradesAs, pendingGradeInfo)
    }
  }

  componentWillReceiveProps(nextProps) {
    if (!this.isFocused()) {
      const {assignment, enterGradesAs, gradingScheme, pendingGradeInfo, submission} = nextProps

      this.setState({
        grade: formatGrade(submission, assignment, gradingScheme, enterGradesAs, pendingGradeInfo)
      })
    }
  }

  get gradingData() {
    return getGradeInfo(this.state.grade, this.props)
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

    const gradeInfo = getGradeInfo(this.state.grade, this.props)
    return hasGradeChanged(this.props.submission, gradeInfo, {
      enterGradesAs: this.props.enterGradesAs,
      gradingScheme: this.props.gradingScheme,
      pointsPossible: this.props.assignment.pointsPossible
    })
  }

  handleTextChange(event) {
    this.setState({grade: event.target.value})
  }

  isFocused() {
    return this.textInput === document.activeElement
  }

  render() {
    const className = CLASSNAME_FOR_ENTER_GRADES_AS[this.props.enterGradesAs]

    const messages = []
    if (this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid) {
      messages.push({type: 'error', text: I18n.t('This grade is invalid')})
    }

    return (
      <div className={className}>
        <CellTextInput
          value={this.state.grade}
          disabled={this.props.disabled}
          inputRef={this.bindTextInput}
          label={<ScreenReaderContent>{I18n.t('Grade')}</ScreenReaderContent>}
          messages={messages}
          onChange={this.handleTextChange}
          size="small"
        />
      </div>
    )
  }
}
