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

import React, {useState, useCallback} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as createI18nScope} from '@canvas/i18n'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {Gradebook} from './components/Gradebook'
import useRollups from './hooks/useRollups'
import LMGBContext, {
  getLMGBContext,
  LMGBContextType,
} from '@canvas/outcomes/react/contexts/LMGBContext'
import {FilterWrapper} from './components/filters/FilterWrapper'
import {Toolbar} from './components/toolbar/Toolbar'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {GradebookSettings, NameDisplayFormat} from './utils/constants'
import {saveLearningMasteryGradebookSettings} from './apiClient'
import {useGradebookSettings} from './hooks/useGradebookSettings'

const queryClient = new QueryClient()

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

  const {
    settings: gradebookSettings,
    isLoading: isLoadingSettings,
    updateSettings,
  } = useGradebookSettings(courseId)

  const [isSavingSettings, setIsSavingSettings] = useState(false)

  const {
    isLoading: isLoadingGradebook,
    error,
    students,
    outcomes,
    rollups,
    pagination,
    setCurrentPage,
    sorting,
  } = useRollups({
    courseId,
    accountMasteryScalesEnabled: accountLevelMasteryScalesFF ?? false,
    enabled: !isLoadingSettings,
    settings: gradebookSettings,
  })

  const handleGradebookSettingsChange = useCallback(
    async (settings: GradebookSettings) => {
      setIsSavingSettings(true)
      let error = null

      try {
        const response = await saveLearningMasteryGradebookSettings(courseId, settings)

        if (response.status !== 200) {
          throw new Error('Failed to save settings')
        }

        updateSettings(settings)
      } catch (_) {
        error = I18n.t('Failed to save settings')
      } finally {
        setIsSavingSettings(false)
      }

      return {success: error === null}
    },
    [courseId, updateSettings],
  )

  const handleNameDisplayFormatChange = useCallback(
    async (format: NameDisplayFormat) => {
      const newSettings = {...gradebookSettings, nameDisplayFormat: format}
      await handleGradebookSettingsChange(newSettings)
    },
    [gradebookSettings, handleGradebookSettingsChange],
  )

  const handleUpdateStudentsPerPage = useCallback(
    async (studentsPerPage: number) => {
      const newSettings = {...gradebookSettings, studentsPerPage}

      handleGradebookSettingsChange(newSettings)
    },
    [gradebookSettings, handleGradebookSettingsChange],
  )

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
    if (isLoadingGradebook || isLoadingSettings) return renderLoader()
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
        onChangeNameDisplayFormat={handleNameDisplayFormatChange}
        data-testid="gradebook-body"
      />
    )
  }

  return (
    <QueryClientProvider client={queryClient}>
      <LMGBContext.Provider value={contextValues}>
        <Toolbar
          courseId={courseId}
          contextURL={contextURL}
          showDataDependentControls={error === null && !isLoadingSettings}
          gradebookSettings={gradebookSettings}
          setGradebookSettings={handleGradebookSettingsChange}
          isSavingSettings={isSavingSettings}
        />
        <FilterWrapper pagination={pagination} onPerPageChange={handleUpdateStudentsPerPage} />
        {renderBody()}
      </LMGBContext.Provider>
    </QueryClientProvider>
  )
}

export default LearningMastery
