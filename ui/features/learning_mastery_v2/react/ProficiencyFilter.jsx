/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {View} from '@instructure/ui-view'
import {useScope as useI18nScope} from '@canvas/i18n'
import ProficiencyRating from './ProficiencyRating'
import {proficiencyRatingShape} from './shapes'

const I18n = useI18nScope('LearningMasteryGradebook')

const ProficiencyFilter = ({ratings, visibleRatings, setVisibleRatings}) => {
  const onClickPill = (isVisible, visibleIndex) => {
    let index
    if (visibleIndex === null) {
      index = 0
    } else {
      index = visibleIndex + 1
    }
    const visible = [...visibleRatings]
    visible[index] = isVisible
    setVisibleRatings(visible)
  }

  return (
    <View display="flex" padding="small 0 small 0">
      <View display="flex">
        {ratings.map(({points, color, description, masteryAt}) => (
          <ProficiencyRating
            points={points}
            masteryAt={masteryAt}
            color={color}
            description={description}
            onClick={onClickPill}
            key={points}
          />
        ))}
      </View>
    </View>
  )
}

ProficiencyFilter.propTypes = {
  ratings: PropTypes.arrayOf(PropTypes.shape(proficiencyRatingShape)).isRequired,
  visibleRatings: PropTypes.arrayOf(PropTypes.bool).isRequired,
  setVisibleRatings: PropTypes.func.isRequired,
}
export default ProficiencyFilter
