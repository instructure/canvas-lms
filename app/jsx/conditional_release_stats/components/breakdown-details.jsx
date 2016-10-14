define([
  'react',
  './student-ranges-view',
  './student-details-view',
  '../shapes/index',
], (React, StudentRangeView, StudentDetailsView, { assignmentShape, selectedPathShape }) => {
  const { array, object, func, bool } = React.PropTypes

  return class BreakdownDetails extends React.Component {
    static propTypes = {
      ranges: array.isRequired,
      students: object.isRequired,
      assignment: assignmentShape.isRequired,
      selectedPath: selectedPathShape.isRequired,
      isStudentDetailsLoading: bool.isRequired,

      // actions
      selectRange: func.isRequired,
      selectStudent: func.isRequired,
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
        <div className='crs-breakdown-details'>
          <div className='crs-breakdown-details__content'>
            <StudentRangeView
              assignment={this.props.assignment}
              ranges={this.props.ranges}
              selectedPath={this.props.selectedPath}
              selectRange={this.props.selectRange}
              selectStudent={this.props.selectStudent}
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
      )
    }
  }
})
