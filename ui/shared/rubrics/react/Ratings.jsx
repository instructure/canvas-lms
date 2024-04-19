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
import $ from 'jquery'
import React from 'react'
import classNames from 'classnames'
import PropTypes from 'prop-types'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {useScope as useI18nScope} from '@canvas/i18n'

import {ratingShape, tierShape} from './types'

const I18n = useI18nScope('edit_rubricRatings')

const pointString = (points, endOfRangePoints) => {
  if (endOfRangePoints !== null) {
    return I18n.t('%{points} to >%{endOfRangePoints} pts', {
      points: I18n.toNumber(points, {precision: 2, strip_insignificant_zeros: true}),
      endOfRangePoints: I18n.toNumber(endOfRangePoints, {
        precision: 2,
        strip_insignificant_zeros: true,
      }),
    })
  } else {
    return I18n.t('%{points} pts', {
      points: I18n.toNumber(points, {precision: 2, strip_insignificant_zeros: true}),
    })
  }
}

export const Rating = props => {
  const {
    assessing,
    classes,
    description,
    endOfRangePoints,
    footer,
    long_description,
    points,
    onClick,
    shaderClass,
    tierColor,
    hidePoints,
    isSummary,
    selected,
  } = props

  const shaderStyle = selected && tierColor ? {borderBottom: `0.3em solid ${tierColor}`} : {backgroundColor: tierColor}
  const triangleStyle = {borderBottomColor: tierColor}
  const shaderClasses = classNames('shader', shaderClass)

  const ratingPoints = () => (
    <div className="rating-points">
      <Text size="small" weight="bold">
        {pointString(points, endOfRangePoints)}
      </Text>
    </div>
  )

  return (
    // eslint is unhappy here because it's not smart enough to understand that
    // when this is interact-able (via tabIndex), it will always have a role
    // eslint-disable-next-line jsx-a11y/no-static-element-interactions
    <div
      className={classes}
      onClick={assessing ? onClick : null}
      onKeyPress={e => (e.key === 'Enter' ? onClick() : null)}
      role={assessing ? 'button' : null}
      // eslint-disable-next-line jsx-a11y/no-noninteractive-tabindex
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
      <div className="rating-footer">{footer}</div>
      <div
        className={shaderClasses}
        style={shaderStyle}
        aria-label={isSummary || !selected ? null : I18n.t('This rating is selected')}
      >
        <div className="triangle" style={triangleStyle} />
      </div>
    </div>
  )
}

const getCustomColor = (points, pointsPossible, customRatings) => {
  const sortedRatings = _.sortBy(customRatings, 'points').reverse()
  const scaledPoints =
    pointsPossible > 0 ? points * (sortedRatings[0].points / pointsPossible) : points
  const selectedRating = _.find(sortedRatings, rating => scaledPoints >= rating.points)
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
  shaderClass: PropTypes.string,
}
Rating.defaultProps = {
  footer: null,
  selected: false,
  endOfRangePoints: null, // eslint-disable-line react/default-props-match-prop-types
  hidePoints: false,
  shaderClass: null,
}

const Ratings = props => {
  const {
    assessing,
    selectedRatingId,
    customRatings,
    defaultMasteryThreshold,
    footer,
    tiers,
    points,
    pointsPossible,
    hidePoints,
    onPointChange,
    isSummary,
    useRange,
  } = props

  const pairs = tiers.map((tier, index) => {
    const next = tiers[index + 1]
    return {current: tier.points, next: next ? next.points : null}
  })

  const currentIndex = () => {
    if (selectedRatingId) {
      return _.findIndex(
        tiers,
        tier => tier.id === selectedRatingId && (useRange || tier.points === points)
      )
    } else {
      return pairs.findIndex(({current, next}) => {
        const currentMatch = points === current
        const withinRange = points > next && points <= current
        const zeroAndInLastRange = points === 0 && next === null
        return currentMatch || (useRange && (withinRange || zeroAndInLastRange))
      })
    }
  }

  const getRangePoints = (currentPoints, nextTier) => {
    if (nextTier) {
      return currentPoints === nextTier.points ? null : nextTier.points
    } else if (currentPoints !== 0) {
      return 0
    }
    return null
  }

  const getTierColor = selected => {
    if (!selected) {
      return 'transparent'
    }
    if (customRatings && customRatings.length > 0) {
      return getCustomColor(points, pointsPossible, customRatings)
    } else {
      return null
    }
  }

  const getShaderClass = selected => {
    if (!selected) {
      return null
    }
    if (customRatings && customRatings.length > 0) {
      return null
    }
    if (points >= defaultMasteryThreshold * 1.5) {
      return 'exceedsMasteryShader'
    } else if (points >= defaultMasteryThreshold) {
      return 'meetsMasteryShader'
    } else if (points >= defaultMasteryThreshold / 2) {
      return 'nearMasteryShader'
    } else {
      return 'wellBelowMasteryShader'
    }
  }

  const handleClick = (tier, selected) => {
    onPointChange(tier, selected)
    $.screenReaderFlashMessage(selected ? I18n.t('Rating selected') : I18n.t('Rating unselected'))
  }

  const selectedIndex = points !== undefined ? currentIndex() : null

  const visible = tiers
    .map((tier, index) => ({
      tier,
      index,
      selected: selectedIndex === index,
    }))
    .filter(({selected}) => (isSummary ? selected : true))

  const ratings = visible
    .map(({tier, index}) => {
      const selected = selectedIndex === index
      const classes = classNames({
        'rating-tier': true,
        selected,
        assessing,
      })

      return (
        <Flex.Item key={`tier-${index}`} width={`${100 / visible.length}%`} align="start">
          <Rating
            key={index}
            assessing={assessing}
            classes={classes}
            endOfRangePoints={useRange ? getRangePoints(tier.points, tiers[index + 1]) : null}
            footer={isSummary ? footer : null}
            onClick={() => handleClick(tier, selected)}
            shaderClass={getShaderClass(selected)}
            tierColor={getTierColor(selected)}
            long_description={tier.long_description}
            hidePoints={isSummary || hidePoints}
            isSummary={isSummary}
            selected={selected}
            {...tier}
          />
        </Flex.Item>
      )
    })
    .filter(v => v !== null)

  const defaultRating = () => (
    <Rating
      key={0}
      assessing={assessing}
      classes="rating-tier"
      description={I18n.t('No details')}
      footer={footer}
      isSummary={isSummary}
      points={0}
      hidePoints={isSummary || hidePoints}
    />
  )

  const fullFooter = () =>
    isSummary || _.isNil(footer) ? null : <div className="rating-all-footer">{footer}</div>

  return (
    <div>
      <Flex>{ratings.length > 0 || !isSummary ? ratings : defaultRating()}</Flex>
      {fullFooter()}
    </div>
  )
}
Ratings.propTypes = {
  ...ratingShape,
  assessing: PropTypes.bool.isRequired,
  footer: PropTypes.node,
  onPointChange: PropTypes.func,
  isSummary: PropTypes.bool.isRequired,
  hidePoints: PropTypes.bool,
}
Ratings.defaultProps = {
  footer: null,
  hidePoints: false,
  onPointChange: () => {},
}

export default Ratings
