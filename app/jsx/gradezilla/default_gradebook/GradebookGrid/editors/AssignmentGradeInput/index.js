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
import ScreenReaderContent from '@instructure/ui-a11y/lib/components/ScreenReaderContent'
import I18n from 'i18n!gradebook'

import CompleteIncompleteGradeInput from './CompleteIncompleteGradeInput'
import GradingSchemeGradeInput from './GradingSchemeGradeInput'
import TextGradeInput from './TextGradeInput'

const CLASSNAME_FOR_ENTER_GRADES_AS = {
  gradingScheme: 'Grid__GradeCell__GradingSchemeInput',
  passFail: 'Grid__GradeCell__CompleteIncompleteInput',
  percent: 'Grid__GradeCell__PercentInput',
  points: 'Grid__GradeCell__PointsInput'
}

function inputComponentFor(enterGradesAs) {
  switch (enterGradesAs) {
    case 'gradingScheme': {
      return GradingSchemeGradeInput
    }
    case 'passFail': {
      return CompleteIncompleteGradeInput
    }
    default: {
      return TextGradeInput
    }
  }
}

export default class AssignmentGradeInput extends Component {
  static propTypes = {
    assignment: shape({
      pointsPossible: number
    }).isRequired,
    disabled: bool,
    enterGradesAs: oneOf(['gradingScheme', 'passFail', 'percent', 'points']).isRequired,
    gradingScheme: instanceOf(Array),
    pendingGradeInfo: shape({
      excused: bool.isRequired,
      grade: string,
      valid: bool.isRequired
    }),
    submission: shape({
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired
    }).isRequired
  }

  static defaultProps = {
    disabled: false,
    gradingScheme: null,
    pendingGradeInfo: null
  }

  constructor(props) {
    super(props)

    this.bindGradeInput = ref => {
      this.gradeInput = ref
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
  }

  get gradeInfo() {
    return this.gradeInput.gradeInfo
  }

  focus() {
    this.gradeInput.focus()
  }

  handleKeyDown(event) {
    return this.gradeInput.handleKeyDown(event)
  }

  hasGradeChanged() {
    return this.gradeInput.hasGradeChanged()
  }

  render() {
    const className = CLASSNAME_FOR_ENTER_GRADES_AS[this.props.enterGradesAs]

    const messages = []
    if (this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid) {
      messages.push({type: 'error', text: I18n.t('This grade is invalid')})
    }

    const InputComponent = inputComponentFor(this.props.enterGradesAs)

    return (
      <div className={className}>
        <InputComponent
          {...this.props}
          label={<ScreenReaderContent>{I18n.t('Grade')}</ScreenReaderContent>}
          messages={messages}
          ref={this.bindGradeInput}
        />
      </div>
    )
  }
}
