import React from 'react'
import Button from 'instructure-ui/lib/components/Button'
import Tray from 'instructure-ui/lib/components/Tray'
import IconX from 'instructure-icons/react/Solid/IconXSolid'
import I18n from 'i18n!cyoe_assignment_sidebar'
import StudentRangeView from './student-ranges-view'
import StudentDetailsView from './student-details-view'
import { assignmentShape, selectedPathShape } from '../shapes/index'

const { array, object, func, bool } = React.PropTypes

export default class BreakdownDetails extends React.Component {
    static propTypes = {
      ranges: array.isRequired,
      students: object.isRequired,
      assignment: assignmentShape.isRequired,
      selectedPath: selectedPathShape.isRequired,
      isStudentDetailsLoading: bool.isRequired,
      showDetails: bool.isRequired,

      // actions
      selectRange: func.isRequired,
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
          isOpen={this.props.showDetails}
          placement="right"
          isDismissable={false}
          trapFocus
          getDefaultFocusElement={() => this.closeButton}
          onReady={() => document.getElementById('application').setAttribute('aria-hidden', true)}
          onClose={() => document.getElementById('application').setAttribute('aria-hidden', false)}
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
              <StudentRangeView
                assignment={this.props.assignment}
                ranges={ranges}
                selectedPath={selectedPath}
                selectRange={this.props.selectRange}
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
      )
    }
  }
