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
    classes,
    description,
    endOfRangePoints,
    footer,
    long_description,
    points,
    onClick,
    tierColor,
    hidePoints,
    isSummary,
    selected
  } = props

  const shaderStyle = { backgroundColor: tierColor }
  const triangleStyle = { borderBottomColor: tierColor }

  const ratingPoints = () => (
    <div className="rating-points">
      <Text size="small" weight="bold">
        {pointString(points, endOfRangePoints)}
      </Text>
    </div>
  )

  return (
    <div
      className={classes}
      onClick={assessing ? onClick : null}
      onKeyPress={(e) => e.key === 'Enter' ? onClick() : null}
      role={assessing ? "button" : null}
      tabIndex={assessing ? 0 : null}
    >
      {hidePoints ? null : ratingPoints()}
      <div className="rating-description">
        <Text size="small" lineHeight="condensed" weight="bold">
          {description}
        </Text>
      </div>
      <Text size="small" lineHeight="condensed">
        {long_description}
      </Text>
      {
        footer !== null ? (
          <div className="rating-footer">
            {footer}
          </div>
        ) : null
      }
      <div className='shader' style={shaderStyle}
        aria-label={isSummary || !selected ? null : I18n.t('This rating is selected')}>
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

const getCustomColor = (points, pointsPossible, customRatings) => {
  const sortedRatings = _.sortBy(customRatings, 'points').reverse()
  const scaledPoints = pointsPossible > 0 ? points * (sortedRatings[0].points / pointsPossible) : points
  const selectedRating = _.find(sortedRatings, (rating) => ( scaledPoints >= rating.points ))
  if (selectedRating) {
    return `#${selectedRating.color}`
  } else {
    return `#${_.last(sortedRatings).color}`
  }
}

Rating.propTypes = {
  ...tierShape,
  assessing: PropTypes.bool.isRequired,
  footer: PropTypes.node,
  selected: PropTypes.bool,
  hidePoints: PropTypes.bool,
  isSummary: PropTypes.bool.isRequired,
}
Rating.defaultProps = {
  footer: null,
  selected: false,
  endOfRangePoints: null, // eslint-disable-line react/default-props-match-prop-types
  hidePoints: false
}

const Ratings = (props) => {
  const {
    assessing,
    customRatings,
    defaultMasteryThreshold,
    footer,
    tiers,
    points,
    pointsPossible,
    hidePoints,
    onPointChange,
    isSummary,
    useRange
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
      return getCustomColor(points, pointsPossible, customRatings)
    } else {
      return getDefaultColor(points, defaultMasteryThreshold)
    }
  }

  const selectedIndex = points !== undefined ? currentIndex() : null
  const ratings = tiers.map((tier, index) => {
    const selected = selectedIndex === index
    if (isSummary && !selected) return null
    const classes = classNames({
      'rating-tier': true,
      'selected': selected,
    })

    return (
      <Rating
        key={index} // eslint-disable-line react/no-array-index-key
        assessing={assessing}
        classes={classes}
        endOfRangePoints={useRange ? getRangePoints(tier.points, tiers[index + 1]) : null}
        footer={footer}
        onClick={() => onPointChange(tier.points)}
        tierColor={getTierColor(selected)}
        hidePoints={isSummary || hidePoints}
        isSummary={isSummary}
        selected={selected}
        {...tier}
      />
    )
  }).filter((v) => v !== null)

  const defaultRating = () => (
    <Rating
      key={0}
      classes="rating-tier"
      description={I18n.t('No details')}
      footer={footer}
      points={0}
      hidePoints={isSummary || hidePoints}
    />
  )

  return (
    <div className={classNames("rating-tier-list", { 'react-assessing': assessing })}>
      {ratings.length > 0 || !isSummary ? ratings : defaultRating()}
    </div>
  )
}
Ratings.propTypes = {
  ...ratingShape,
  assessing: PropTypes.bool.isRequired,
  footer: PropTypes.node,
  onPointChange: PropTypes.func,
  isSummary: PropTypes.bool.isRequired,
  hidePoints: PropTypes.bool
}
Ratings.defaultProps = {
  footer: null,
  hidePoints: false,
  onPointChange: () => { }
}

export default Ratings
