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
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import LoadingIndicator from '@canvas/loading-indicator/react'
import {useQuery, useMutation, queryClient} from '@canvas/query'
import type {Rubric, RubricAssociation, RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {colors} from '@instructure/canvas-theme'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {IconEyeLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {RubricCriteriaRow} from './RubricCriteriaRow'
import {NewCriteriaRow} from './NewCriteriaRow'
import {fetchRubric, saveRubric, type SaveRubricResponse} from './queries/RubricFormQueries'
import type {RubricFormProps} from './types/RubricForm'
import {CriterionModal} from './CriterionModal'
import {DragDropContext as DragAndDrop, Droppable} from 'react-beautiful-dnd'
import type {DropResult} from 'react-beautiful-dnd'
import {OutcomeCriterionModal} from './OutcomeCriterionModal'
import {RubricAssessmentTray} from '@canvas/rubrics/react/RubricAssessment'
import FindDialog from '@canvas/outcomes/backbone/views/FindDialog'
import OutcomeGroup from '@canvas/outcomes/backbone/models/OutcomeGroup'
import type {GroupOutcome} from '@canvas/global/env/EnvCommon'
import {stripHtmlTags} from '@canvas/outcomes/stripHtmlTags'
import {reorder, stripPTags, translateRubricData, translateRubricQueryResponse} from './utils'
import {Checkbox} from '@instructure/ui-checkbox'

const I18n = useI18nScope('rubrics-form')

const {Option: SimpleSelectOption} = SimpleSelect

export const defaultRubricForm: RubricFormProps = {
  title: '',
  hasRubricAssociations: false,
  hidePoints: false,
  criteria: [],
  pointsPossible: 0,
  buttonDisplay: 'numeric',
  ratingOrder: 'descending',
  unassessed: true,
  workflowState: 'active',
  freeFormCriterionComments: false,
  hideOutcomeResults: false,
  hideScoreTotal: false,
  useForGrading: false,
}

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
  const [isOutcomeCriterionModalOpen, setIsOutcomeCriterionModalOpen] = useState(false)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [outcomeDialogOpen, setOutcomeDialogOpen] = useState(false)
  const [savedRubricResponse, setSavedRubricResponse] = useState<SaveRubricResponse>()
  const criteriaRef = useRef(rubricForm.criteria)

  const header = rubricId ? I18n.t('Edit Rubric') : I18n.t('Create New Rubric')
  const queryKey = ['fetch-rubric', rubricId ?? '']

  const {data, isLoading} = useQuery({
    queryKey,
    queryFn: fetchRubric,
    enabled: !!rubricId && canManageRubrics && !rubric,
  })

  const {
    isLoading: saveLoading,
    isSuccess: saveSuccess,
    isError: saveError,
    mutate,
  } = useMutation({
    mutationFn: async () => saveRubric(rubricForm, assignmentId),
    mutationKey: ['save-rubric'],
    onSuccess: async successResponse => {
      showFlashSuccess(I18n.t('Rubric saved successfully'))()
      setSavedRubricResponse(successResponse as SaveRubricResponse)
      const rubricsForContextQueryKey = accountId
        ? `accountRubrics-${accountId}`
        : `courseRubrics-${courseId}`
      await queryClient.invalidateQueries(queryKey, {}, {cancelRefetch: true})
      await queryClient.invalidateQueries([rubricsForContextQueryKey], undefined, {
        cancelRefetch: true,
      })
      await queryClient.invalidateQueries([`rubric-preview-${rubricId}`], {}, {cancelRefetch: true})
    },
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
    [setRubricForm]
  )

  const formValid = () => {
    return !validationErrors.title?.message && rubricForm.criteria.length > 0
  }

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

  const calcPointsPossible = (criteria: RubricCriterion[]): number =>
    criteria.reduce((acc, c) => acc + (c.ignoreForScoring ? 0 : c.points), 0)

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
    mutate()
  }

  const handleSave = () => {
    setRubricFormField('workflowState', 'active')
    mutate()
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

  const handleAddOutcome = () => {
    setOutcomeDialogOpen(true)
  }

  useEffect(() => {
    if (outcomeDialogOpen) {
      const dialog = new FindDialog({
        title: I18n.t('Find Outcome'),
        selectedGroup: new OutcomeGroup(rootOutcomeGroup),
        useForScoring: true,
        shouldImport: false,
        disableGroupImport: true,
        rootOutcomeGroup: new OutcomeGroup(rootOutcomeGroup),
        url: '/outcomes/find_dialog',
      })
      dialog?.show()
      ;(dialog as any).on('import', (outcomeData: any) => {
        const newOutcomeCriteria = {
          id: Date.now().toString(),
          points: outcomeData.attributes.points_possible,
          description: outcomeData.outcomeLink.outcome.title,
          longDescription: stripPTags(outcomeData.attributes.description),
          outcome: {
            displayName: outcomeData.attributes.display_name,
            title: outcomeData.outcomeLink.outcome.title,
          },
          ignoreForScoring: !outcomeData.useForScoring,
          masteryPoints: outcomeData.attributes.mastery_points,
          criterionUseRange: false,
          ratings: outcomeData.attributes.ratings,
          learningOutcomeId: outcomeData.outcomeLink.outcome.id,
        }
        const criteria = [...criteriaRef.current]
        // Check if the outcome has already been added to this rubric
        const hasDuplicateLearningOutcomeId = criteria.some(
          criterion => criterion.learningOutcomeId === newOutcomeCriteria.learningOutcomeId
        )

        if (hasDuplicateLearningOutcomeId) {
          showFlashError(
            I18n.t('This Outcome has not been added as it already exists in this rubric.')
          )()

          return
        }
        criteria.push(newOutcomeCriteria)

        setRubricFormField('pointsPossible', calcPointsPossible(criteria))
        setRubricFormField('criteria', criteria)
        dialog.cleanup()
      })
      setOutcomeDialogOpen(false)
    }
  }, [outcomeDialogOpen, rootOutcomeGroup, setRubricFormField])

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
        <Flex.Item>
          {saveError && (
            <Alert
              variant="error"
              liveRegionPoliteness="polite"
              isLiveRegionAtomic={true}
              liveRegion={getLiveRegion}
              timeout={3000}
            >
              <Text weight="bold">{I18n.t('There was an error saving the rubric.')}</Text>
            </Alert>
          )}
        </Flex.Item>

        {!hideHeader && (
          <Flex.Item>
            <Heading level="h1" as="h1" themeOverride={{h1FontWeight: 700}}>
              {header}
            </Heading>
          </Flex.Item>
        )}

        {!rubricForm.unassessed && (
          <Flex.Item data-testid="rubric-limited-edit-mode-alert">
            <Alert
              variant="info"
              margin="medium 0 0 0"
              data-testid="rubric-limited-edit-mode-alert"
            >
              {I18n.t(
                'Editing is limited for this rubric as it has already been used for grading.'
              )}
            </Alert>
          </Flex.Item>
        )}

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
              <>
                {showAdditionalOptions && (
                  <Flex.Item margin="0 0 0 small">
                    <GradingTypeSelect
                      onChange={isFreeFormComments => {
                        setRubricFormField('freeFormCriterionComments', isFreeFormComments)
                      }}
                      freeFormCriterionComments={rubricForm.freeFormCriterionComments}
                    />
                  </Flex.Item>
                )}
                <Flex.Item margin="0 0 0 small">
                  <RubricRatingOrderSelect
                    ratingOrder={rubricForm.ratingOrder}
                    onChangeOrder={ratingOrder => setRubricFormField('ratingOrder', ratingOrder)}
                  />
                </Flex.Item>
                {showAdditionalOptions && (
                  <Flex.Item margin="0 0 0 small">
                    <ScoringTypeSelect
                      hidePoints={rubricForm.hidePoints}
                      onChange={() => {
                        setRubricFormField('hidePoints', !rubricForm.hidePoints)
                        setRubricFormField('hideScoreTotal', false)
                        setRubricFormField('useForGrading', false)
                      }}
                    />
                  </Flex.Item>
                )}
              </>
            )}
          </Flex>

          {showAdditionalOptions && (
            <Flex margin="medium 0 0" gap="medium">
              <Flex.Item>
                <Checkbox
                  label={"Don't post to Learning Mastery Gradebook"}
                  checked={rubricForm.hideOutcomeResults}
                  onChange={e => setRubricFormField('hideOutcomeResults', e.target.checked)}
                  data-testid="hide-outcome-results-checkbox"
                />
              </Flex.Item>
              {!rubricForm.hidePoints && (
                <>
                  <Flex.Item>
                    <Checkbox
                      label="Use this rubric for assignment grading"
                      checked={rubricForm.useForGrading}
                      onChange={e => {
                        setRubricFormField('useForGrading', e.target.checked)
                        setRubricFormField('hideScoreTotal', false)
                      }}
                      data-testid="use-for-grading-checkbox"
                    />
                  </Flex.Item>

                  {!rubricForm.useForGrading && (
                    <Flex.Item>
                      <Checkbox
                        label="Hide rubric score total from students"
                        checked={rubricForm.hideScoreTotal}
                        onChange={e => setRubricFormField('hideScoreTotal', e.target.checked)}
                        data-testid="hide-score-total-checkbox"
                      />
                    </Flex.Item>
                  )}
                </>
              )}
            </Flex>
          )}

          <View as="div" margin="large 0 large 0">
            <Flex>
              <Flex.Item shouldGrow={true}>
                <Heading
                  level="h2"
                  as="h2"
                  themeOverride={{h2FontWeight: 700, h2FontSize: '22px', lineHeight: '1.75rem'}}
                >
                  {I18n.t('Criteria Builder')}
                </Heading>
              </Flex.Item>
              {!rubricForm.hidePoints && !rubricForm.hideScoreTotal && (
                <Flex.Item>
                  <Heading
                    level="h2"
                    as="h2"
                    data-testid={`rubric-points-possible-${rubricForm.id}`}
                    themeOverride={{h2FontWeight: 700, h2FontSize: '22px', lineHeight: '1.75rem'}}
                  >
                    {rubricForm.pointsPossible} {I18n.t('Points Possible')}
                  </Heading>
                </Flex.Item>
              )}
            </Flex>
          </View>
        </Flex.Item>

        <Flex.Item shouldGrow={true} shouldShrink={true} as="main" padding="xx-small">
          <View as="div" margin="0 0 small 0">
            <DragAndDrop onDragEnd={handleDragEnd}>
              <Droppable droppableId="droppable-id">
                {provided => {
                  return (
                    <div ref={provided.innerRef} {...provided.droppableProps}>
                      {rubricForm.criteria.map((criterion, index) => {
                        return (
                          <RubricCriteriaRow
                            key={criterion.id}
                            criterion={criterion}
                            freeFormCriterionComments={rubricForm.freeFormCriterionComments}
                            hidePoints={rubricForm.hidePoints}
                            rowIndex={index + 1}
                            unassessed={rubricForm.unassessed}
                            onDeleteCriterion={() => deleteCriterion(criterion)}
                            onDuplicateCriterion={() => duplicateCriterion(criterion)}
                            onEditCriterion={() => openCriterionModal(criterion)}
                          />
                        )
                      })}
                      {provided.placeholder}
                    </div>
                  )
                }}
              </Droppable>
            </DragAndDrop>
            {rubricForm.unassessed && (
              <NewCriteriaRow
                rowIndex={rubricForm.criteria.length + 1}
                onEditCriterion={() => openCriterionModal()}
                onAddOutcome={handleAddOutcome}
              />
            )}
          </View>
        </Flex.Item>
      </Flex>

      <div id="enhanced-rubric-builder-footer" style={{backgroundColor: colors.white}}>
        <View
          as="div"
          margin="small large"
          themeOverride={{marginLarge: '48px', marginSmall: '12px'}}
        >
          <Flex justifyItems="end">
            <Flex.Item margin="0 medium 0 0">
              <Button onClick={onCancel} data-testid="cancel-rubric-save-button">
                {I18n.t('Cancel')}
              </Button>

              {!rubricForm.hasRubricAssociations && !assignmentId && (
                <Button
                  margin="0 0 0 small"
                  disabled={saveLoading || !formValid()}
                  onClick={handleSaveAsDraft}
                  data-testid="save-as-draft-button"
                >
                  {I18n.t('Save as Draft')}
                </Button>
              )}

              <Button
                margin="0 0 0 small"
                color="primary"
                onClick={handleSave}
                disabled={saveLoading || !formValid()}
                data-testid="save-rubric-button"
              >
                {I18n.t('Save Rubric')}
              </Button>
            </Flex.Item>
            <Flex.Item>
              <View
                as="div"
                padding="0 0 0 medium"
                borderWidth="none none none medium"
                height="2.375rem"
              >
                <Link
                  as="button"
                  data-testid="preview-rubric-button"
                  isWithinText={false}
                  margin="x-small 0 0 0"
                  onClick={() => setIsPreviewTrayOpen(true)}
                >
                  <IconEyeLine /> {I18n.t('Preview Rubric')}
                </Link>
              </View>
            </Flex.Item>
          </Flex>
        </View>
      </div>

      <CriterionModal
        criterion={selectedCriterion}
        criterionUseRangeEnabled={criterionUseRangeEnabled}
        hidePoints={rubricForm.hidePoints || rubricForm.freeFormCriterionComments}
        isOpen={isCriterionModalOpen}
        unassessed={rubricForm.unassessed}
        onDismiss={() => setIsCriterionModalOpen(false)}
        onSave={(updatedCriteria: RubricCriterion) => handleSaveCriterion(updatedCriteria)}
      />
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
    </View>
  )
}

