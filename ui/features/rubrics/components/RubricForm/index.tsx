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

import React, {useEffect, useState} from 'react'
import {useNavigate, useParams} from 'react-router-dom'
import {showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import getLiveRegion from '@canvas/instui-bindings/react/liveRegion'
import LoadingIndicator from '@canvas/loading-indicator/react'
import {useQuery, useMutation, queryClient} from '@canvas/query'
import type {RubricCriterion} from '@canvas/rubrics/react/types/rubric'
import {Alert} from '@instructure/ui-alerts'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Flex} from '@instructure/ui-flex'
import {
  IconTableLeftHeaderSolid,
  IconTableRowPropertiesSolid,
  IconTableTopHeaderSolid,
} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Link} from '@instructure/ui-link'
import {RubricCriteriaRow} from './RubricCriteriaRow'
import {NewCriteriaRow} from './NewCriteriaRow'
import {fetchRubric, saveRubric, type RubricQueryResponse} from '../../queries/RubricFormQueries'
import type {RubricFormProps} from '../../types/RubricForm'
import {CriterionModal} from './CriterionModal'

const I18n = useI18nScope('rubrics-form')

const {Option: SimpleSelectOption} = SimpleSelect

const defaultRubricForm: RubricFormProps = {
  title: '',
  hidePoints: false,
  criteria: [],
  pointsPossible: 0,
}

