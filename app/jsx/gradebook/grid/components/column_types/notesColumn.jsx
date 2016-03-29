define([
  'react',
  'jsx/gradebook/grid/components/column_types/teacherNote',
  'jsx/gradebook/grid/constants'
], function(React, TeacherNote, GradebookConstants) {

  let NotesColumn = React.createClass({
    propTypes: {
      rowData: React.PropTypes.object.isRequired
    },

    render() {
      let student = this.props.rowData.student,
        studentName = this.props.rowData.studentName,
        teacherNote = this.props.rowData.teacherNote,
        columnId = GradebookConstants.teacher_notes.id;

      return (
        <TeacherNote
          key={'notes' + student.user_id} note={teacherNote}
          userId={student.user_id} studentName={studentName} 
          columnId={columnId} />
      );
    }
  });

  return NotesColumn;
});
