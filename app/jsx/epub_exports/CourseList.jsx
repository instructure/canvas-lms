/** @jsx React.DOM */

define([
  'react',
  'underscore',
  'jsx/epub_exports/CourseListItem'
], function(React, _, CourseListItem){

  var CourseList = React.createClass({
    displayName: 'CourseList',
    propTypes: {
      courses: React.PropTypes.object,
    },

    //
    // Rendering
    //

    render() {
      return (
        <ul className='ig-list'>
          {_.map(this.props.courses, function(course, key) {
            return <CourseListItem key={key} course={course}/>;
          })}
        </ul>
      );
    }
  });

  return CourseList;
});
