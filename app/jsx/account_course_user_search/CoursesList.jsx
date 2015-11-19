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

        <div className="content-box" role='grid'>
          <div role='row' className="grid-row border border-b pad-box-mini">
            <div className="col-md-3">
              <div className="grid-row">
                <div className="col-xs-2">
                </div>
                <div className="col-xs-10" role='columnheader'>
                  <strong><small>{I18n.t("Course")}</small></strong>
                </div>
              </div>
            </div>
            <div role='columnheader' className="col-xs-1">
              <strong><small>{I18n.t("SIS ID")}</small></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><small>{I18n.t("Teacher")}</small></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><small>{I18n.t("Enrollments")}</small></strong>
            </div>
            <div role='columnheader' className="col-md-2">
              <span className='screenreader-only'>{I18n.t("Course option links")}</span>
            </div>
          </div>

          <div className='courses-list' role='rowgroup'>
            {courses.map((course) => <CoursesListRow key={course.id} {...course} />)}
          </div>
        </div>
      );
    }
  });

  return CoursesList;
});
