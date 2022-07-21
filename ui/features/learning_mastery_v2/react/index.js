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
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import ProficiencyFilter from './ProficiencyFilter'
import Gradebook from './Gradebook'
import useRollups from './hooks/useRollups'
import GradebookMenu from '@canvas/gradebook-menu/react/gradebook_menu'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('LearningMasteryGradebook')

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
  const {isLoading, students, outcomes, rollups} = useRollups({courseId})
  const options = ENV.GRADEBOOK_OPTIONS
  return (
    <>
      <View
        width="100%"
        display="block"
        padding="medium small medium small"
        borderWidth="0 0 small 0"
        data-testid="lmgb-gradebook-menu"
      >
        <GradebookMenu
          courseUrl={options.context_url}
          learningMasteryEnabled
          variant="DefaultGradebookLearningMastery"
        />
      </View>
      <Flex.Item as="div" width="100%" padding="small 0 0 0">
        <ProficiencyFilter ratings={getRatings()} />
      </Flex.Item>
      {isLoading ? (
        renderLoader()
      ) : (
        <Gradebook courseId={courseId} outcomes={outcomes} students={students} rollups={rollups} />
      )}
    </>
  )
}

LearningMastery.propTypes = {
  courseId: PropTypes.string.isRequired
}

export default LearningMastery
