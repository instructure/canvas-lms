define([
  'react',
  './student-range-item',
], (React, StudentRangeItem) => {
  const { object, func } = React.PropTypes

  return class StudentRange extends React.Component {
    static get propTypes () {
      return {
        range: object.isRequired,
        onStudentSelect: func.isRequired,
      }
    }

    render () {
      const students = this.props.range.students

      return (
        <div className='crs-student-range'>
          {students.map((student, i) => (
            <StudentRangeItem
              key={i}
              student={student}
              studentIndex={i}
              onSelect={this.props.onStudentSelect}
            />
          ))}
        </div>
      )
    }
  }
})