const translateRubricData = (fields: RubricQueryResponse): RubricFormProps => {
  return {
    id: fields.id,
    title: fields.title ?? '',
    hidePoints: fields.hidePoints ?? false,
    criteria: fields.criteria ?? [],
    pointsPossible: fields.pointsPossible ?? 0,
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

  if (isLoading && !!rubricId) {
    return <LoadingIndicator />
  }

  return (
    <View as="div">
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
      <Heading level="h1" as="h1" margin="small 0" themeOverride={{h1FontWeight: 700}}>
        {header}
      </Heading>

      <View as="div" display="block" margin="large 0 small 0" maxWidth="45rem">
        <TextInput
          data-testid="rubric-form-title"
          renderLabel={I18n.t('Rubric Name')}
          onChange={e => setRubricFormField('title', e.target.value)}
          value={rubricForm.title}
        />
      </View>
      <View as="div" margin="medium 0" maxWidth="45rem">
        <Flex wrap="wrap" justifyItems="space-between">
          <Flex.Item>
            <Flex>
              <Flex.Item>
                <Text weight="bold">{I18n.t('Type')}:</Text>
              </Flex.Item>
              <Flex.Item margin="0 0 0 small">
                <RubricHidePointsSelect
                  hidePoints={rubricForm.hidePoints}
                  onChangeHidePoints={hidePoints => setRubricFormField('hidePoints', hidePoints)}
                />
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <Flex>
              <Flex.Item>
                <Text weight="bold">{I18n.t('Rating Order')}:</Text>
              </Flex.Item>
              <Flex.Item margin="0 0 0 small">
                <RubricRatingOrderSelect />
              </Flex.Item>
            </Flex>
          </Flex.Item>
          <Flex.Item>
            <Flex>
              <Flex.Item>
                <Text weight="bold">{I18n.t('Button Display')}:</Text>
              </Flex.Item>
              <Flex.Item margin="0 0 0 small">
                <RubricButtonDisplaySelect />
              </Flex.Item>
            </Flex>
          </Flex.Item>
        </Flex>
      </View>

      <View as="hr" margin="large 0 small 0" />

      <View as="div">
        <Flex>
          <Flex.Item shouldGrow={true}>
            <Heading level="h2" as="h2" themeOverride={{h2FontWeight: 700}}>
              {I18n.t('Criteria Builder')}
            </Heading>
          </Flex.Item>
          <Flex.Item>
            <Text weight="bold" size="xx-large" themeOverride={{fontWeightBold: 400}}>
              {rubricForm.pointsPossible}
            </Text>
            <View as="span" margin="0 0 0 small">
              <Text weight="light" size="x-large">
                {I18n.t('Possible Points')}
              </Text>
            </View>
          </Flex.Item>
        </Flex>
      </View>

      <Flex width="100%">
        <Flex.Item
          margin="medium 0 0 0"
          shouldGrow={true}
          shouldShrink={true}
          overflowX="hidden"
          as="main"
        >
          {rubricForm.criteria.map((criterion, index) => (
            <RubricCriteriaRow
              key={criterion.id}
              criterion={criterion}
              rowIndex={index + 1}
              onEditCriterion={() => openCriterionModal(criterion)}
            />
          ))}

          <NewCriteriaRow
            rowIndex={rubricForm.criteria.length + 1}
            onEditCriterion={() => openCriterionModal()}
          />
        </Flex.Item>
      </Flex>

      {/* Need to use div here, View does not set the "bottom" attribute */}
      <div style={{position: 'absolute', bottom: '0', width: '100%'}}>
        <View as="hr" margin="0 0 small 0" />

        <Flex alignItems="end" margin="0 0 medium 0">
          <Flex.Item>
            <Text weight="bold">{I18n.t('Select Rubric Display Type')}:</Text>
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <SimpleSelect renderLabel="" size="small" width="8.125rem">
              <SimpleSelectOption
                id="traditionalOption"
                value="traditional"
                renderBeforeLabel={<IconTableLeftHeaderSolid />}
              >
                {I18n.t('Traditional')}
              </SimpleSelectOption>
              <SimpleSelectOption
                id="verticalOption"
                value="vertical"
                renderBeforeLabel={<IconTableTopHeaderSolid />}
              >
                {I18n.t('Vertical')}
              </SimpleSelectOption>
              <SimpleSelectOption
                id="horizontalOption"
                value="horizontal"
                renderBeforeLabel={<IconTableRowPropertiesSolid />}
              >
                {I18n.t('Horizontal')}
              </SimpleSelectOption>
            </SimpleSelect>
          </Flex.Item>
          <Flex.Item shouldGrow={true} margin="0 0 0 small">
            <Link as="button" isWithinText={false}>
              {I18n.t('Preview')}
            </Link>
          </Flex.Item>
          <Flex.Item>
            <Button onClick={() => navigate(navigateUrl)}>{I18n.t('Cancel')}</Button>

            <Button
              margin="0 0 0 small"
              color="primary"
              onClick={() => mutate()}
              disabled={saveLoading || !formValid()}
              data-testid="save-rubric-button"
            >
              {I18n.t('Save Rubric')}
            </Button>
          </Flex.Item>
        </Flex>
      </div>

      <CriterionModal
        criterion={selectedCriterion}
        isOpen={isCriterionModalOpen}
        onDismiss={() => setIsCriterionModalOpen(false)}
        onSave={(updatedCriteria: RubricCriterion) => handleSaveCriterion(updatedCriteria)}
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
      renderLabel={<ScreenReaderContent>{I18n.t('Rubric Type')}</ScreenReaderContent>}
      size="small"
      width="8.125rem"
      value={hidePoints ? 'unscored' : 'scored'}
      onChange={(e, {value}) => onChange(value)}
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

const RubricRatingOrderSelect = () => {
  return (
    <SimpleSelect
      renderLabel={<ScreenReaderContent>{I18n.t('Rubric Rating Order')}</ScreenReaderContent>}
      size="small"
      width="8.125rem"
    >
      <SimpleSelectOption id="highToLowOption" value="highToLow">
        {I18n.t('High < Low')}
      </SimpleSelectOption>
      <SimpleSelectOption id="lowToHighOption" value="lowToHigh">
        {I18n.t('Low < High')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}

const RubricButtonDisplaySelect = () => {
  return (
    <SimpleSelect
      renderLabel={<ScreenReaderContent>{I18n.t('Rubric Button Display')}</ScreenReaderContent>}
      size="small"
      width="8.125rem"
    >
      <SimpleSelectOption id="numericOption" value="numeric">
        {I18n.t('Numeric')}
      </SimpleSelectOption>
      <SimpleSelectOption id="emojiOption" value="emoji">
        {I18n.t('Emoji')}
      </SimpleSelectOption>
      <SimpleSelectOption id="letterOption" value="letter">
        {I18n.t('Letter')}
      </SimpleSelectOption>
    </SimpleSelect>
  )
}
