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
import GradeFormatHelper from 'jsx/gradebook/shared/helpers/GradeFormatHelper'
import {parseTextValue} from '../../../../../grading/helpers/GradeInputHelper'
import CellTextInput from './CellTextInput'

const CLASSNAME_FOR_ENTER_GRADES_AS = {
  gradingScheme: 'Grid__AssignmentRowCell__GradingSchemeInput',
  passFail: 'Grid__AssignmentRowCell__PassFailInput',
  percent: 'Grid__AssignmentRowCell__PercentInput',
  points: 'Grid__AssignmentRowCell__PointsInput'
}

function formatGrade(submission, assignment, gradingScheme, enterGradesAs) {
  const formatOptions = {
    defaultValue: '',
    formatType: enterGradesAs,
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'entered'
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function getGradingData(value, props) {
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
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
      id: string.isRequired
    }).isRequired
  }

  static defaultProps = {
    disabled: false
  }

  constructor(props) {
    super(props)

    this.bindTextInput = ref => {
      this.textInput = ref
    }

    this.handleTextChange = this.handleTextChange.bind(this)

    const {assignment, enterGradesAs, gradingScheme, submission} = props

    this.state = {
      grade: formatGrade(submission, assignment, gradingScheme, enterGradesAs)
    }
  }

  componentWillReceiveProps(nextProps) {
    if (!this.isFocused()) {
      const {assignment, enterGradesAs, gradingScheme, submission} = nextProps

      this.setState({
        grade: formatGrade(submission, assignment, gradingScheme, enterGradesAs)
      })
    }
  }

  get gradingData() {
    return getGradingData(this.state.grade, this.props)
  }

  focus() {
    this.textInput.focus()
    this.textInput.setSelectionRange(0, this.textInput.value.length)
  }

  hasGradeChanged() {
    const {assignment, enterGradesAs, gradingScheme, submission} = this.props
    const formattedGrade = formatGrade(submission, assignment, gradingScheme, enterGradesAs)

    if (formattedGrade === this.state.grade.trim()) {
      return false
    }

    const inputData = getGradingData(this.state.grade, this.props)
    if (inputData.excused !== this.props.submission.excused) {
      return true
    }

    if (inputData.enteredAs === 'gradingScheme') {
      /*
       * When the value given is a grading scheme key, it must be compared to
       * the grade on the submission instead of the score. This avoids updating
       * the grade when the stored score and interpreted score differ and the
       * input value was not changed.
       *
       * To avoid updating the grade in cases where the stored grade is of a
       * different type but otherwise equivalent, get the grading data for the
       * stored grade and compare it to the grading data from the input.
       */
      const submissionData = getGradingData(this.props.submission.enteredGrade, this.props)
      return submissionData.grade !== inputData.grade
    }

    return this.props.submission.enteredScore !== inputData.score
  }

  handleTextChange(event) {
    this.setState({grade: event.target.value})
  }

  isFocused() {
    return this.textInput === document.activeElement
  }

  render() {
    const className = CLASSNAME_FOR_ENTER_GRADES_AS[this.props.enterGradesAs]

    return (
      <div className={className}>
        <CellTextInput
          value={this.state.grade}
          disabled={this.props.disabled}
          inputRef={this.bindTextInput}
          label={<ScreenReaderContent>Grade</ScreenReaderContent>}
          onChange={this.handleTextChange}
          size="small"
        />
      </div>
    )
  }
}
