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
import Text from '@instructure/ui-core/lib/components/Text'
import SubmissionCell from 'compiled/gradezilla/SubmissionCell';
import IconExpandLeftLine from 'instructure-icons/lib/Line/IconExpandLeftLine';
import I18n from 'i18n!gradebook';
import CellButton from '../GradebookGrid/editors/AssignmentCellEditor/CellButton'
import GradeInput from '../GradebookGrid/editors/AssignmentCellEditor/GradeInput'

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
    submission: shape({
      assignmentId: string.isRequired,
      enteredGrade: string,
      enteredScore: number,
      excused: bool.isRequired,
      id: string,
      userId: string.isRequired
    }).isRequired,
    submissionIsUpdating: bool.isRequired
  };

  constructor (props) {
    super(props);

    this.bindContainerRef = ref => {
      this.contentContainer = ref
    }
    this.bindGradeInput = ref => {
      this.gradeInput = ref
    }
    this.bindToggleTrayButtonRef = ref => {
      this.trayButton = ref
    }

    this.gradeSubmission = this.gradeSubmission.bind(this)
  }

  componentDidMount () {
    if (this.props.enterGradesAs === 'passFail') {
      // eslint-disable-next-line new-cap
      this.submissionCell = new SubmissionCell.pass_fail({
        ...this.props.editorOptions,
        container: this.contentContainer
      })
    } else if (!this.props.submissionIsUpdating && this.trayButton !== document.activeElement) {
      this.gradeInput.focus()
    }
  }

  componentDidUpdate(prevProps) {
    const submissionFinishedUpdating =
      prevProps.submissionIsUpdating && !this.props.submissionIsUpdating

    if (
      this.props.enterGradesAs !== 'passFail' &&
      submissionFinishedUpdating &&
      this.trayButton !== document.activeElement
    ) {
      this.gradeInput.focus()
    }
  }

  componentWillUnmount () {
    if (this.submissionCell) {
      this.submissionCell.destroy()
    }
  }

  handleKeyDown = (event) => {
    const inputHasFocus = this.contentContainer.contains(document.activeElement)
    const trayButtonHasFocus = this.trayButton === document.activeElement

    if (event.which === 9) { // Tab
      if (!event.shiftKey && inputHasFocus) {
        // browser will set focus on the tray button
        return false; // prevent Grid behavior
      } else if (event.shiftKey && trayButtonHasFocus) {
        // browser will set focus on the submission cell
        return false; // prevent Grid behavior
      }
    }

    // Enter
    if (event.which === 13 && trayButtonHasFocus) {
      // browser will activate the tray button
      return false; // prevent Grid behavior
    }

    return undefined;
  }

  handleToggleTrayButtonClick = () => {
    const options = this.props.editorOptions;
    this.props.onToggleSubmissionTrayOpen(options.item.id, options.column.assignmentId);
  }

  focus() {
    if (this.submissionCell) {
      this.submissionCell.focus()
    } else {
      this.gradeInput.focus()
    }
  }

  gradeSubmission(item, state) {
    if (this.props.enterGradesAs === 'passFail') {
      this.submissionCell.applyValue(item, state)
    } else {
      this.props.onGradeSubmission(this.props.submission, this.gradeInput.gradingData)
    }
  }

  isValueChanged () {
    if (this.props.enterGradesAs === 'passFail') {
      return this.submissionCell.isValueChanged()
    }
    return this.gradeInput.hasGradeChanged()
  }

  loadValue() {
    if (this.submissionCell) {
      this.submissionCell.loadValue()
    }
  }

  serializeValue() {
    return this.submissionCell ? this.submissionCell.serializeValue() : null
  }

  render () {
    let pointsPossible = null
    if (this.props.enterGradesAs === 'points' && this.props.assignment.pointsPossible) {
      pointsPossible = `/${I18n.n(this.props.assignment.pointsPossible)}`
    }

    const showEndText =
      this.props.enterGradesAs === 'percent' || this.props.enterGradesAs === 'points'

    return (
      <div className="Grid__AssignmentRowCell">
        <div className="Grid__AssignmentRowCell__StartContainer" />

        <div className="Grid__AssignmentRowCell__Content" ref={this.bindContainerRef}>
          {this.props.enterGradesAs !== 'passFail' && (
            <GradeInput
              assignment={this.props.assignment}
              enterGradesAs={this.props.enterGradesAs}
              disabled={this.props.submissionIsUpdating}
              gradingScheme={this.props.gradingScheme}
              ref={this.bindGradeInput}
              submission={this.props.submission}
            />
          )}
        </div>

        <div className="Grid__AssignmentRowCell__EndContainer">
          {showEndText && (
            <span className="Grid__AssignmentRowCell__EndText">
              {pointsPossible && <Text size="small">{pointsPossible}</Text>}
            </span>
          )}

          <div className="Grid__AssignmentRowCell__Options">
            <CellButton
              buttonRef={this.bindToggleTrayButtonRef}
              onClick={this.handleToggleTrayButtonClick}
            >
              <IconExpandLeftLine title={I18n.t('Open submission tray')} />
            </CellButton>
          </div>
        </div>
      </div>
    );
  }
}
