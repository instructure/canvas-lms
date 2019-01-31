/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import PropTypes from 'prop-types'
import React from 'react'

import Complete from './Complete'
import GradingScheme from './GradingScheme'
import Letter from './Letter'
import Percent from './Percent'
import Points from './Points'
import PossiblePoints from './PossiblePoints'

function PointsDisplay(props) {
  const {displayAs, receivedGrade, possiblePoints} = props

  switch (displayAs) {
    case 'points':
      return <Points receivedGrade={receivedGrade} possiblePoints={possiblePoints} />
    case 'percent':
      return <Percent receivedGrade={receivedGrade} />
    case 'pass_fail':
      return <Complete receivedGrade={receivedGrade} />
    case 'gpa_scale':
      return <GradingScheme receivedGrade={receivedGrade} />
    case 'letter_grade':
      return <Letter receivedGrade={receivedGrade} />
    case 'points_possible':
      return <PossiblePoints possiblePoints={possiblePoints} />
    case 'not_graded':
      return <div />
    default:
      throw new Error(`Invalid displayAs option "${displayAs}"`)
  }
}

// TODO once we add other types here, we can use this to only make possiblePoints
//      required if the displayAs is set to points: https://stackoverflow.com/questions/42299335
//      Would be helpful if the other types are actually passing in different data (A, C+, etc).
PointsDisplay.propTypes = {
  displayAs: PropTypes.string.isRequired,
  receivedGrade: PropTypes.oneOf([PropTypes.number, PropTypes.string]),
  possiblePoints: PropTypes.number.isRequired
}

PointsDisplay.defaultProps = {
  displayAs: 'points'
}

export default React.memo(PointsDisplay)
