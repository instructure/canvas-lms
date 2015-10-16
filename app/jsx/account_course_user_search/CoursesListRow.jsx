define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./UserLink",
], function(React, I18n, _, UserLink) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  var CoursesListRow = React.createClass({
    propTypes: {
      id: string.isRequired,
      name: string.isRequired,
      workflow_state: string.isRequired,
      total_students: number.isRequired,
      teachers: arrayOf(shape(UserLink.propTypes)).isRequired
    },

    render() {
      var { id, name, workflow_state, sis_course_id, total_students, teachers } = this.props;
      var url = `/courses/${id}`;
      var isPublished = workflow_state !== "unpublished";

      return (
        <tr>
          <td style={{width: 16}}>
            {isPublished && (<i className="icon-publish courses-list__published-icon" />)}
          </td>
          <td>
            <a href={url}>{name}</a>
          </td>
          <td>
            {sis_course_id}
          </td>
          <td>
            {teachers &&
            <div style={{margin: "-6px 0 -9px 0"}}>
              {teachers.map((teacher) => <UserLink key={teacher.id} {...teacher} />)}
            </div>
            }
          </td>
          <td>
            {total_students}
          </td>
          <td>
            {/* TODO actions */}
          </td>
        </tr>
      );
    }
  });

  return CoursesListRow;
});
