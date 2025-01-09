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
import {bool, func, instanceOf, number, oneOf, shape, string} from 'prop-types'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {IconCheckMarkSolid, IconExpandStartLine, IconEndSolid} from '@instructure/ui-icons'

import {useScope as createI18nScope} from '@canvas/i18n'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = createI18nScope('gradebook')

const componentOverrides = {
  IconButton: {
    iconPadding: '0 3px',
    smallHeight: '23px',
  },
}

function formatGrade(
  // @ts-expect-error
  submission,
  // @ts-expect-error
  assignment,
  // @ts-expect-error
  gradingScheme,
  // @ts-expect-error
  pointsBasedGradingScheme,
  // @ts-expect-error
  enterGradesAs,
  // @ts-expect-error
  scalingFactor,
) {
  const formatOptions = {
    defaultValue: '–',
    formatType: enterGradesAs,
    gradingScheme,
    pointsBasedGradingScheme,
    pointsPossible: assignment.pointsPossible,
    scalingFactor,
    version: 'final',
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

// @ts-expect-error
function renderTextGrade(grade) {
  return <Text size="small">{grade}</Text>
}

// @ts-expect-error
function renderCompleteIncompleteGrade(grade) {
  if (grade !== 'complete' && grade !== 'incomplete') {
    return renderTextGrade('–')
  }

  let content
  if (grade === 'complete') {
    content = (
      <Text color="success" size="medium">
        <IconCheckMarkSolid title={I18n.t('Complete')} />
      </Text>
    )
  } else {
    content = (
      <Text size="medium">
        <IconEndSolid title={I18n.t('Incomplete')} />
      </Text>
    )
  }
  return <span style={{display: 'flex', paddingBottom: '3px'}}>{content}</span>
}

export default class ReadOnlyCell extends Component {
  static propTypes = {
    assignment: shape({
      id: string.isRequired,
      pointsPossible: number,
    }).isRequired,
    enterGradesAs: oneOf(['gradingScheme', 'passFail', 'percent', 'points']).isRequired,
    gradeIsVisible: bool.isRequired,
    gradingScheme: instanceOf(Array).isRequired,
    pointsBasedGradingScheme: bool,
    onToggleSubmissionTrayOpen: func.isRequired,
    scalingFactor: number,
    student: shape({
      id: string.isRequired,
    }).isRequired,
    submission: shape({
      assignmentId: string.isRequired,
      excused: bool.isRequired,
      grade: string,
      id: string,
      rawGrade: string,
      score: number,
    }).isRequired,
  }

  // @ts-expect-error
  constructor(props) {
    super(props)

    // @ts-expect-error
    this.bindToggleTrayButtonRef = ref => {
      // @ts-expect-error
      this.trayButton = ref
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleToggleTrayButtonClick = this.handleToggleTrayButtonClick.bind(this)
  }

  componentDidMount() {
    // @ts-expect-error
    this.trayButton.focus()
  }

  /* Required for AssignmentCellEditor */
  // @ts-expect-error
  handleKeyDown(event) {
    // Enter
    // @ts-expect-error
    if (event.which === 13 && this.trayButton === document.activeElement) {
      // browser will activate the tray button
      return false // prevent Grid behavior
    }

    return undefined
  }

  handleToggleTrayButtonClick() {
    // @ts-expect-error
    const {assignment, student} = this.props
    // @ts-expect-error
    this.props.onToggleSubmissionTrayOpen(student.id, assignment.id)
  }

  focus() {
    // @ts-expect-error
    this.trayButton.focus()
  }

  /* Required for AssignmentCellEditor */
  gradeSubmission() {}

  /* Required for AssignmentCellEditor */
  isValueChanged() {
    return false
  }

  render() {
    const {
      // @ts-expect-error
      assignment,
      // @ts-expect-error
      enterGradesAs,
      // @ts-expect-error
      gradeIsVisible,
      // @ts-expect-error
      gradingScheme,
      // @ts-expect-error
      pointsBasedGradingScheme,
      // @ts-expect-error
      scalingFactor,
      // @ts-expect-error
      submission,
    } = this.props

    let content = ''
    if (gradeIsVisible) {
      if (enterGradesAs === 'passFail' && !submission.excused) {
        // @ts-expect-error
        content = renderCompleteIncompleteGrade(submission.rawGrade)
      } else {
        // @ts-expect-error
        content = renderTextGrade(
          formatGrade(
            submission,
            assignment,
            gradingScheme,
            pointsBasedGradingScheme,
            enterGradesAs,
            scalingFactor,
          ),
        )
      }
    }

    return (
      <InstUISettingsProvider theme={{componentOverrides}}>
        <div className="Grid__GradeCell Grid__ReadOnlyCell">
          <div className="Grid__GradeCell__StartContainer" />

          <div className="Grid__GradeCell__Content">{gradeIsVisible && content}</div>

          <div className="Grid__GradeCell__EndContainer">
            <div className="Grid__GradeCell__Options">
              <IconButton
                // @ts-expect-error
                elementRef={this.bindToggleTrayButtonRef}
                onClick={this.handleToggleTrayButtonClick}
                size="small"
                color="secondary"
                screenReaderLabel={I18n.t('Open submission tray')}
                renderIcon={IconExpandStartLine}
              />
            </div>
          </div>
        </div>
      </InstUISettingsProvider>
    )
  }
}
