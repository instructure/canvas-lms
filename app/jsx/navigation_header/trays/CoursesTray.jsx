/** @jsx React.DOM */

define([
  'i18n!new_nav',
  'react',
  'jsx/shared/SVGWrapper'
], (I18n, React, SVGWrapper) => {

  SVGWrapper = React.createFactory(SVGWrapper);

  var CoursesTray = React.createClass({
    propTypes: {
      courses: React.PropTypes.array.isRequired
    },

    getDefaultProps() {
      return {
        courses: []
      };
    },

    renderCourses() {
      return this.props.courses.map((course) => {
        return <li key={course.id}><a href={`/courses/${course.id}`}>{course.name}</a></li>;
      });
    },

    render() {
      return (
        <div>
          <h1>{I18n.t('Courses')}</h1>
          <ul>
            {this.renderCourses()}
          </ul>
        </div>
      );
    }
  });

  return CoursesTray;

});
