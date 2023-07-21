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
import classNames from 'classnames'
import categoryHelper from '@canvas/assignments/assignment-categories'
import {transformScore} from '@canvas/conditional-release-score'
import assignmentShape from '../shapes/assignment'

const {number} = PropTypes

// eslint-disable-next-line react/prefer-stateless-function
export default class StudentAssignmentItem extends React.Component {
  static propTypes = {
    assignment: assignmentShape.isRequired,
    trend: number,
    score: number,
  }

  render() {
    const {trend} = this.props

    const trendClasses = classNames({
      'crs-student__trend-icon': true,
      'crs-student__trend-icon__positive': trend === 1,
      'crs-student__trend-icon__neutral': trend === 0,
      'crs-student__trend-icon__negative': trend === -1,
    })

    const showTrend = trend !== null && trend !== undefined
    const category = categoryHelper.getCategory(this.props.assignment).id

    return (
      <div className="crs-student-details__assignment">
        <i
          className={`icon-${category} crs-student-details__assignment-icon crs-icon-${category}`}
        />
        <div className="crs-student-details__assignment-name">{this.props.assignment.name}</div>
        <div className="crs-student-details__assignment-score">
          <div>{transformScore(this.props.assignment.score, this.props.assignment, true)}</div>
          {showTrend && <span className={trendClasses} />}
        </div>
      </div>
    )
  }
}
