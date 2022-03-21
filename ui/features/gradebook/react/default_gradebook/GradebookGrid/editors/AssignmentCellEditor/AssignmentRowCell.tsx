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
import {bool, func, instanceOf, number, oneOf, shape, string} from 'prop-types'
import {ApplyTheme} from '@instructure/ui-themeable'
import {Button} from '@instructure/ui-buttons'
import {IconExpandStartLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {useScope as useI18nScope} from '@canvas/i18n'

import AssignmentGradeInput from '../AssignmentGradeInput/index'
import InvalidGradeIndicator from '../InvalidGradeIndicator'
import SimilarityIndicator from '../SimilarityIndicator'

const I18n = useI18nScope('gradebook')

const themeOverrides = {
  [Button.theme]: {
    iconPadding: '0 3px',
    smallHeight: '23px'
  },
  [TextInput.theme]: {
    smallHeight: '27px'
  }
}

export default class AssignmentRowCell extends Component {
  static propTypes = {
    assignment: shape({
      id: string.isRequired,
      pointsPossible: number
    }).isRequired,
    editorOptions: shape({
      column: shape({
        assignmentId: string.isRequired
      }).isRequired,
      grid: shape({}).isRequired,
      item: shape({
        id: string.isRequired
      }).isRequired
    }).isRequired,
    enterGradesAs: oneOf(['gradingScheme', 'passFail', 'percent', 'points']).isRequired,
    gradingScheme: instanceOf(Array).isRequired,
    onGradeSubmission: func.isRequired,
    onToggleSubmissionTrayOpen: func.isRequired,
    pendingGradeInfo: shape({
      enteredAs: string,
      excused: bool.isRequired,
      grade: string,
      score: number,
      valid: bool.isRequired
    }),
    submission: shape({
      assignmentId: string.isRequired,
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
      id: string,
      similarityInfo: shape({
        similarityScore: number,
        status: string.isRequired
      }),
      userId: string.isRequired
    }).isRequired,
    submissionIsUpdating: bool.isRequired
  }

  static defaultProps = {
    pendingGradeInfo: null
  }

  constructor(props) {
    super(props)

    this.bindContainerRef = ref => {
      this.contentContainer = ref
    }
    this.bindStartContainerIndicatorRef = ref => {
      this.startContainerIndicator = ref
    }
    this.bindGradeInput = ref => {
      this.gradeInput = ref
    }
    this.bindToggleTrayButtonRef = ref => {
      this.trayButton = ref
    }

    this.gradeSubmission = this.gradeSubmission.bind(this)
  }

  componentDidMount() {
    if (!this.props.submissionIsUpdating && this.trayButton !== document.activeElement) {
      this.gradeInput.focus()
    }
  }

  componentDidUpdate(prevProps) {
    const submissionFinishedUpdating =
      prevProps.submissionIsUpdating && !this.props.submissionIsUpdating

    if (submissionFinishedUpdating && this.trayButton !== document.activeElement) {
      // the cell was reactivated while the grade was updating
      // set the focus on the input by default
      this.gradeInput.focus()
    }
  }

  handleKeyDown = event => {
    const indicatorHasFocus = this.startContainerIndicator === document.activeElement
    const inputHasFocus = this.contentContainer.contains(document.activeElement)
    const trayButtonHasFocus = this.trayButton === document.activeElement

    if (this.gradeInput) {
      const inputHandled = this.gradeInput.handleKeyDown(event)
      if (inputHandled != null) {
        return inputHandled
      }
    }

    const hasPreviousElement = trayButtonHasFocus || (inputHasFocus && this.startContainerIndicator)
    const hasNextElement = inputHasFocus || indicatorHasFocus

    // Tab
    if (event.which === 9) {
      if (!event.shiftKey && hasNextElement) {
        return false // prevent Grid behavior
      } else if (event.shiftKey && hasPreviousElement) {
        return false // prevent Grid behavior
      }
    }

    // Enter
    if (event.which === 13 && trayButtonHasFocus) {
      // browser will activate the tray button
      return false // prevent Grid behavior
    }

    return undefined
  }

  handleToggleTrayButtonClick = () => {
    const options = this.props.editorOptions
    this.props.onToggleSubmissionTrayOpen(options.item.id, options.column.assignmentId)
  }

  focus() {
    this.gradeInput.focus()
  }

  gradeSubmission() {
    this.props.onGradeSubmission(this.props.submission, this.gradeInput.gradeInfo)
  }

  isValueChanged() {
    return this.gradeInput.hasGradeChanged()
  }

  render() {
    let pointsPossible = null
    if (this.props.enterGradesAs === 'points' && this.props.assignment.pointsPossible) {
      pointsPossible = `/${I18n.n(this.props.assignment.pointsPossible)}`
    }

    const gradeIsInvalid = this.props.pendingGradeInfo && !this.props.pendingGradeInfo.valid

    const {similarityInfo} = this.props.submission
    const showSimilarityIcon = !gradeIsInvalid && similarityInfo != null

    return (
      <ApplyTheme theme={themeOverrides}>
        <div className={`Grid__GradeCell ${this.props.enterGradesAs}`}>
          <div className="Grid__GradeCell__StartContainer">
            {gradeIsInvalid && (
              <InvalidGradeIndicator elementRef={this.bindStartContainerIndicatorRef} />
            )}
            {showSimilarityIcon && (
              <SimilarityIndicator
                elementRef={this.bindStartContainerIndicatorRef}
                similarityInfo={similarityInfo}
              />
            )}
          </div>

          <div className="Grid__GradeCell__Content" ref={this.bindContainerRef}>
            <AssignmentGradeInput
              assignment={this.props.assignment}
              enterGradesAs={this.props.enterGradesAs}
              disabled={this.props.submissionIsUpdating}
              gradingScheme={this.props.gradingScheme}
              pendingGradeInfo={this.props.pendingGradeInfo}
              ref={this.bindGradeInput}
              submission={this.props.submission}
            />
          </div>

          <div className="Grid__GradeCell__EndContainer">
            {this.props.enterGradesAs === 'points' && (
              <span className="Grid__GradeCell__EndText">
                {pointsPossible && <Text size="small">{pointsPossible}</Text>}
              </span>
            )}

            <div className="Grid__GradeCell__Options">
              <Button
                elementRef={this.bindToggleTrayButtonRef}
                onClick={this.handleToggleTrayButtonClick}
                size="small"
                variant="icon"
              >
                <IconExpandStartLine title={I18n.t('Open submission tray')} />
              </Button>
            </div>
          </div>
        </div>
      </ApplyTheme>
    )
  }
}
