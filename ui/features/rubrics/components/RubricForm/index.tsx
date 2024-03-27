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

import React, {useEffect, useRef, useState} from 'react'
import {useNavigate, useParams} from 'react-router-dom'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import LoadingIndicator from '@canvas/loading-indicator/react'
import {useQuery, useMutation, queryClient} from '@canvas/query'
import type {RubricAssessmentData, RubricCriterion} from '@canvas/rubrics/react/types/rubric'
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
import {fetchRubric, saveRubric, type RubricQueryResponse} from '../../queries/RubricFormQueries'
import type {RubricFormProps} from '../../types/RubricForm'
import {CriterionModal} from './CriterionModal'
import {RubricAssessmentTray} from '@canvas/rubrics/react/RubricAssessment'

const I18n = useI18nScope('rubrics-form')

const {Option: SimpleSelectOption} = SimpleSelect

const defaultRubricForm: RubricFormProps = {
  title: '',
  hasRubricAssociations: false,
  hidePoints: false,
  criteria: [],
  pointsPossible: 0,
  buttonDisplay: 'numeric',
  ratingOrder: 'descending',
  unassessed: true,
  workflowState: 'active',
}

const translateRubricData = (fields: RubricQueryResponse): RubricFormProps => {
  return {
    id: fields.id,
    title: fields.title ?? '',
    hasRubricAssociations: fields.hasRubricAssociations ?? false,
    hidePoints: fields.hidePoints ?? false,
    criteria: fields.criteria ?? [],
    pointsPossible: fields.pointsPossible ?? 0,
    buttonDisplay: fields.buttonDisplay ?? 'numeric',
    ratingOrder: fields.ratingOrder ?? 'descending',
    unassessed: fields.unassessed ?? true,
    workflowState: fields.workflowState ?? 'active',
  }
}

