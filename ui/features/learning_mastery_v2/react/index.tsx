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

import React, {useState} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Gradebook} from './components/Gradebook'
import useRollups from './hooks/useRollups'
import LMGBContext, {
  getLMGBContext,
  LMGBContextType,
} from '@canvas/outcomes/react/contexts/LMGBContext'
import {FilterWrapper} from './components/filters/FilterWrapper'
import {Toolbar} from './components/toolbar/Toolbar'
import {getSearchParams, setSearchParams} from './utils/ManageURLSearchParams'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {DEFAULT_GRADEBOOK_SETTINGS, DisplayFilter, GradebookSettings} from './utils/constants'

const I18n = createI18nScope('LearningMasteryGradebook')

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
  const [gradebookSettings, setGradebookSettings] = useState<GradebookSettings>(
    DEFAULT_GRADEBOOK_SETTINGS,
  )

  const {
    isLoading,
    error,
    students,
    outcomes,
    rollups,
    gradebookFilters,
    setGradebookFilters,
    pagination,
    currentPage,
    setCurrentPage,
    studentsPerPage,
    setStudentsPerPage,
    sorting,
  } = useRollups({
    courseId,
    accountMasteryScalesEnabled: accountLevelMasteryScalesFF ?? false,
    ...getSearchParams(),
  })

  setSearchParams(currentPage, studentsPerPage, sorting)

  const addGradebookFilter = (filterItem: string) => {
    const filters = new Set(gradebookFilters)
    if (filters.has(filterItem)) return
    filters.add(filterItem)
    setGradebookFilters(Array.from(filters))
  }

  const removeGradebookFilter = (filterItem: string) => {
    const filters = new Set(gradebookFilters)
    if (!filters.has(filterItem)) return
    filters.delete(filterItem)
    setGradebookFilters(Array.from(filters))
  }

  const handleGradebookSettingsChange = (settings: GradebookSettings) => {
    setGradebookSettings(settings)

    if (settings.displayFilters.includes(DisplayFilter.SHOW_STUDENTS_WITH_NO_RESULTS)) {
      removeGradebookFilter('missing_user_rollups')
    } else {
      addGradebookFilter('missing_user_rollups')
    }
  }

  const renderBody = () => {
    if (error !== null)
      return (
        <GenericErrorPage
          errorMessage={error}
          imageUrl={errorShipUrl}
          errorSubject={I18n.t('Error loading rollups')}
          errorCategory={I18n.t('Learning Mastery Gradebook Error Page')}
        />
      )
    if (isLoading) return renderLoader()
    return (
      <Gradebook
        courseId={courseId}
        outcomes={outcomes}
        students={students}
        rollups={rollups}
        pagination={pagination}
        setCurrentPage={setCurrentPage}
        sorting={sorting}
        gradebookSettings={gradebookSettings}
        data-testid="gradebook-body"
      />
    )
  }

  return (
    <LMGBContext.Provider value={contextValues}>
      <Toolbar
        courseId={courseId}
        contextURL={contextURL}
        gradebookFilters={gradebookFilters}
        showDataDependentControls={error === null}
        gradebookSettings={gradebookSettings}
        setGradebookSettings={handleGradebookSettingsChange}
      />
      <FilterWrapper pagination={pagination} onPerPageChange={setStudentsPerPage} />
      {renderBody()}
    </LMGBContext.Provider>
  )
}

export default LearningMastery
