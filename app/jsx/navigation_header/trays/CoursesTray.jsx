/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  var CoursesTray = React.createClass({
    propTypes: {
      courses: React.PropTypes.array.isRequired,
      closeTray: React.PropTypes.func.isRequired
    },

    getDefaultProps() {
      return {
        courses: []
      };
    },

    renderCourses() {
      var courses = this.props.courses.map((course) => {
        return <li key={course.id}><a href={`/courses/${course.id}`}>{course.name}</a></li>;
      });
      courses.push(<li key='allCourseLink'><a href='/courses'>All Courses ❯</a></li>);
      return courses;
    },

    render() {
      return (
        <div className="ReactTray__layout">
          <div className="ReactTray__primary-content">
            <div className="ReactTray__header">
              <h1 className="ReactTray__headline">{I18n.t('Courses')}</h1>
              <button className="Button Button--icon-action ReactTray__closeBtn" type="button" onClick={this.props.closeTray}>
                <i className="icon-x"></i>
                <span className="screenreader-only">{I18n.t('Close')}</span>
              </button>
            </div>
            <ul className="ReactTray__link-list">
              {this.renderCourses()}
            </ul>
          </div>
          <div className="ReactTray__secondary-content">
            <div className="ReactTray__info-box">
              {I18n.t('Welcome to your courses! To customize the list of courses,' +
                      'click on the "All Courses" link and star the courses to display.')}
            </div>
          </div>
        </div>
      );
    }
  });

  return CoursesTray;

});
