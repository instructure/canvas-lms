/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import StudentRangeItem from './student-range-item'

const {object, func} = PropTypes

// eslint-disable-next-line react/prefer-stateless-function
export default class StudentRange extends React.Component {
  static propTypes = {
    range: object.isRequired,
    onStudentSelect: func.isRequired,
  }

  render() {
    return (
      <div className="crs-student-range">
        {this.props.range.students.map((student, i) => {
          return (
            <StudentRangeItem
              key={student.user.id}
              student={student}
              studentIndex={i}
              selectStudent={this.props.onStudentSelect}
            />
          )
        })}
      </div>
    )
  }
}
