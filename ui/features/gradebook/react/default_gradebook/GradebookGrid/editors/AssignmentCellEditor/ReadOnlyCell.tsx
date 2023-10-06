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
import {bool, func, instanceOf, number, oneOf, shape, string} from 'prop-types'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import {IconCheckMarkSolid, IconExpandStartLine, IconEndSolid} from '@instructure/ui-icons'

import {useScope as useI18nScope} from '@canvas/i18n'
import GradeFormatHelper from '@canvas/grading/GradeFormatHelper'

const I18n = useI18nScope('gradebook')

const componentOverrides = {
  IconButton: {
    iconPadding: '0 3px',
    smallHeight: '23px',
  },
}

function formatGrade(submission, assignment, gradingScheme, enterGradesAs) {
  const formatOptions = {
    defaultValue: '–',
    formatType: enterGradesAs,
    gradingScheme,
    pointsPossible: assignment.pointsPossible,
    version: 'final',
  }

  return GradeFormatHelper.formatSubmissionGrade(submission, formatOptions)
}

function renderTextGrade(grade) {
  return <Text size="small">{grade}</Text>
}

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
    onToggleSubmissionTrayOpen: func.isRequired,
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

  constructor(props) {
    super(props)

    this.bindToggleTrayButtonRef = ref => {
      this.trayButton = ref
    }

    this.handleKeyDown = this.handleKeyDown.bind(this)
    this.handleToggleTrayButtonClick = this.handleToggleTrayButtonClick.bind(this)
  }

  componentDidMount() {
    this.trayButton.focus()
  }

  /* Required for AssignmentCellEditor */
  handleKeyDown(event) {
    // Enter
    if (event.which === 13 && this.trayButton === document.activeElement) {
      // browser will activate the tray button
      return false // prevent Grid behavior
    }

    return undefined
  }

  handleToggleTrayButtonClick() {
    const {assignment, student} = this.props
    this.props.onToggleSubmissionTrayOpen(student.id, assignment.id)
  }

  focus() {
    this.trayButton.focus()
  }

  /* Required for AssignmentCellEditor */
  gradeSubmission() {}

  /* Required for AssignmentCellEditor */
  isValueChanged() {
    return false
  }

  render() {
    const {assignment, enterGradesAs, gradeIsVisible, gradingScheme, submission} = this.props

    let content = ''
    if (gradeIsVisible) {
      if (enterGradesAs === 'passFail' && !submission.excused) {
        content = renderCompleteIncompleteGrade(submission.rawGrade)
      } else {
        content = renderTextGrade(formatGrade(submission, assignment, gradingScheme, enterGradesAs))
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