export const RubricForm = () => {
  const {rubricId, accountId, courseId} = useParams()
  const navigate = useNavigate()
  const navigateUrl = accountId ? `/accounts/${accountId}/rubrics` : `/courses/${courseId}/rubrics`
  const [rubricForm, setRubricForm] = useState<RubricFormProps>({
    ...defaultRubricForm,
    accountId,
    courseId,
  })

  const [selectedCriterion, setSelectedCriterion] = useState<RubricCriterion>()
  const [isCriterionModalOpen, setIsCriterionModalOpen] = useState(false)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)

  const header = rubricId ? I18n.t('Edit Rubric') : I18n.t('Create New Rubric')

  const {data, isLoading} = useQuery({
    queryKey: [`fetch-rubric-${rubricId}`],
    queryFn: async () => fetchRubric(rubricId),
    enabled: !!rubricId,
  })

  const {
    isLoading: saveLoading,
    isSuccess: saveSuccess,
    isError: saveError,
    mutate,
  } = useMutation({
    mutationFn: async () => saveRubric(rubricForm),
    mutationKey: ['save-rubric'],
    onSuccess: async () => {
      showFlashSuccess(I18n.t('Rubric saved successfully'))()
      const queryKey = accountId ? `accountRubrics-${accountId}` : `courseRubrics-${courseId}`
      await queryClient.invalidateQueries([`fetch-rubric-${rubricId}`], {}, {cancelRefetch: true})
      await queryClient.invalidateQueries([queryKey], undefined, {cancelRefetch: true})
    },
  })

  const setRubricFormField = <K extends keyof RubricFormProps>(
    key: K,
    value: RubricFormProps[K]
  ) => {
    setRubricForm(prevState => ({...prevState, [key]: value}))
  }

  const formValid = () => {
    // Add more form validation here
    return rubricForm.title.trim().length > 0
  }

  const openCriterionModal = (criterion?: RubricCriterion) => {
    setSelectedCriterion(criterion)
    setIsCriterionModalOpen(true)
  }

  const duplicateCriterion = (criterion: RubricCriterion) => {
    const newCriterion = {...criterion, id: ``}
    setSelectedCriterion(newCriterion)
    setIsCriterionModalOpen(true)
  }

  const deleteCriterion = (criterion: RubricCriterion) => {
    const criteria = rubricForm.criteria.filter(c => c.id !== criterion.id)
    const newPointsPossible = criteria.reduce((acc, c) => acc + c.points, 0)
    setRubricFormField('pointsPossible', newPointsPossible)
    setRubricFormField('criteria', criteria)
  }

  const handleSaveCriterion = (updatedCriteria: RubricCriterion) => {
    const criteria = [...rubricForm.criteria]

    const criterionIndexToUpdate = criteria.findIndex(c => c.id === updatedCriteria.id)

    if (criterionIndexToUpdate < 0) {
      criteria.push(updatedCriteria)
    } else {
      criteria[criterionIndexToUpdate] = updatedCriteria
    }

    const newPointsPossible = criteria.reduce((acc, c) => acc + c.points, 0)
    setRubricFormField('pointsPossible', newPointsPossible)
    setRubricFormField('criteria', criteria)
    setIsCriterionModalOpen(false)
  }

  const handleSaveAsDraft = () => {
    setRubricFormField('workflowState', 'draft')
    mutate()
  }

  const handleSave = () => {
    setRubricFormField('workflowState', 'active')
    mutate()
  }

  useEffect(() => {
    if (data) {
      const rubricFormData = translateRubricData(data)
      setRubricForm({...rubricFormData, accountId, courseId})
    }
  }, [accountId, courseId, data])

  useEffect(() => {
    if (saveSuccess) {
      navigate(navigateUrl)
    }
  }, [navigate, navigateUrl, saveSuccess])

  const [distanceToBottom, setDistanceToBottom] = useState<number>(0)
  const containerRef = useRef<HTMLElement>()

  useEffect(() => {
    const calculateDistance = () => {
      if (containerRef.current) {
        const rect = (containerRef.current as HTMLElement).getBoundingClientRect()
        const distance = window.innerHeight - rect.bottom
        setDistanceToBottom(distance)
      }
    }

    calculateDistance()
  }, [containerRef, isLoading])

  if (isLoading && !!rubricId) {
    return <LoadingIndicator />
  }

  return (
    <View as="div">
      <Flex
        height={`${distanceToBottom}px`}
        as="div"
        direction="column"
        elementRef={elRef => {
          if (elRef instanceof HTMLElement) {
            containerRef.current = elRef
          }
        }}
        style={{minHeight: '100%'}}
      >
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

        <Flex.Item>
          <Heading level="h1" as="h1" themeOverride={{h1FontWeight: 700}}>
            {header}
          </Heading>
        </Flex.Item>

        {!rubricForm.unassessed && (
          <Flex.Item>
            <Alert variant="info" margin="medium 0 0 0">
              {I18n.t(
                'Editing is limited for this rubric as it has already been used for grading.'
              )}
            </Alert>
          </Flex.Item>
        )}

        <Flex.Item>
          <Flex margin="large 0 0 0">
            <Flex.Item shouldGrow={true} shouldShrink={true}>
              <TextInput
                data-testid="rubric-form-title"
                renderLabel={I18n.t('Rubric Name')}
                onChange={e => setRubricFormField('title', e.target.value)}
                value={rubricForm.title}
              />
            </Flex.Item>
            {rubricForm.unassessed && (
              <>
                <Flex.Item margin="0 0 0 small">
                  <RubricHidePointsSelect
                    hidePoints={rubricForm.hidePoints}
                    onChangeHidePoints={hidePoints => setRubricFormField('hidePoints', hidePoints)}
                  />
                </Flex.Item>
                <Flex.Item margin="0 0 0 small">
                  <RubricRatingOrderSelect
                    ratingOrder={rubricForm.ratingOrder}
                    onChangeOrder={ratingOrder => setRubricFormField('ratingOrder', ratingOrder)}
                  />
                </Flex.Item>
              </>
            )}
          </Flex>

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
              <Flex.Item>
                <Heading
                  level="h2"
                  as="h2"
                  themeOverride={{h2FontWeight: 700, h2FontSize: '22px', lineHeight: '1.75rem'}}
                >
                  {rubricForm.pointsPossible} {I18n.t('Points Possible')}
                </Heading>
              </Flex.Item>
            </Flex>
          </View>
        </Flex.Item>

        <Flex.Item shouldGrow={true} shouldShrink={true} as="main">
          <View as="div" margin="0 0 small 0">
            {rubricForm.criteria.map((criterion, index) => (
              <RubricCriteriaRow
                key={criterion.id}
                criterion={criterion}
                rowIndex={index + 1}
                unassessed={rubricForm.unassessed}
                onDeleteCriterion={() => deleteCriterion(criterion)}
                onDuplicateCriterion={() => duplicateCriterion(criterion)}
                onEditCriterion={() => openCriterionModal(criterion)}
              />
            ))}

            {rubricForm.unassessed && (
              <NewCriteriaRow
                rowIndex={rubricForm.criteria.length + 1}
                onEditCriterion={() => openCriterionModal()}
              />
            )}
          </View>
        </Flex.Item>

        <Flex.Item as="footer" height="75px">
          <View as="hr" margin="0 0 small 0" />

          <Flex justifyItems="end" margin="0 0 medium 0">
            <Flex.Item margin="0 medium 0 0">
              <Button onClick={() => navigate(navigateUrl)}>{I18n.t('Cancel')}</Button>

              {!rubricForm.hasRubricAssociations && (
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
                  isWithinText={false}
                  margin="x-small 0 0 0"
                  onClick={() => setIsPreviewTrayOpen(true)}
                >
                  <IconEyeLine /> {I18n.t('Preview Rubric')}
                </Link>
              </View>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>

      <CriterionModal
        criterion={selectedCriterion}
        isOpen={isCriterionModalOpen}
        unassessed={rubricForm.unassessed}
        onDismiss={() => setIsCriterionModalOpen(false)}
        onSave={(updatedCriteria: RubricCriterion) => handleSaveCriterion(updatedCriteria)}
      />
      <RubricAssessmentTray
        isOpen={isPreviewTrayOpen}
        isPreviewMode={true}
        rubric={rubricForm}
        rubricAssessmentData={[]}
        onDismiss={() => setIsPreviewTrayOpen(false)}
      />
    </View>
  )
}

type RubricHidePointsSelectProps = {
  hidePoints: boolean
  onChangeHidePoints: (hidePoints: boolean) => void
}
const RubricHidePointsSelect = ({hidePoints, onChangeHidePoints}: RubricHidePointsSelectProps) => {
  const onChange = (value?: string | number) => {
    onChangeHidePoints(value === 'unscored')
  }

  return (
    <SimpleSelect
      renderLabel={I18n.t('Type')}
      width="10.563rem"
      value={hidePoints ? 'unscored' : 'scored'}
      onChange={(e, {value}) => onChange(value)}
      data-testid="rubric-hide-points-select"
    >
      <SimpleSelectOption id="scoredOption" value="scored">
        {I18n.t('Scored')}
      </SimpleSelectOption>
      <SimpleSelectOption id="unscoredOption" value="unscored">
        {I18n.t('Unscored')}
      </SimpleSelectOption>
    </SimpleSelect>
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
      <SimpleSelectOption id="highToLowOption" value="descending">
        {I18n.t('High < Low')}
      </SimpleSelectOption>
      <SimpleSelectOption id="lowToHighOption" value="ascending">
        {I18n.t('Low < High')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
