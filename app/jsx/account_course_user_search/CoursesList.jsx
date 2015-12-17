define([
  "react",
  "i18n!account_course_user_search",
  "underscore",
  "./CoursesListRow",
], function(React, I18n, _, CoursesListRow) {

  var { number, string, func, shape, arrayOf } = React.PropTypes;

  let defaultDirection = 'ASC';
  var CoursesList = React.createClass({
    getInitialState () {
      return {
        sort: {
          direction: defaultDirection,
          property: 'name'
        }
      }
    },
    propTypes: {
      courses: arrayOf(shape(CoursesListRow.propTypes)).isRequired
    },
    sortArrow (column) {
      let className = this.state.sort.direction == defaultDirection ? 'icon-mini-arrow-down' : 'icon-mini-arrow-up';

      // Defaults to sort the name
      if (column == this.state.sort.property) {
        return <i className={className} />;
      }
    },
    sortCourses ({property, direction}) {
      let courses = _.sortBy(this.props.courses, (course) => {
        return property === 'display_name' ? course.teachers.display_name : course[property];
      });

      if (direction == 'DESC') {
        courses.reverse()
      }

      return courses;
    },
    toggleDirection (direction) {
      if (direction == 'DESC') {
        return 'ASC';
      } else {
        return 'DESC';
      }
    },
    sort (theProperty) {
      let {property, direction} = this.state.sort;

      if (theProperty == property) { // toggle the direction? Or use a new default
        direction = this.toggleDirection(direction);
      } else {
        direction = defaultDirection;
      }

      this.setState({
        sort: {
          direction: direction,
          property: theProperty
        }
      });
    },
    render() {
      let courses = this.sortCourses(this.state.sort);

      return (

        <div className="content-box" role='grid'>
          <div role='row' className="grid-row border border-b pad-box-mini">
            <div className="col-md-3">
              <div className="grid-row">
                <div className="col-xs-2">
                </div>
                <div className="col-xs-10" role='columnheader'>
                  <strong>
                    <a href="#" className="coursesHeaderLink" onClick={this.sort.bind(this, 'name')}><small>{I18n.t("Course")}</small>{this.sortArrow('name')}</a>
                  </strong>
                </div>
              </div>
            </div>
            <div role='columnheader' className="col-xs-1">
              <strong><a href="#" className="courseSIS" onClick={this.sort.bind(this, 'sis_course_id')}><small>{I18n.t("SIS ID")}</small>{this.sortArrow('sis_course_id')}</a></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><a href="#" className="sortTeacherName" onClick={this.sort.bind(this, 'display_name')}><small>{I18n.t("Teacher")}</small>{this.sortArrow('display_name')}</a></strong>
            </div>
            <div role='columnheader' className="col-md-3">
              <strong><a href="#" className="sortEnrollments" onClick={this.sort.bind(this, 'total_students')}><small>{I18n.t("Enrollments")}</small>{this.sortArrow('total_students')}</a></strong>
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
