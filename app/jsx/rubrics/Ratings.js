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
import React from 'react'
import classNames from 'classnames'
import _ from 'lodash'
import PropTypes from 'prop-types'
import Text from '@instructure/ui-core/lib/components/Text'
import I18n from 'i18n!edit_rubric'

import { ratingShape, tierShape } from './types'

const pointString = (points) =>
  I18n.t('%{points} pts', {
    points: I18n.toNumber(points, { precision : 1 })
  })

const Rating = (props) => {
  const {
    description,
    long_description,
    points,
    onClick,
    classes
  } = props

  return (
    <div
      className={classes}
      onClick={onClick}
      onKeyPress={(e) => e.key === 'Enter' ? onClick() : null}
      role="button"
      tabIndex={0}
    >
      <div className="rating-points">
        <Text size="x-small">
          {pointString(points)}
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
      <div className='shader'><div className="triangle"/></div>
    </div>
  )
}

const getMasteryLevel = (points, masteryThreshold) => {
  if (points >= masteryThreshold) {
    return 'full'
  } else if (points >= masteryThreshold/2) {
    return 'partial'
  } else {
    return 'none'
  }
}

Rating.propTypes = {
  ...tierShape,
  selected: PropTypes.bool
}
Rating.defaultProps = {
  selected: false,
}

const Ratings = ({ assessing, tiers, points, onPointChange, masteryThreshold }) => {
  const pairs = tiers.map((tier, index) => {
    const next = tiers[index + 1]
    return { current: tier.points, next: next ? next.points : 0 }
  })

  const selectedIndex = _.findIndex(pairs, ({ current, next }) => (
    points > next && points <= current
  ))

  return (
    <div className={classNames("rating-tier-list", { 'react-assessing': assessing })}>
      {
        tiers.map((tier, index) => {
          const selected = selectedIndex === index
          const classes = classNames({
            'rating-tier': true,
            'selected': selected,
          }, selected && getMasteryLevel(points, masteryThreshold))
          return ( // eslint-disable-next-line react/no-array-index-key
            <Rating key={index} onClick={() => onPointChange(tier.points)} classes={classes} {...tier} />
          )
        })
      }
    </div>
  )
}
Ratings.propTypes = {
  ...ratingShape,
  onPointChange: PropTypes.func
}
Ratings.defaultProps = {
  onPointChange: () => { }
}

export default Ratings
