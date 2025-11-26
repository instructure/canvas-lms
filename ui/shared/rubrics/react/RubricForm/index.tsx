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
import type {RubricFormProps, GenerateCriteriaFormProps} from './types/RubricForm'
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
import {
  GeneratedCriteriaForm,
  defaultGenerateCriteriaForm,
} from './components/AIGeneratedCriteria/GeneratedCriteriaForm'
import {GeneratedCriteriaHeader} from './components/AIGeneratedCriteria/GeneratedCriteriaHeader'
import {RubricFormFooter} from './components/RubricFormFooter'
import {useSaveRubricForm} from './hooks/useSaveRubricForm'
import {useRegenerateCriteria} from './hooks/useRegenerateCriteria'
import {RubricCriteriaContainer} from './components/RubricCriteriaContainer'
import {RubricFormHeader} from './components/RubricFormHeader'
import {CriteriaBuilderHeader} from './components/CriteriaBuilderHeader'
import {RubricAssignmentSettings} from './components/RubricAssignmentSettings'
import {RubricFormSettings} from './components/RubricFormSettings'
import {EditConfirmModal} from '../RubricAssignment/components/EditConfirmModal'
import {SaveRubricConfirmationModal} from './components/SaveRubricConfirmationModal'
import {AssignmentPointsDifferenceModal} from './components/AssignmentPointsDifferenceModal'
import {useGenerateCriteria} from './hooks/useGenerateCriteria'

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
  assignmentPointsPossible?: number
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
  onSaveRubric: (savedRubricResponse: SaveRubricResponse, updatePointsPossible?: boolean) => void
  onCancel: () => void
}

