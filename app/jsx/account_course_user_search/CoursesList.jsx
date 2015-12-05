define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./CoursesListRow",
], function(React, I18n, _, CoursesListRow) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  var CoursesList = React.createClass({
    propTypes: {
      courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired
    },

    render() {
      var { courses } = this.props;

      return (
        <div className="pad-box no-sides">
          <table className="ic-Table courses-list">
            <thead>
              <tr>
                <th />
                <th>
                  {I18n.t("Course ID")}
                </th>
                <th>
                  {I18n.t("SIS ID")}
                </th>
                <th>
                  {I18n.t("Teacher")}
                </th>
                <th>
                  {I18n.t("Enrollments")}
                </th>
                <th />
              </tr>
            </thead>

            <tbody>
              {courses.map((course) => <CoursesListRow key={course.id} {...course} />)}
            </tbody>
          </table>
        </div>
      );
    }
  });

  return CoursesList;
});
