define([
  "react",
  "jquery",
  "i18n!account_course_user_search",
  "underscore",
  "axios",
  "./CoursesListRow",
], function(React, $, I18n, _, axios, CoursesListRow) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  var CoursesList = React.createClass({
    propTypes: {
      courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired
    },

    getInitialState () {
      return {
        sections: []
      };
    },

    componentWillMount () {
      this.props.courses.forEach((course) => {
        axios.get(`/api/v1/courses/${course.id}/sections`)
             .then((response) => {
                this.setState({
                  sections: this.state.sections.concat(response.data)
                });
             });
      });

    },
    render() {
      let courses = this.props.courses;

      return (

        <div className="content-box" role='grid'>
          <div role='row' className="grid-row border border-b pad-box-mini">
            <div className="col-xs-5">
              <div className="grid-row">
                <div className="col-xs-2">
                </div>
                <div className="col-xs-10" role='columnheader'>
                  <span className="courses-user-list-header">
                    {I18n.t("Course")}
                  </span>
                </div>
              </div>
            </div>
            <div role='columnheader' className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t("SIS ID")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-3">
              <span className="courses-user-list-header">
                {I18n.t("Teacher")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-1">
              <span className="courses-user-list-header">
                {I18n.t("Enrollments")}
              </span>
            </div>
            <div role='columnheader' className="col-xs-2">
              <span className='screenreader-only'>{I18n.t("Course option links")}</span>
            </div>
          </div>

          <div className='courses-list' role='rowgroup'>
            {courses.map((course) => {
              let urlsForCourse = {
                USER_LISTS_URL: $.replaceTags(this.props.addUserUrls.USER_LISTS_URL, 'id', course.id),
                ENROLL_USERS_URL: $.replaceTags(this.props.addUserUrls.ENROLL_USERS_URL, 'id', course.id)
              };

              const sectionsForCourse = this.state.sections.filter((section) => {
                return section.course_id === parseInt(course.id, 10);
              });

              return (
                <CoursesListRow
                  key={course.id}
                  courseModel={courses}
                  roles={this.props.roles}
                  urls={urlsForCourse}
                  sections={sectionsForCourse}
                  {...course}
                />
              );
            })}
          </div>
        </div>
      );
    }
  });

  return CoursesList;
});
