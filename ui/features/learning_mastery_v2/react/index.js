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

import React, {useEffect, useState} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import I18n from 'i18n!LearningMasteryGradebook'
import ProficiencyFilter from './ProficiencyFilter'
import Gradebook from './Gradebook'
import {loadRollups} from './apiClient'

const getRatings = () => {
  const ratings = ENV.GRADEBOOK_OPTIONS.outcome_proficiency.ratings
  const masteryAt = ratings.find(rating => rating.mastery).points
  return [
    ...ratings.map(({points, description, color}) => ({
      description,
      points,
      masteryAt,
      color: '#' + color
    })),
    {points: null, masteryAt, color: null, description: I18n.t('Not Assessed')}
  ]
}

const renderLoader = () => (
  <View width="100%" display="block" textAlign="center">
    <Spinner size="large" renderTitle={I18n.t('Loading')} />
  </View>
)

const LearningMastery = ({courseId}) => {
  const [isLoading, setIsLoading] = useState(true)
  const [students, setStudents] = useState([])
  useEffect(() => {
    const getRollups = async () => {
      try {
        const {data} = await loadRollups(courseId)
        setStudents(data.linked.users)
        setIsLoading(false)
      } catch (e) {
        showFlashAlert({
          message: I18n.t('Error loading rollups'),
          type: 'error'
        })
      }
    }
    getRollups()
  }, [courseId])

  return (
    <>
      <ProficiencyFilter ratings={getRatings()} />
      {isLoading ? renderLoader() : <Gradebook courseId={courseId} students={students} />}
    </>
  )
}

LearningMastery.propTypes = {
  courseId: PropTypes.string.isRequired
}

export default LearningMastery
