import React from 'react'
import _ from 'underscore'
import CourseListItem from 'jsx/epub_exports/CourseListItem'

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

export default CourseList
