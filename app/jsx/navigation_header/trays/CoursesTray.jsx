define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  var CoursesTray = React.createClass({
    propTypes: {
      courses: React.PropTypes.array.isRequired,
      closeTray: React.PropTypes.func.isRequired,
      hasLoaded: React.PropTypes.bool.isRequired
    },

    getDefaultProps() {
      return {
        courses: []
      };
    },

    renderCourses() {
      if (!this.props.hasLoaded) {
        return (
          <li className="ic-NavMenu-list-item ic-NavMenu-list-item--loading-message">
            {I18n.t('Loading')} &hellip;
          </li>
        );
      }
      var courses = this.props.courses.map((course) => {
        return (
          <li key={course.id} className='ic-NavMenu-list-item'>
            <a href={`/courses/${course.id}`} className='ic-NavMenu-list-item__link'>{course.name}</a>
            { course.enrollment_term_id > 1 ? ( <div className='ic-NavMenu-list-item__helper-text'>{course.term.name}</div> ) : null }
          </li>
        );
      });
      courses.push(
        <li key='allCourseLink' className='ic-NavMenu-list-item ic-NavMenu-list-item--feature-item'>
          <a href='/courses' className='ic-NavMenu-list-item__link'>{I18n.t('All Courses')}</a>
        </li>
      );
      return courses;
    },

    render() {
      return (
        <div className="ic-NavMenu__layout">
          <div className="ic-NavMenu__primary-content">
            <div className="ic-NavMenu__header">
              <h1 className="ic-NavMenu__headline">{I18n.t('Courses')}</h1>
              <button className="Button Button--icon-action ic-NavMenu__closeButton" type="button" onClick={this.props.closeTray}>
                <i className="icon-x"></i>
                <span className="screenreader-only">{I18n.t('Close')}</span>
              </button>
            </div>
            <ul className="ic-NavMenu__link-list">
              {this.renderCourses()}
            </ul>
          </div>
          <div className="ic-NavMenu__secondary-content">
              {I18n.t('Welcome to your courses! To customize the list of courses, ' +
                      'click on the "All Courses" link and star the courses to display.')}
          </div>
        </div>
      );
    }
  });

  return CoursesTray;

});
