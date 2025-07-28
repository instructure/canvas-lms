/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import LoadingIndicator from '@canvas/loading-indicator/react'
import type {Rubric, RubricAssociation, RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {Flex} from '@instructure/ui-flex'
import {Responsive} from '@instructure/ui-responsive'
import {fetchRubric, type SaveRubricResponse} from './queries/RubricFormQueries'
import type {RubricFormProps} from './types/RubricForm'
import {CriterionModal} from './components/CriterionModal/CriterionModal'
import {WarningModal} from './components/WarningModal'
import type {DropResult} from 'react-beautiful-dnd'
import {OutcomeCriterionModal} from './components/OutcomeCriterionModal'
import {RubricAssessmentTray} from '@canvas/rubrics/react/RubricAssessment'
import type {GroupOutcome} from '@canvas/global/env/EnvCommon'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'
import {
  calcPointsPossible,
  hasRubricChanged,
  defaultRubricForm,
  reorder,
  translateRubricData,
  translateRubricQueryResponse,
} from './utils'
import {useQuery} from '@tanstack/react-query'
import useOutcomeDialog from './hooks/useOutcomeDialog'
import {GeneratedCriteriaForm} from './components/AIGeneratedCriteria/GeneratedCriteriaForm'
import {GeneratedCriteriaHeader} from './components/AIGeneratedCriteria/GeneratedCriteriaHeader'
import {RubricFormFooter} from './components/RubricFormFooter'
import {useSaveRubricForm} from './hooks/useSaveRubricForm'
import {RubricCriteriaContainer} from './components/RubricCriteriaContainer'
import {RubricFormHeader} from './components/RubricFormHeader'
import {CriteriaBuilderHeader} from './components/CriteriaBuilderHeader'
import {RubricAssignmentSettings} from './components/RubricAssignmentSettings'
import {RubricFormSettings} from './components/RubricFormSettings'
import {CanvasProgress} from '@canvas/progress/ProgressHelpers'
import {EditConfirmModal} from '../RubricAssignment/components/EditConfirmModal'

const I18n = createI18nScope('rubrics-form')

type RubricFormValidationProps = {
  title?: {
    message?: string
  }
}

export type RubricFormComponentProp = {
  rubricId?: string
  accountId?: string
  assignmentId?: string
  courseId?: string
  canManageRubrics: boolean
  rootOutcomeGroup: GroupOutcome
  criterionUseRangeEnabled: boolean
  hideHeader?: boolean
  aiRubricsEnabled: boolean
  rubric?: Rubric
  rubricAssociation?: RubricAssociation
  showAdditionalOptions?: boolean
  onLoadRubric?: (rubricTitle: string) => void
  onSaveRubric: (savedRubricResponse: SaveRubricResponse) => void
  onCancel: () => void
}

export const RubricForm = ({
  rubricId,
  assignmentId,
  accountId,
  courseId,
  canManageRubrics,
  criterionUseRangeEnabled,
  rootOutcomeGroup,
  hideHeader = false,
  aiRubricsEnabled,
  rubric,
  rubricAssociation,
  showAdditionalOptions = false,
  onLoadRubric,
  onSaveRubric,
  onCancel,
}: RubricFormComponentProp) => {
  const [rubricForm, setRubricForm] = useState<RubricFormProps>({
    ...defaultRubricForm,
    accountId,
    courseId,
  })
  const [validationErrors, setValidationErrors] = useState<RubricFormValidationProps>({})
  const [selectedCriterion, setSelectedCriterion] = useState<RubricCriterion>()
  const [isCriterionModalOpen, setIsCriterionModalOpen] = useState(false)
  const [isEditConfirmModalOpen, setIsEditConfirmModalOpen] = useState(false)
  const [isOutcomeCriterionModalOpen, setIsOutcomeCriterionModalOpen] = useState(false)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [savedRubricResponse, setSavedRubricResponse] = useState<SaveRubricResponse>()
  const [showWarningModal, setShowWarningModal] = useState(false)
  const [showGenerateCriteriaForm, setShowGenerateCriteriaForm] = useState(
    aiRubricsEnabled && !!assignmentId && !rubric?.id,
  )
  const [showGenerateCriteriaHeader, setShowGenerateCriteriaHeader] = useState(false)
  const [generatedCriteriaProgress, setGeneratedCriteriaProgress] = useState<CanvasProgress>()
  const [generatedCriteriaIsPending, setGeneratedCriteriaIsPending] = useState(false)
  const hasAssignment = !!assignmentId && assignmentId !== ''
  const showAssignmentSettings = hasAssignment

  const criteriaRef = useRef(rubricForm.criteria)

  const header = rubricId || rubric?.id ? I18n.t('Edit Rubric') : I18n.t('Create New Rubric')
  const queryKey = ['fetch-rubric', rubricId ?? '']
  const formValid = !validationErrors.title?.message && rubricForm.criteria.length > 0
  const criteriaBeingGenerated =
    generatedCriteriaIsPending ||
    (generatedCriteriaProgress &&
      !['failed', 'completed'].includes(generatedCriteriaProgress.workflow_state))

  const {data, isLoading} = useQuery({
    queryKey,
    queryFn: fetchRubric,
    enabled: !!rubricId && canManageRubrics && !rubric,
  })

  const {savePending, saveSuccess, saveError, saveRubricMutation} = useSaveRubricForm({
    accountId,
    assignmentId,
    courseId,
    queryKey,
    rubricId,
    rubricForm,
    handleSaveSuccess: setSavedRubricResponse,
  })

  const setRubricFormField = useCallback(
    <K extends keyof RubricFormProps>(key: K, value: RubricFormProps[K]) => {
      setRubricForm(prevState => ({...prevState, [key]: value}))

      const validateField = (key: K, value: RubricFormProps[K]): void => {
        if (key === 'title') {
          const messageValidation =
            typeof value === 'string' && value.trim().length > 0 && value.length <= 255
          const message = messageValidation
            ? undefined
            : I18n.t('The Rubic Name must be between 1 and 255 characters.')
          setValidationErrors(prevState => ({
            ...prevState,
            [key]: {message},
          }))
        }
      }
      validateField(key, value)
    },
    [setRubricForm],
  )

  const {openOutcomeDialog} = useOutcomeDialog({
    criteriaRef,
    rootOutcomeGroup,
    setRubricFormField,
  })

  const openCriterionModal = (criterion?: RubricCriterion) => {
    setSelectedCriterion(criterion)
    if (criterion?.learningOutcomeId) {
      setIsOutcomeCriterionModalOpen(true)
    } else {
      setIsCriterionModalOpen(true)
    }
  }

  const duplicateCriterion = (criterion: RubricCriterion) => {
    const newCriterion: RubricCriterion = {
      ...criterion,
      id: Date.now().toString(),
      outcome: undefined,
      learningOutcomeId: undefined,
      description: stripHtmlTags(criterion.description) ?? '',
      longDescription: stripHtmlTags(criterion.longDescription) ?? '',
    }

    setSelectedCriterion(newCriterion)
    setIsCriterionModalOpen(true)
  }

  const deleteCriterion = (criterion: RubricCriterion) => {
    const criteria = rubricForm.criteria.filter(c => c.id !== criterion.id)
    setRubricFormField('pointsPossible', calcPointsPossible(criteria))
    setRubricFormField('criteria', criteria)
  }

  const handleSaveCriterion = (updatedCriteria: RubricCriterion) => {
    const criteria = [...criteriaRef.current]

    const criterionIndexToUpdate = criteria.findIndex(c => c.id === updatedCriteria.id)

    if (criterionIndexToUpdate < 0) {
      criteria.push(updatedCriteria)
    } else {
      criteria[criterionIndexToUpdate] = updatedCriteria
    }

    setRubricFormField('pointsPossible', calcPointsPossible(criteria))
    setRubricFormField('criteria', criteria)
    setIsCriterionModalOpen(false)
    setIsOutcomeCriterionModalOpen(false)
  }

  const handleSaveAsDraft = () => {
    setRubricFormField('workflowState', 'draft')
    saveRubricMutation()
  }

  const handleSave = () => {
    setRubricFormField('workflowState', 'active')
    saveRubricMutation()
  }

  const handleDragEnd = (result: DropResult) => {
    const {source, destination} = result
    if (!destination) {
      return
    }

    const reorderedItems = reorder({
      list: rubricForm.criteria,
      startIndex: source.index,
      endIndex: destination.index,
    })

    const newRubricFormProps = {
      ...rubricForm,
      criteria: reorderedItems,
    }

    setRubricForm(newRubricFormProps)
  }

  const handleCancelButton = () => {
    if (
      rubricForm.criteria.length === defaultRubricForm.criteria.length &&
      rubricForm.title === defaultRubricForm.title
    ) {
      onCancel()
    } else {
      setShowWarningModal(true)
    }
  }

  useEffect(() => {
    criteriaRef.current = rubricForm.criteria
  }, [rubricForm.criteria])

  useEffect(() => {
    if (!rubricId) {
      onLoadRubric?.(I18n.t('Create'))
      return
    }

    if (data) {
      const rubricFormData = translateRubricQueryResponse(data)
      setRubricForm({...rubricFormData, accountId, courseId})
      onLoadRubric?.(rubricFormData.title)
    }
  }, [accountId, courseId, data, rubricId, onLoadRubric])

  useEffect(() => {
    if (rubric && rubricAssociation) {
      const rubricFormData = translateRubricData(rubric, rubricAssociation)
      setRubricForm({...rubricFormData, accountId, courseId})
    }
  }, [accountId, courseId, rubric, rubricAssociation])

  useEffect(() => {
    if (saveSuccess && savedRubricResponse) {
      onSaveRubric(savedRubricResponse)
    }
  }, [saveSuccess, savedRubricResponse, onSaveRubric])

  if (isLoading && !!rubricId) {
    return <LoadingIndicator />
  }

  return (
    <View as="div" margin="0 0 medium 0" overflowY="hidden" overflowX="hidden" padding="large">
      <Flex as="div" direction="column" style={{minHeight: '100%'}}>
        <RubricFormHeader
          header={header}
          hideHeader={hideHeader}
          isUnassessed={rubricForm.unassessed}
          saveError={saveError}
        />
        <Flex.Item overflowX="hidden" overflowY="hidden" padding="0 xx-small">
          <Flex margin="large 0 0 0" alignItems="start">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <TextInput
                data-testid="rubric-form-title"
                renderLabel={I18n.t('Rubric Name')}
                onChange={e => setRubricFormField('title', e.target.value)}
                value={rubricForm.title}
                messages={[
                  validationErrors.title?.message
                    ? {text: validationErrors.title.message, type: 'error'}
                    : {text: <></>, type: 'hint'},
                ]}
              />
            </Flex.Item>
            {rubricForm.unassessed && (
              <RubricFormSettings
                showAdditionalOptions={showAdditionalOptions}
                rubricForm={rubricForm}
                setRubricFormField={setRubricFormField}
              />
            )}
          </Flex>

          {showAdditionalOptions && showAssignmentSettings && (
            <RubricAssignmentSettings
              hideOutcomeResults={rubricForm.hideOutcomeResults}
              hidePoints={rubricForm.hidePoints}
              useForGrading={rubricForm.useForGrading}
              hideScoreTotal={rubricForm.hideScoreTotal}
              setRubricFormField={setRubricFormField}
            />
          )}

          <CriteriaBuilderHeader
            hidePoints={rubricForm.hidePoints}
            hideScoreTotal={rubricForm.hideScoreTotal}
            rubricId={rubricForm.id}
            pointsPossible={rubricForm.pointsPossible}
          />

          {showGenerateCriteriaForm && (
            <GeneratedCriteriaForm
              courseId={rubricForm.courseId}
              assignmentId={assignmentId}
              criterionUseRangeEnabled={criterionUseRangeEnabled}
              criteriaBeingGenerated={!!criteriaBeingGenerated}
              criteriaRef={criteriaRef}
              handleInProgressUpdates={setGeneratedCriteriaIsPending}
              handleProgressUpdates={setGeneratedCriteriaProgress}
              setShowGenerateCriteriaForm={setShowGenerateCriteriaForm}
              setShowGenerateCriteriaHeader={setShowGenerateCriteriaHeader}
              setRubricFormField={setRubricFormField}
            />
          )}

          {showGenerateCriteriaHeader && (
            <GeneratedCriteriaHeader aiFeedbackLink={window.ENV.AI_FEEDBACK_LINK} />
          )}
        </Flex.Item>

        {criteriaBeingGenerated && (
          <Flex.Item shouldGrow={true}>
            <LoadingIndicator />
          </Flex.Item>
        )}

        <RubricCriteriaContainer
          rubricForm={rubricForm}
          handleDragEnd={handleDragEnd}
          deleteCriterion={deleteCriterion}
          duplicateCriterion={duplicateCriterion}
          openCriterionModal={openCriterionModal}
          openOutcomeDialog={openOutcomeDialog}
        />
      </Flex>

      <RubricFormFooter
        assignmentId={assignmentId}
        hasRubricAssociations={rubricForm.hasRubricAssociations}
        rubricId={rubricId ?? rubric?.id}
        savePending={savePending}
        handleCancelButton={handleCancelButton}
        handlePreviewRubric={() => setIsPreviewTrayOpen(true)}
        handleSaveAsDraft={handleSaveAsDraft}
        handleSave={() => {
          if (rubric && hasAssignment && hasRubricChanged(rubricForm, rubric)) {
            setIsEditConfirmModalOpen(true)
          } else {
            handleSave()
          }
        }}
        formValid={formValid}
      />

      <WarningModal
        isOpen={showWarningModal}
        onDismiss={() => setShowWarningModal(false)}
        onCancel={onCancel}
      />
      <Responsive
        match="media"
        query={{
          compact: {maxWidth: '50rem'},
          fullWidth: {minWidth: '50rem'},
          large: {minWidth: '66.5rem'},
        }}
      >
        {(_props, matches) => {
          const isFullWidth = matches?.includes('fullWidth') ?? false

          return (
            <CriterionModal
              criterion={selectedCriterion}
              criterionUseRangeEnabled={criterionUseRangeEnabled}
              hidePoints={rubricForm.hidePoints}
              freeFormCriterionComments={rubricForm.freeFormCriterionComments}
              isFullWidth={isFullWidth}
              isOpen={isCriterionModalOpen}
              unassessed={rubricForm.unassessed}
              onDismiss={() => setIsCriterionModalOpen(false)}
              onSave={(updatedCriteria: RubricCriterion) => handleSaveCriterion(updatedCriteria)}
            />
          )
        }}
      </Responsive>
      <OutcomeCriterionModal
        criterion={selectedCriterion}
        isOpen={isOutcomeCriterionModalOpen}
        onDismiss={() => setIsOutcomeCriterionModalOpen(false)}
      />
      <RubricAssessmentTray
        hidePoints={rubricForm.hidePoints}
        isOpen={isPreviewTrayOpen}
        isPreviewMode={false}
        rubric={rubricForm}
        rubricAssessmentData={[]}
        onDismiss={() => setIsPreviewTrayOpen(false)}
      />
      <EditConfirmModal
        isOpen={isEditConfirmModalOpen}
        onConfirm={() => {
          setIsEditConfirmModalOpen(false)
          handleSave()
        }}
        onDismiss={() => setIsEditConfirmModalOpen(false)}
      />
    </View>
  )
}