type RubricRatingOrderSelectProps = {
  ratingOrder: string
  onChangeOrder: (ratingOrder: string) => void
}

const RubricRatingOrderSelect = ({ratingOrder, onChangeOrder}: RubricRatingOrderSelectProps) => {
  const onChange = (value: string) => {
    onChangeOrder(value)
  }

  return (
    <SimpleSelect
      renderLabel={I18n.t('Rating Order')}
      width="10.563rem"
      value={ratingOrder}
      onChange={(e, {value}) => onChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-order-select"
    >
      <SimpleSelectOption
        id="highToLowOption"
        value="descending"
        data-testid="high_low_rating_order"
      >
        {I18n.t('High < Low')}
      </SimpleSelectOption>
      <SimpleSelectOption
        id="lowToHighOption"
        value="ascending"
        data-testid="low_high_rating_order"
      >
        {I18n.t('Low < High')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}

type GradingTypeSelectProps = {
  freeFormCriterionComments: boolean
  onChange: (isFreeFormComments: boolean) => void
}

const GradingTypeSelect = ({freeFormCriterionComments, onChange}: GradingTypeSelectProps) => {
  const handleChange = (value: string) => {
    onChange(value === 'freeForm')
  }

  const gradingType = freeFormCriterionComments ? 'freeForm' : 'scale'

  return (
    <SimpleSelect
      renderLabel={I18n.t('Type')}
      width="10.563rem"
      value={gradingType}
      onChange={(e, {value}) => handleChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-type-select"
    >
      <SimpleSelectOption id="scaleOption" value="scale" data-testid="rating_type_scale">
        {I18n.t('Scale')}
      </SimpleSelectOption>
      <SimpleSelectOption id="freeFormOption" value="freeForm" data-testid="rating_type_free_form">
        {I18n.t('Written Feedback')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}

type ScoreTypeSelectProps = {
  hidePoints: boolean
  onChange: (shouldHidePoints: boolean) => void
}

const ScoringTypeSelect = ({hidePoints, onChange}: ScoreTypeSelectProps) => {
  const handleChange = (value: string) => {
    onChange(value === 'unscored')
  }

  const scoreType = hidePoints ? 'unscored' : 'scored'

  return (
    <SimpleSelect
      renderLabel={I18n.t('Scoring')}
      width="10.563rem"
      value={scoreType}
      onChange={(e, {value}) => handleChange(value !== undefined ? value.toString() : '')}
      data-testid="rubric-rating-scoring-type-select"
    >
      <SimpleSelectOption id="scoredOption" value="scored" data-testid="scoring_type_scored">
        {I18n.t('Scored')}
      </SimpleSelectOption>
      <SimpleSelectOption id="unscoredOption" value="unscored" data-testid="scoring_type_unscored">
        {I18n.t('Unscored')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
