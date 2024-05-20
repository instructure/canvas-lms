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
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import ProficiencyFilter from './ProficiencyFilter'
import Gradebook from './Gradebook'
import useRollups from './hooks/useRollups'
import GradebookMenu from '@canvas/gradebook-menu/react/GradebookMenu'
import {Flex} from '@instructure/ui-flex'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import LMGBContext, {getLMGBContext} from '@canvas/outcomes/react/contexts/LMGBContext'
import ExportCSVButton from './ExportCSVButton'

const I18n = useI18nScope('LearningMasteryGradebook')

const getRatings = ratings => {
  const masteryAt = ratings.find(rating => rating.mastery).points
  return [
    ...ratings.map(({points, description, color}) => ({
      description: description === I18n.t('Below Mastery') ? I18n.t('Remediation') : description,
      points,
      masteryAt,
      color: '#' + color,
    })),
    {points: null, masteryAt, color: null, description: I18n.t('Not Assessed')},
  ]
}

const componentOverrides = {
  Link: {
    color: 'licorice',
  },
}

const renderLoader = () => (
  <View width="100%" display="block" textAlign="center">
    <Spinner size="large" renderTitle={I18n.t('Loading')} />
  </View>
)

const LearningMastery = ({courseId}) => {
  const contextValues = getLMGBContext()
  const {contextURL, outcomeProficiency, accountLevelMasteryScalesFF} = contextValues.env

  const {isLoading, students, outcomes, rollups, gradebookFilters, setGradebookFilters} =
    useRollups({
      courseId,
      accountLevelMasteryScalesFF,
    })
  const [visibleRatings, setVisibleRatings] = useState([])

  const onGradebookFilterChange = filterItem => {
    const filters = new Set(gradebookFilters)

    if (filters.has(filterItem)) {
      filters.delete(filterItem)
    } else {
      filters.add(filterItem)
    }

    setGradebookFilters(Array.from(filters))
  }

  useEffect(() => {
    if (accountLevelMasteryScalesFF) {
      setVisibleRatings([true, true, true, true, true, true])
    }
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <LMGBContext.Provider value={contextValues}>
      <InstUISettingsProvider theme={{componentOverrides}}>
        <Flex
          height="100%"
          display="flex"
          alignItems="center"
          justifyItems="space-between"
          padding="medium 0 0 0"
          data-testid="lmgb-menu-and-settings"
        >
          <Flex alignItems="center" data-testid="lmgb-gradebook-menu">
            <Text size="xx-large" weight="bold">
              {I18n.t('Learning Mastery Gradebook')}
            </Text>
            <View padding="xx-small">
              <GradebookMenu
                courseUrl={contextURL}
                learningMasteryEnabled={true}
                variant="DefaultGradebookLearningMastery"
                customTrigger={
                  <IconButton
                    withBorder={false}
                    withBackground={false}
                    screenReaderLabel={I18n.t('Gradebook Menu Dropdown')}
                  >
                    <IconArrowOpenDownSolid size="x-small" />
                  </IconButton>
                }
              />
            </View>
          </Flex>
          <View>
            <ExportCSVButton
              courseId={courseId}
              gradebookFilters={gradebookFilters}
              data-testid="export-csv-button"
            />
          </View>
        </Flex>
      </InstUISettingsProvider>
      {accountLevelMasteryScalesFF && (
        <Flex.Item as="div" width="100%" padding="small 0 0 0">
          <ProficiencyFilter
            ratings={getRatings(outcomeProficiency.ratings)}
            visibleRatings={visibleRatings}
            setVisibleRatings={setVisibleRatings}
          />
        </Flex.Item>
      )}
      {isLoading ? (
        renderLoader()
      ) : (
        <Gradebook
          courseId={courseId}
          outcomes={outcomes}
          students={students}
          rollups={rollups}
          visibleRatings={visibleRatings}
          gradebookFilters={gradebookFilters}
          gradebookFilterHandler={onGradebookFilterChange}
        />
      )}
    </LMGBContext.Provider>
  )
}

LearningMastery.propTypes = {
  courseId: PropTypes.string.isRequired,
}

export default LearningMastery
