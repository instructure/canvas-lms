define([
  'react',
  'bower/reflux/dist/reflux',
  'jsx/gradebook/grid/stores/customColumnsStore',
  'jsx/gradebook/grid/components/column_types/teacherNote'
], function(React, Reflux, CustomColumnsStore, TeacherNote) {
  let CustomColumn = React.createClass({
    propTypes: {
      columnData: React.PropTypes.object.isRequired,
      rowData: React.PropTypes.object.isRequired,
      cellData: React.PropTypes.object
    },

    content(columnDatum) {
      if (columnDatum === null || columnDatum === undefined) {
        return '';
      }

      return columnDatum.content;
    },

    render() {
      let columnDatum, columnId, content, studentName, userId;

      columnId = this.props.columnData.customColumnData.id;
      userId = this.props.rowData.student.user_id;
      columnDatum = this.props.cellData;
      content = this.content(columnDatum);
      studentName= this.props.rowData.student.user.name;

      return (
        <TeacherNote
          key={'custom_columns-' + userId + '-' + columnId}
          note={content} userId={userId} studentName={studentName}
          columnId={columnId} />
      );
    }
  });

  return CustomColumn;
});
