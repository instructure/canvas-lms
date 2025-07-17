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
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {IconArrowOpenDownSolid} from '@instructure/ui-icons'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Gradebook} from './components/Gradebook'
import useRollups from './hooks/useRollups'
import GradebookMenu from '@canvas/gradebook-menu/react/GradebookMenu'
import {Flex} from '@instructure/ui-flex'
import {InstUISettingsProvider} from '@instructure/emotion'
import {IconButton} from '@instructure/ui-buttons'
import LMGBContext, {
  getLMGBContext,
  LMGBContextType,
} from '@canvas/outcomes/react/contexts/LMGBContext'
import {ExportCSVButton} from './components/ExportCSVButton'
import {FilterWrapper} from './components/filters/FilterWrapper'

const I18n = createI18nScope('LearningMasteryGradebook')

const componentOverrides = {
  Link: {
    // TODO: this should be changed to theme.colors.contrasts.grey125125
    color: '#273540',
  },
}

const renderLoader = (): JSX.Element => (
  <View width="100%" display="block" textAlign="center">
    <Spinner size="large" renderTitle={I18n.t('Loading')} />
  </View>
)

interface LearningMasteryProps {
  courseId: string
}

const LearningMastery: React.FC<LearningMasteryProps> = ({courseId}) => {
  const contextValues = getLMGBContext() as LMGBContextType
  const {contextURL, accountLevelMasteryScalesFF} = contextValues.env

  const {
    isLoading,
    students,
    outcomes,
    rollups,
    gradebookFilters,
    setGradebookFilters,
    pagination,
    setCurrentPage,
    setStudentsPerPage,
    sorting,
  } = useRollups({
    courseId,
    accountMasteryScalesEnabled: accountLevelMasteryScalesFF ?? false,
  })

  const onGradebookFilterChange = (filterItem: string) => {
    const filters = new Set(gradebookFilters)

    if (filters.has(filterItem)) {
      filters.delete(filterItem)
    } else {
      filters.add(filterItem)
    }

    setGradebookFilters(Array.from(filters))
  }

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
                courseUrl={contextURL ?? ''}
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
      <FilterWrapper pagination={pagination} onPerPageChange={setStudentsPerPage} />
      {isLoading ? (
        renderLoader()
      ) : (
        <Gradebook
          courseId={courseId}
          outcomes={outcomes}
          students={students}
          rollups={rollups}
          gradebookFilters={gradebookFilters}
          gradebookFilterHandler={onGradebookFilterChange}
          pagination={pagination}
          setCurrentPage={setCurrentPage}
          sorting={sorting}
        />
      )}
    </LMGBContext.Provider>
  )
}

export default LearningMastery
