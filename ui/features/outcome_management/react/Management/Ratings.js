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

import React, {useCallback} from 'react'
import PropTypes from 'prop-types'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconPlusLine} from '@instructure/ui-icons'
import I18n from 'i18n!OutcomeManagement'
import {View} from '@instructure/ui-view'
import {createRating} from '@canvas/outcomes/react/hooks/useRatings'
import useCanvasContext from '@canvas/outcomes/react/hooks/useCanvasContext'
import ProficiencyRating from '../MasteryScale/ProficiencyRating'

const ratingsShape = PropTypes.shape({
  description: PropTypes.string,
  points: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  mastery: PropTypes.bool
})

const Ratings = ({ratings, onChangeRatings, canManage}) => {
  const {isMobileView} = useCanvasContext()

  const addRow = () => {
    let points = 0.0
    const last = ratings[ratings.length - 1]

    if (last) {
      points = last.points - 1.0
    }

    if (points < 0.0 || Number.isNaN(points)) {
      points = 0.0
    }

    onChangeRatings([...ratings, createRating('', points, null, false)])
  }

  const onRatingFieldChange = (field, value, index) => {
    onChangeRatings(currentRatings => {
      let ratingsCopy = [...currentRatings]

      const newRating = {
        ...ratingsCopy[index],
        [field]: value
      }

      const oldRating = ratingsCopy[index]

      // if mastery was set to true here
      // remove mastery from all
      if (newRating.mastery && !oldRating.mastery) {
        ratingsCopy = ratingsCopy.map(r => ({
          ...r,
          mastery: false
        }))
      }

      ratingsCopy.splice(index, 1, newRating)

      return ratingsCopy
    })
  }

  const handleDelete = useCallback(
    currentIndex => {
      onChangeRatings(currentRatings => {
        const ratingsCopy = [...currentRatings]

        const currentRating = currentRatings[currentIndex]
        ratingsCopy.splice(currentIndex, 1)

        if (currentRating.mastery) {
          const newMasteryIndex = Math.max(currentIndex - 1, 0)
          ratingsCopy[newMasteryIndex] = {
            ...ratingsCopy[newMasteryIndex],
            mastery: true
          }
        }

        return ratingsCopy
      })
    },
    [onChangeRatings]
  )

  const renderBorder = () => (
    <View
      width="100%"
      textAlign="start"
      margin="0 0 small 0"
      as="div"
      borderWidth="none none small none"
    />
  )

  return (
    <>
      <Flex
        width="100%"
        padding={isMobileView ? '0 0 small 0' : '0 small small small'}
        margin="medium none none"
        data-testid="outcome-management-ratings"
      >
        <Flex.Item size={isMobileView ? '25%' : '15%'} padding="0 medium 0 0">
          <div aria-hidden="true" className="header">
            {I18n.t('Mastery')}
          </div>
        </Flex.Item>
        <Flex.Item size={isMobileView ? '75%' : '65%'}>
          <div aria-hidden="true" className="header">
            {I18n.t('Proficiency Rating')}
          </div>
        </Flex.Item>
        {!isMobileView && (
          <Flex.Item size="10%">
            <div aria-hidden="true" className="header">
              {I18n.t('Points')}
            </div>
          </Flex.Item>
        )}
      </Flex>
      {renderBorder()}
      {ratings.map(({key, description, descriptionError, pointsError, mastery, points}, index) => (
        <React.Fragment key={key}>
          <ProficiencyRating
            description={description}
            descriptionError={descriptionError}
            disableDelete={ratings.length === 1}
            mastery={mastery}
            onDelete={() => handleDelete(index)}
            onDescriptionChange={value => onRatingFieldChange('description', value, index)}
            onMasteryChange={() => onRatingFieldChange('mastery', true, index)}
            onPointsChange={value => onRatingFieldChange('points', value, index)}
            points={points?.toString()}
            pointsError={pointsError}
            isMobileView={isMobileView}
            position={index + 1}
            canManage={canManage}
            individualOutcome
          />
          {renderBorder()}
        </React.Fragment>
      ))}
      {canManage && (
        <View textAlign="center" padding="small" as="div">
          <IconButton
            onClick={addRow}
            withBorder={false}
            color="primary"
            size="large"
            shape="circle"
            screenReaderLabel={I18n.t('Add Mastery Level')}
          >
            <IconPlusLine />
          </IconButton>
        </View>
      )}
    </>
  )
}

Ratings.propTypes = {
  ratings: PropTypes.arrayOf(ratingsShape).isRequired,
  canManage: PropTypes.bool,
  onChangeRatings: PropTypes.func
}

Ratings.defaultProps = {
  onChangeRatings: () => {}
}

export default Ratings
