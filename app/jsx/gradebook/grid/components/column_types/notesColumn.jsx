define([
  'react',
  'jsx/gradebook/grid/components/column_types/teacherNote'
], function(React, TeacherNote) {

  var NotesColumn = React.createClass({
    propTypes: {
      rowData: React.PropTypes.object.isRequired
    },

    render() {
      var student     = this.props.rowData.student,
          studentName = this.props.rowData.studentName,
          teacherNote = this.props.rowData.teacherNote;

      return (
        <TeacherNote
          key={'notes' + student.user_id} note={teacherNote}
          userId={student.user_id} studentName={studentName}/>
      );
    }
  });

  return NotesColumn;
});
