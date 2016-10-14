define([
  'react',
  './student-range-item',
], (React, StudentRangeItem) => {
  const { object, func } = React.PropTypes

  return class StudentRange extends React.Component {
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
})