export const RubricForm = ({
  rubricId,
  assignmentId,
  assignmentPointsPossible,
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
  const defaultAssociationType = assignmentId ? 'Assignment' : accountId ? 'Account' : 'Course'
  const [rubricForm, setRubricForm] = useState<RubricFormProps>({
    ...defaultRubricForm,
    accountId,
    courseId,
    associationType: defaultAssociationType,
  })
  const [validationErrors, setValidationErrors] = useState<RubricFormValidationProps>({})
  const [selectedCriterion, setSelectedCriterion] = useState<RubricCriterion>()
  const [isCriterionModalOpen, setIsCriterionModalOpen] = useState(false)
  const [isEditConfirmModalOpen, setIsEditConfirmModalOpen] = useState(false)
  const [isOutcomeCriterionModalOpen, setIsOutcomeCriterionModalOpen] = useState(false)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [savedRubricResponse, setSavedRubricResponse] = useState<SaveRubricResponse>()
  const [showWarningModal, setShowWarningModal] = useState(false)
  const [generateCriteriaFormOptions, setGenerateCriteriaFormOptions] =
    useState<GenerateCriteriaFormProps>(defaultGenerateCriteriaForm)
  const [isSaveConfirmModalOpen, setIsSaveConfirmModalOpen] = useState(false)
  const [isAssignmentPointsDifferenceModalOpen, setIsAssignmentPointsDifferenceModalOpen] =
    useState(false)
  const hasAssignment = !!assignmentId && assignmentId !== ''
  const isNewRubric = !rubricId && !rubric?.id

  const criteriaRef = useRef(rubricForm.criteria)

  const validateField = useCallback(
    <K extends keyof RubricFormProps>(key: K, value: RubricFormProps[K]): boolean => {
      if (key === 'title') {
        const titleString = value?.toString() ?? ''
        const trimmedTitle = titleString.trim()
        const isTitleEmpty = trimmedTitle.length === 0
        const isTitleTooLong = trimmedTitle.length > 255
        const isTitleValid = !isTitleEmpty && !isTitleTooLong
        let message = undefined

        if (isTitleEmpty) {
          message = I18n.t('Rubric requires a name')
        } else if (isTitleTooLong) {
          message = I18n.t('The Rubric Name must be between 1 and 255 characters.')
        }

        setValidationErrors(prevState => ({
          ...prevState,
          [key]: {message},
        }))
        if (!isTitleValid) {
          return false
        }
      }
      return true
    },
    [],
  )

  const setRubricFormField = useCallback(
    <K extends keyof RubricFormProps>(key: K, value: RubricFormProps[K]) => {
      setRubricForm(prevState => ({...prevState, [key]: value}))

      validateField(key, value)
    },
    [validateField],
  )

  const isAIRubricsAvailable = aiRubricsEnabled && isNewRubric && hasAssignment

  const {generateCriteriaIsPending, generateCriteriaIsSuccess, generateCriteriaMutation} =
    useGenerateCriteria({
      assignmentId,
      criteriaRef,
      courseId: rubricForm.courseId,
      generateOptions: generateCriteriaFormOptions,
      setRubricFormField,
    })

  const showGenerateCriteriaForm = isAIRubricsAvailable && !generateCriteriaIsSuccess
  const showGeneratedCriteriaHeader = isAIRubricsAvailable && generateCriteriaIsSuccess

  const {regenerateAllCriteria, regenerateSingleCriterion, regenerateCriteriaIsPending} =
    useRegenerateCriteria({
      assignmentId,
      courseId: rubricForm.courseId,
      criteriaRef,
      generateOptions: generateCriteriaFormOptions,
      setRubricFormField,
    })

  const header = isNewRubric ? I18n.t('Create New Rubric') : I18n.t('Edit Rubric')
  const queryKey = ['fetch-rubric', rubricId ?? '']
  const formValid = !validationErrors.title?.message && rubricForm.criteria.length > 0
  const criteriaBeingGenerated = generateCriteriaIsPending || regenerateCriteriaIsPending

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
    const clonedCriterion = structuredClone(criterion)

    const newCriterion: RubricCriterion = {
      ...clonedCriterion,
      id: Date.now().toString(),
      outcome: undefined,
      learningOutcomeId: undefined,
      description: stripHtmlTags(clonedCriterion.description) ?? '',
      longDescription: stripHtmlTags(clonedCriterion.longDescription) ?? '',
      points: Math.max(...clonedCriterion.ratings.map(r => r.points), 0),
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
    if (!validateField('title', rubricForm.title)) {
      return
    }

    setRubricFormField('workflowState', 'draft')
    saveRubricMutation()
  }

  const handleSave = (skipUpdatingPointsPossible?: boolean) => {
    if (!validateField('title', rubricForm.title)) {
      return
    }

    if (skipUpdatingPointsPossible !== undefined) {
      setRubricFormField('skipUpdatingPointsPossible', skipUpdatingPointsPossible)
    }
    setRubricFormField('workflowState', 'active')
    saveRubricMutation()
  }

  const isAssignmentPointsDifferent =
    !!assignmentPointsPossible &&
    !!rubricForm.pointsPossible &&
    !rubricForm.hidePoints &&
    rubricForm.useForGrading &&
    rubricForm.pointsPossible !== assignmentPointsPossible

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
      const updatePointsPossible = rubricForm.skipUpdatingPointsPossible === false
      onSaveRubric(savedRubricResponse, updatePointsPossible)
    }
  }, [saveSuccess, savedRubricResponse, onSaveRubric])

  if (isLoading && !!rubricId) {
    return <LoadingIndicator />
  }

  return (
    <View as="div" margin="0 0 medium 0" overflowY="hidden" overflowX="hidden" padding="large">
      <Flex as="div" direction="column" style={{minHeight: '100%'}}>
        <RubricFormHeader
          canUpdateRubric={isNewRubric || rubricForm.canUpdateRubric}
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
                onBlur={e => validateField('title', e.target.value)}
                onChange={e => setRubricFormField('title', e.target.value)}
                value={rubricForm.title}
                isRequired
                messages={[
                  validationErrors.title?.message
                    ? {text: validationErrors.title.message, type: 'error'}
                    : {text: <></>, type: 'hint'},
                ]}
              />
            </Flex.Item>
            <RubricFormSettings
              showAdditionalOptions={showAdditionalOptions}
              rubricForm={rubricForm}
              setRubricFormField={setRubricFormField}
            />
          </Flex>

          {showAdditionalOptions && hasAssignment && (
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
            isAIRubricsAvailable={isAIRubricsAvailable}
            rubricId={rubricForm.id}
            pointsPossible={rubricForm.pointsPossible}
          />

          {showGenerateCriteriaForm && (
            <GeneratedCriteriaForm
              criterionUseRangeEnabled={criterionUseRangeEnabled}
              criteriaBeingGenerated={!!criteriaBeingGenerated}
              generateCriteriaMutation={generateCriteriaMutation}
              onFormOptionsChange={setGenerateCriteriaFormOptions}
            />
          )}

          {showGeneratedCriteriaHeader && (
            <GeneratedCriteriaHeader
              aiFeedbackLink={window.ENV.AI_FEEDBACK_LINK}
              onRegenerateAll={regenerateAllCriteria}
              isGenerating={criteriaBeingGenerated}
            />
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
          onRegenerateCriterion={regenerateSingleCriterion}
          isGenerating={criteriaBeingGenerated}
          showCriteriaRegeneration={isAIRubricsAvailable}
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
          if (rubric && hasAssignment && isAssignmentPointsDifferent) {
            setIsAssignmentPointsDifferenceModalOpen(true)
          } else if (rubric && hasAssignment && hasRubricChanged(rubricForm, rubric)) {
            setIsEditConfirmModalOpen(true)
          } else if (rubricForm.unassessed) {
            handleSave()
          } else {
            setIsSaveConfirmModalOpen(true)
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
        currentUserId={ENV.current_user_id ?? ''}
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
      <SaveRubricConfirmationModal
        isOpen={isSaveConfirmModalOpen}
        onConfirm={() => {
          setIsSaveConfirmModalOpen(false)
          handleSave()
        }}
        onDismiss={() => setIsSaveConfirmModalOpen(false)}
      />
      <AssignmentPointsDifferenceModal
        assignmentPoints={assignmentPointsPossible ?? 0}
        rubricPoints={rubricForm.pointsPossible}
        isOpen={isAssignmentPointsDifferenceModalOpen}
        onChange={() => {
          handleSave(false)
          setIsAssignmentPointsDifferenceModalOpen(false)
        }}
        onDismiss={() => {
          setIsAssignmentPointsDifferenceModalOpen(false)
        }}
        onLeaveDifferent={() => {
          handleSave(true)
          setIsAssignmentPointsDifferenceModalOpen(false)
        }}
      />
    </View>
  )
}
