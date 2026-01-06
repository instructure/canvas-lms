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

import React, {useState, useCallback, useEffect} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {QueryClient, QueryClientProvider} from '@tanstack/react-query'
import {useScope as createI18nScope} from '@canvas/i18n'
import LMGBContext, {
  getLMGBContext,
  LMGBContextType,
} from '@canvas/outcomes/react/contexts/LMGBContext'
import GenericErrorPage from '@canvas/generic-error-page/react'
import errorShipUrl from '@canvas/images/ErrorShip.svg'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {Gradebook} from './components/Gradebook'
import {FilterWrapper} from './components/filters/FilterWrapper'
import {SearchWrapper} from './components/filters/SearchWrapper'
import {Toolbar} from './components/toolbar/Toolbar'
import {GradebookSettings, NameDisplayFormat} from './utils/constants'
import useRollups from './hooks/useRollups'
import {useGradebookSettings} from './hooks/useGradebookSettings'
import {saveLearningMasteryGradebookSettings, saveOutcomeOrder} from './apiClient'
import {Outcome} from './types/rollup'
import {useContributingScores} from './hooks/useContributingScores'
import {StudentAssignmentDetailTray} from './components/trays/StudentAssignmentDetailTray'
import {useStudentAssignmentTray} from './hooks/useStudentAssignmentTray'

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

interface LearningMasteryContentProps {
  courseId: string
  contextURL: string
  accountLevelMasteryScalesFF: boolean
}

const LearningMasteryContent: React.FC<LearningMasteryContentProps> = ({
  courseId,
  contextURL,
  accountLevelMasteryScalesFF,
}) => {
  const {
    settings: gradebookSettings,
    isLoading: isLoadingSettings,
    updateSettings,
  } = useGradebookSettings(courseId)

  const [isSavingSettings, setIsSavingSettings] = useState(false)
  const [selectedUserIds, setSelectedUserIds] = useState<number[]>([])

  const {
    isLoading: isLoadingGradebook,
    error,
    students,
    outcomes: initialOutcomes,
    rollups,
    pagination,
    setCurrentPage,
    sorting,
    filter,
  } = useRollups({
    courseId,
    accountMasteryScalesEnabled: accountLevelMasteryScalesFF ?? false,
    enabled: !isLoadingSettings,
    settings: gradebookSettings,
    selectedUserIds,
  })

  const studentAssignmentDetailTray = useStudentAssignmentTray(students)

  const [localOutcomes, setLocalOutcomes] = useState<Outcome[] | null>(null)
  const outcomes = localOutcomes ?? initialOutcomes

  useEffect(() => {
    setLocalOutcomes(null)
  }, [initialOutcomes])

  const {
    isLoading: isLoadingContributingScores,
    error: contributingScoresError,
    contributingScores,
  } = useContributingScores({
    enabled: !isLoadingSettings && !isLoadingGradebook,
    courseId,
    studentIds: students.map(student => student.id),
    outcomeIds: outcomes.map(outcome => outcome.id),
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

  const handleOutcomesReorder = useCallback(
    async (reorderedOutcomes: Outcome[]) => {
      const originalOutcomes = outcomes
      setLocalOutcomes(reorderedOutcomes)

      try {
        await saveOutcomeOrder(courseId, reorderedOutcomes)
      } catch {
        setLocalOutcomes(originalOutcomes === initialOutcomes ? null : originalOutcomes)
        showFlashAlert({
          type: 'error',
          message: I18n.t('Failed to save outcome order'),
        })
      }
    },
    [courseId, outcomes, initialOutcomes],
  )

  const renderBody = () => {
    if (error !== null || contributingScoresError !== null)
      return (
        <GenericErrorPage
          errorMessage={error || contributingScoresError}
          imageUrl={errorShipUrl}
          errorSubject={I18n.t('Error loading rollups')}
          errorCategory={I18n.t('Learning Mastery Gradebook Error Page')}
        />
      )

    if (isLoadingGradebook || isLoadingSettings || isLoadingContributingScores)
      return renderLoader()

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
        onOutcomesReorder={handleOutcomesReorder}
        contributingScores={contributingScores}
        onOpenStudentAssignmentTray={studentAssignmentDetailTray.open}
        data-testid="gradebook-body"
      />
    )
  }

  return (
    <>
      <Toolbar
        courseId={courseId}
        contextURL={contextURL}
        showDataDependentControls={error === null && !isLoadingSettings}
        gradebookSettings={gradebookSettings}
        setGradebookSettings={handleGradebookSettingsChange}
        isSavingSettings={isSavingSettings}
      />
      {pagination && (
        <SearchWrapper
          courseId={courseId}
          selectedUserIds={selectedUserIds}
          onSelectedUserIdsChange={setSelectedUserIds}
          selectedOutcomes={filter.selectedOutcomeIds}
          onSelectOutcomes={filter.setSelectedOutcomeIds}
        />
      )}
      <FilterWrapper pagination={pagination} onPerPageChange={handleUpdateStudentsPerPage} />
      {renderBody()}
      {studentAssignmentDetailTray.isOpen &&
        studentAssignmentDetailTray.state &&
        studentAssignmentDetailTray.assignment && (
          <StudentAssignmentDetailTray
            open={true}
            onDismiss={studentAssignmentDetailTray.close}
            outcome={studentAssignmentDetailTray.state.outcome}
            courseId={courseId}
            student={studentAssignmentDetailTray.state.student}
            assignment={studentAssignmentDetailTray.assignment}
            assignmentNavigator={{
              ...studentAssignmentDetailTray.assignmentNavigator,
              onNext: studentAssignmentDetailTray.handlers.navigateNextAssignment,
              onPrevious: studentAssignmentDetailTray.handlers.navigatePreviousAssignment,
            }}
            studentNavigator={{
              ...studentAssignmentDetailTray.studentNavigator,
              onNext: studentAssignmentDetailTray.handlers.navigateNextStudent,
              onPrevious: studentAssignmentDetailTray.handlers.navigatePreviousStudent,
            }}
            rollups={rollups}
            outcomes={outcomes}
          />
        )}
    </>
  )
}

const LearningMastery: React.FC<LearningMasteryProps> = ({courseId}) => {
  const contextValues = getLMGBContext() as LMGBContextType
  const {contextURL, accountLevelMasteryScalesFF} = contextValues.env

  return (
    <QueryClientProvider client={queryClient}>
      <LMGBContext.Provider value={contextValues}>
        <LearningMasteryContent
          courseId={courseId}
          contextURL={contextURL ?? ''}
          accountLevelMasteryScalesFF={accountLevelMasteryScalesFF ?? false}
        />
      </LMGBContext.Provider>
    </QueryClientProvider>
  )
}

export default LearningMastery
