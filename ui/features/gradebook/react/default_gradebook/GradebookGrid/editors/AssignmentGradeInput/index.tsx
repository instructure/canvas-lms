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
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as useI18nScope} from '@canvas/i18n'

import CompleteIncompleteGradeInput from './CompleteIncompleteGradeInput'
import GradingSchemeGradeInput from './GradingSchemeGradeInput'
import TextGradeInput from './TextGradeInput'

const I18n = useI18nScope('gradebook')

const CLASSNAME_FOR_ENTER_GRADES_AS = {
  gradingScheme: 'Grid__GradeCell__GradingSchemeInput',
  passFail: 'Grid__GradeCell__CompleteIncompleteInput',
  percent: 'Grid__GradeCell__PercentInput',
  points: 'Grid__GradeCell__PointsInput',
} as const

type Props = {
  assignment: {
    pointsPossible: number
  }
  disabled: boolean
  enterGradesAs: 'gradingScheme' | 'passFail' | 'percent' | 'points'
  gradingScheme: [name: string, value: number][]
  pendingGradeInfo: {
    excused: boolean
    grade: string
    valid: boolean
  }
  submission: {
    enteredGrade: string
    enteredScore: number
    excused: boolean
  }
}
export default class AssignmentGradeInput extends Component<Props> {
  static defaultProps = {
    disabled: false,
    gradingScheme: null,
    pendingGradeInfo: null,
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

    return (
      <div className={className}>
        {this.props.enterGradesAs === 'gradingScheme' && (
          <GradingSchemeGradeInput
            {...this.props}
            label={<ScreenReaderContent>{I18n.t('Grade')}</ScreenReaderContent>}
            messages={messages}
            ref={this.bindGradeInput}
          />
        )}
        {this.props.enterGradesAs === 'passFail' && (
          <CompleteIncompleteGradeInput
            {...this.props}
            label={<ScreenReaderContent>{I18n.t('Grade')}</ScreenReaderContent>}
            messages={messages}
            ref={this.bindGradeInput}
          />
        )}
        {!['gradingScheme', 'passFail'].includes(this.props.enterGradesAs) && (
          <TextGradeInput
            {...this.props}
            label={<ScreenReaderContent>{I18n.t('Grade')}</ScreenReaderContent>}
            messages={messages}
            ref={this.bindGradeInput}
          />
        )}
      </div>
    )
  }
}
