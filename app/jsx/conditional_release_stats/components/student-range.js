import React from 'react'
import StudentRangeItem from './student-range-item'

  const { object, func } = React.PropTypes

export default class StudentRange extends React.Component {
    static propTypes = {
      range: object.isRequired,
      onStudentSelect: func.isRequired,
    }

    render () {
      const students = this.props.range.students
      return (
        <div className='crs-student-range'>
          {this.props.range.students.map((student, i) => {
            return (
              <StudentRangeItem
                key={student.user.id}
                student={student}
                studentIndex={i}
                selectStudent={this.props.onStudentSelect}
              />
            )}
          )}
        </div>
      )
    }
  }
