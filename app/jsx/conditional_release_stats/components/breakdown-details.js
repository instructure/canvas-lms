/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import React from 'react'
import PropTypes from 'prop-types'
import Button from '@instructure/ui-buttons/lib/components/Button'
import Tray from '@instructure/ui-overlays/lib/components/Tray'
import IconX from '@instructure/ui-icons/lib/Solid/IconX'
import I18n from 'i18n!cyoe_assignment_sidebar'
import StudentRangesView from './student-ranges-view'
import StudentDetailsView from './student-details-view'
import { assignmentShape, selectedPathShape } from '../shapes/index'

const { array, object, func, bool } = PropTypes

export default class BreakdownDetails extends React.Component {
    static propTypes = {
      ranges: array.isRequired,
      students: object.isRequired,
      assignment: assignmentShape.isRequired,
      selectedPath: selectedPathShape.isRequired,
      isStudentDetailsLoading: bool.isRequired,
      showDetails: bool.isRequired,

      // actions
      selectStudent: func.isRequired,
      closeSidebar: func.isRequired
    }

    constructor () {
      super()
      this.unselectStudent = this.unselectStudent.bind(this)
      this.selectPrevStudent = this.selectPrevStudent.bind(this)
      this.selectNextStudent = this.selectNextStudent.bind(this)
    }

    unselectStudent () {
      this.props.selectStudent(null)
    }

    selectPrevStudent () {
      let studentIndex = this.props.selectedPath.student
      const range = this.props.ranges[this.props.selectedPath.range]

      if (studentIndex > 0) {
        studentIndex -= 1
      } else {
        studentIndex = range.size - 1
      }

      this.props.selectStudent(studentIndex)
    }

    selectNextStudent () {
      let studentIndex = this.props.selectedPath.student
      const range = this.props.ranges[this.props.selectedPath.range]

      if (studentIndex < (range.size - 1)) {
        studentIndex += 1
      } else {
        studentIndex = 0
      }

      this.props.selectStudent(studentIndex)
    }

    render () {
      const { selectedPath, ranges, students } = this.props
      const selectedStudent = selectedPath.student !== null ? ranges[selectedPath.range].students[selectedPath.student].user : null
      const studentDetails = selectedPath.student !== null && selectedStudent ? students[selectedStudent.id] : null

      return (
        <Tray
          open={this.props.showDetails}
          placement="end"
          shouldContainFocus
          defaultFocusElement={() => this.closeButton}
        >
          <div className="crs-breakdown-details">
            <div className="crs-breakdown-details__content">
              <span className="crs-breakdown-details__closeButton">
                <Button
                  variant="icon"
                  ref={(e) => { this.closeButton = e }}
                  onClick={this.props.closeSidebar}
                >
                  <span className="crs-breakdown-details__closeButtonIcon">
                    <IconX title={I18n.t('Close details sidebar')} />
                  </span>
                </Button>
              </span>
              <StudentRangesView
                assignment={this.props.assignment}
                ranges={ranges}
                selectedPath={selectedPath}
                selectStudent={this.props.selectStudent}
                student={selectedStudent}
              />
              <StudentDetailsView
                isLoading={this.props.isStudentDetailsLoading}
                student={selectedStudent}
                triggerAssignment={studentDetails && studentDetails.triggerAssignment}
                followOnAssignments={studentDetails && studentDetails.followOnAssignments}
                selectPrevStudent={this.selectPrevStudent}
                selectNextStudent={this.selectNextStudent}
                unselectStudent={this.unselectStudent}
              />
            </div>
          </div>
        </Tray>
      );
    }
  }
