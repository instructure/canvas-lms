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

import _ from 'lodash'
import React from 'react'
import classNames from 'classnames'
import PropTypes from 'prop-types'
import Text from '@instructure/ui-elements/lib/components/Text'
import I18n from 'i18n!edit_rubric'

import { ratingShape, tierShape } from './types'

const pointString = (points, endOfRangePoints) => {
  if (endOfRangePoints !== null) {
    return I18n.t('%{points} to >%{endOfRangePoints} pts', {
      points: I18n.toNumber(points, { precision : 1 }),
      endOfRangePoints: I18n.toNumber(endOfRangePoints, { precision : 1 })
    })
  }
  else {
    return I18n.t('%{points} pts', {
      points: I18n.toNumber(points, { precision : 1 })
    })
  }
}

export const Rating = (props) => {
  const {
    assessing,
    description,
    long_description,
    points,
    onClick,
    endOfRangePoints,
    classes,
    tierColor
  } = props

  const shaderStyle = {backgroundColor: tierColor}
  const triangleStyle = {borderBottomColor: tierColor}

  return (
    <div
      className={classes}
      onClick={assessing ? onClick : null}
      onKeyPress={(e) => e.key === 'Enter' ? onClick() : null}
      role="button"
      tabIndex={assessing ? 0 : null}
    >
      <div className="rating-points">
        <Text size="x-small">
          {pointString(points, endOfRangePoints)}
        </Text>
      </div>
      <div className="rating-description">
        <Text size="x-small" lineHeight="condensed">
          {description}
        </Text>
      </div>
      <Text size="x-small" fontStyle="italic" lineHeight="condensed">
        {long_description}
      </Text>
      <div className='shader' style={shaderStyle}>
        <div className="triangle" style={triangleStyle}/>
      </div>
    </div>
  )
}

const getDefaultColor = (points, defaultMasteryThreshold) => {
  if (points >= defaultMasteryThreshold) {
    return '#8aac53'
  } else if (points >= defaultMasteryThreshold/2) {
    return '#e0d773'
  } else {
    return '#df5b59'
  }
}

const getCustomColor = (points, customRatings) => {
  const sortedRatings = _.sortBy(customRatings, 'points').reverse()
  const selectedRating = _.find(sortedRatings, (rating) => ( points >= rating.points ))
  if (selectedRating) {
    return `#${selectedRating.color}`
  } else {
    return `#${_.last(sortedRatings).color}`
  }
}

Rating.propTypes = {
  ...tierShape,
  assessing: PropTypes.bool.isRequired,
  selected: PropTypes.bool
}
Rating.defaultProps = {
  selected: false,
  endOfRangePoints: null // eslint-disable-line react/default-props-match-prop-types
}

const Ratings = (props) => {
  const {
    assessing,
    tiers,
    points,
    onPointChange,
    defaultMasteryThreshold,
    useRange,
    customRatings
  } = props

  const pairs = tiers.map((tier, index) => {
    const next = tiers[index + 1]
    return { current: tier.points, next: next ? next.points : null }
  })

  const currentIndex = () => pairs.findIndex(({ current, next }) => {
    const currentMatch = points === current
    const withinRange = points > next && points <= current
    const zeroAndInLastRange = points === 0 && next === null
    return currentMatch || (useRange && (withinRange || zeroAndInLastRange))
  })

  const getRangePoints = (currentPoints, nextTier) => {
    if (nextTier) {
      return currentPoints === nextTier.points ? null : nextTier.points
    } else if (currentPoints !== 0) {
      return 0
    }
    return null
  }

  const getTierColor = (selected) => {
    if (!selected) { return 'transparent' }
    if (customRatings && customRatings.length > 0) {
      return getCustomColor(points, customRatings)
    } else {
      return getDefaultColor(points, defaultMasteryThreshold)
    }
  }

  const selectedIndex = points !== undefined ? currentIndex() : null

  return (
    <div className={classNames("rating-tier-list", { 'react-assessing': assessing })}>
      {
        tiers.map((tier, index) => {
          const selected = selectedIndex === index
          const classes = classNames({
            'rating-tier': true,
            'selected': selected,
          })
          return (
            <Rating
              key={index} // eslint-disable-line react/no-array-index-key
              assessing={assessing}
              onClick={() => onPointChange(tier.points)}
              classes={classes}
              endOfRangePoints={useRange ? getRangePoints(tier.points, tiers[index + 1]) : null}
              tierColor={getTierColor(selected)}
              {...tier}
            />
          )
        })
      }
    </div>
  )
}
Ratings.propTypes = {
  ...ratingShape,
  assessing: PropTypes.bool.isRequired,
  onPointChange: PropTypes.func
}
Ratings.defaultProps = {
  onPointChange: () => { }
}

export default Ratings
