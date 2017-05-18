/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import PropTypes from 'prop-types'
import _ from 'underscore'
import CourseListItem from 'jsx/epub_exports/CourseListItem'

const CourseList = React.createClass({
  displayName: 'CourseList',
  propTypes: {
    courses: PropTypes.object,
  },

  //
  // Rendering
  //

  render () {
    return (
      <ul className="ig-list">
        {_.map(this.props.courses, function (course, key) {
          return <CourseListItem key={key} course={course} />;
        })}
      </ul>
    );
  }
});

export default CourseList
