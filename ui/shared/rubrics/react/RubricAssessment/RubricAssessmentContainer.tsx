/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useEffect, useMemo, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import type {
  RubricAssessmentData,
  RubricCriterion,
  RubricSubmissionUser,
  RubricRating,
  UpdateAssessmentData,
} from '../types/rubric'
import {ModernView, type ModernViewModes} from './ModernView'
import {TraditionalView} from './TraditionalView'
import {InstructorScore} from './InstructorScore'
import {findCriterionMatchingRatingIndex} from './utils/rubricUtils'
import {SelfAssessmentInstructorScore} from '@canvas/rubrics/react/RubricAssessment/SelfAssessmentInstructorScore'
import {SelfAssessmentInstructions} from '@canvas/rubrics/react/RubricAssessment/SelfAssessmentInstructions'
import {Checkbox} from '@instructure/ui-checkbox'
import { Heading } from '@instructure/ui-heading'

const I18n = createI18nScope('rubrics-assessment-tray')

export type ViewMode = 'horizontal' | 'vertical' | 'traditional'

export type RubricAssessmentContainerProps = {
  criteria: RubricCriterion[]
  hidePoints: boolean
  isPreviewMode: boolean
  isPeerReview: boolean
  isSelfAssessment?: boolean
  isFreeFormCriterionComments: boolean
  isStandaloneContainer?: boolean
  ratingOrder: string
  rubricTitle: string
  pointsPossible?: number
  rubricAssessmentData: RubricAssessmentData[]
  rubricSavedComments?: Record<string, string[]>
  selfAssessment?: RubricAssessmentData[] | null
  selfAssessmentDate?: string
  submissionUser?: RubricSubmissionUser
  viewModeOverride?: ViewMode
  onViewModeChange?: (viewMode: ViewMode) => void
  onDismiss: () => void
  onSubmit?: (rubricAssessmentDraftData: RubricAssessmentData[]) => void
}
export const RubricAssessmentContainer = ({
  criteria,
  hidePoints,
  isPreviewMode,
  isPeerReview,
  isSelfAssessment = false,
  isFreeFormCriterionComments,
  pointsPossible,
  isStandaloneContainer = false,
  ratingOrder,
  rubricTitle,
  rubricAssessmentData,
  rubricSavedComments = {},
  selfAssessment,
  selfAssessmentDate,
  submissionUser,
  viewModeOverride,
  onDismiss,
  onSubmit,
  onViewModeChange,
}: RubricAssessmentContainerProps) => {
  const [viewModeSelect, setViewModeSelect] = useState<ViewMode>(viewModeOverride ?? 'traditional')
  const [rubricAssessmentDraftData, setRubricAssessmentDraftData] = useState<
    RubricAssessmentData[]
  >([])
  const [showSelfAssessment, setShowSelfAssessment] = useState<boolean>(false)
  const viewMode = viewModeOverride ?? viewModeSelect
  const isTraditionalView = viewMode === 'traditional'
  const instructorPoints = rubricAssessmentDraftData.reduce(
    (prev, curr) => prev + (!curr.ignoreForScoring && curr.points ? curr.points : 0),
    0,
  )

  const [validationErrors, setValidationErrors] = useState<string[]>([])

  const selfAssessmentData: RubricAssessmentData[] = useMemo(() => {
    if (!showSelfAssessment) {
      return []
    }

    return (
      selfAssessment?.map(entry => ({
        id: entry.id,
        points: entry.points,
        criterionId: entry.criterionId,
        comments: entry.comments,
        commentsEnabled: entry.commentsEnabled,
        description: entry.description,
        updatedAt: selfAssessmentDate,
      })) ?? []
    )
  }, [selfAssessment, showSelfAssessment, selfAssessmentDate])

  useEffect(() => {
    const updatedRubricAssessmentData = rubricAssessmentData.map(rubricAssessment => {
      const matchingCriteria = criteria?.find(c => c.id === rubricAssessment.criterionId)
      const ignoreForScoring = matchingCriteria?.ignoreForScoring || false

      return {
        ...rubricAssessment,
        ignoreForScoring,
      }
    })

    setRubricAssessmentDraftData(updatedRubricAssessmentData)
  }, [rubricAssessmentData, criteria])

  const preSubmitValidation = () => {
    const errors = criteria.reduce((acc: string[], criterion: RubricCriterion) => {
      const assessment = rubricAssessmentDraftData.find(data => data.criterionId === criterion.id)

      const requiresComments = isFreeFormCriterionComments && hidePoints
      const requiresPoints = !requiresComments

      if (requiresComments && !assessment?.comments) {
        acc.push(criterion.id)
      }

      if (requiresPoints && typeof assessment?.points !== 'number') {
        acc.push(criterion.id)
      }

      return acc
    }, [])

    setValidationErrors(errors)
    return errors.length === 0
  }

  const validateOnSubmit = (rubricAssessmentDraftData: RubricAssessmentData[]) => {
    if (isPeerReview) {
      if (preSubmitValidation()) {
        onSubmit?.(rubricAssessmentDraftData)
      }
    } else {
      onSubmit?.(rubricAssessmentDraftData)
    }
  }

  const renderViewContainer = () => {
    if (isTraditionalView && !isSelfAssessment) {
      return (
        <TraditionalView
          criteria={criteria}
          hidePoints={hidePoints}
          ratingOrder={ratingOrder}
          rubricAssessmentData={rubricAssessmentDraftData}
          rubricTitle={rubricTitle}
          rubricSavedComments={rubricSavedComments}
          isPreviewMode={isPreviewMode}
          isPeerReview={isPeerReview}
          isFreeFormCriterionComments={isFreeFormCriterionComments}
          selfAssessment={selfAssessmentData}
          submissionUser={submissionUser}
          onUpdateAssessmentData={onUpdateAssessmentData}
          validationErrors={validationErrors}
        />
      )
    }

    return (
      <ModernView
        criteria={criteria}
        hidePoints={hidePoints}
        isPreviewMode={isPreviewMode}
        isPeerReview={isPeerReview}
        isSelfAssessment={isSelfAssessment}
        ratingOrder={ratingOrder}
        rubricSavedComments={rubricSavedComments}
        rubricAssessmentData={rubricAssessmentDraftData}
        selectedViewMode={viewMode as ModernViewModes}
        isFreeFormCriterionComments={isFreeFormCriterionComments}
        validationErrors={validationErrors}
        selfAssessment={selfAssessmentData}
        onUpdateAssessmentData={onUpdateAssessmentData}
        submissionUser={submissionUser}
      />
    )
  }

  const rubricHeader = isPeerReview ? I18n.t('Peer Review') : I18n.t('Rubric')

  const handleViewModeChange = (newViewMode: ViewMode) => {
    setViewModeSelect(newViewMode)
    onViewModeChange?.(newViewMode)
  }

  const onUpdateAssessmentData = (params: UpdateAssessmentData) => {
    const {criterionId, points, comments = '', saveCommentsForLater, ratingId} = params
    const existingAssessmentIndex = rubricAssessmentDraftData.findIndex(
      a => a.criterionId === criterionId,
    )
    const matchingCriteria = criteria?.find(c => c.id === criterionId)
    const ignoreForScoring = matchingCriteria?.ignoreForScoring || false
    const criteriaRatings = matchingCriteria?.ratings ?? []
    const matchingRating: RubricRating | undefined = ratingId
      ? criteriaRatings.find(r => r.id === ratingId)
      : criteriaRatings[
          findCriterionMatchingRatingIndex(
            matchingCriteria?.ratings ?? [],
            points,
            matchingCriteria?.criterionUseRange,
          )
        ]
    const matchingRatingId = matchingRating?.id ?? ''
    const ratingDescription = matchingRating?.description ?? ''
    if (existingAssessmentIndex === -1) {
      setRubricAssessmentDraftData([
        ...rubricAssessmentDraftData,
        {
          criterionId,
          points,
          comments,
          id: matchingRatingId,
          ignoreForScoring,
          commentsEnabled: true,
          description: ratingDescription,
          saveCommentsForLater,
        },
      ])
    } else {
      setRubricAssessmentDraftData(
        rubricAssessmentDraftData.map(a =>
          a.criterionId === criterionId
            ? {
                ...a,
                comments,
                id: matchingRatingId,
                points,
                ignoreForScoring,
                description: ratingDescription,
                saveCommentsForLater,
              }
            : a,
        ),
      )
    }
  }

  const shouldShowFooter = isStandaloneContainer || (!isPreviewMode && onSubmit)

  return (
    <View as="div" data-testid="enhanced-rubric-assessment-container">
      <Flex as="div" direction="column">
        <Flex.Item as="header">
          <AssessmentHeader
            hidePoints={hidePoints}
            instructorPoints={instructorPoints}
            isFreeFormCriterionComments={isFreeFormCriterionComments}
            isPreviewMode={isPreviewMode}
            isPeerReview={isPeerReview}
            pointsPossible={pointsPossible}
            isSelfAssessment={isSelfAssessment}
            isStandaloneContainer={isStandaloneContainer}
            isTraditionalView={isTraditionalView}
            onDismiss={onDismiss}
            onViewModeChange={handleViewModeChange}
            rubricHeader={rubricHeader}
            selectedViewMode={viewMode}
            selfAssessmentEnabled={!!selfAssessment}
            toggleSelfAssessment={() => setShowSelfAssessment(!showSelfAssessment)}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true} as="main">
          <View as="div" overflowY="auto">
            {renderViewContainer()}
          </View>
        </Flex.Item>
        {shouldShowFooter && (
          <Flex.Item as="footer">
            <AssessmentFooter
              isPreviewMode={isPreviewMode}
              isStandAloneContainer={isStandaloneContainer}
              onDismiss={onDismiss}
              onSubmit={onSubmit ? () => validateOnSubmit(rubricAssessmentDraftData) : undefined}
            />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

type ViewModeSelectProps = {
  isFreeFormCriterionComments: boolean
  selectedViewMode: ViewMode
  onViewModeChange: (viewMode: ViewMode) => void
}
const ViewModeSelect = ({
  isFreeFormCriterionComments,
  selectedViewMode,
  onViewModeChange,
}: ViewModeSelectProps) => {
  const handleSelect = (viewMode: string) => {
    onViewModeChange(viewMode as ViewMode)
  }

  return (
    <SimpleSelect
      renderLabel={
        <ScreenReaderContent>{I18n.t('Rubric Assessment View Mode')}</ScreenReaderContent>
      }
      width="10rem"
      height="2.375rem"
      value={selectedViewMode}
      data-testid="rubric-assessment-view-mode-select"
      onChange={(_e, {value}) => handleSelect(value as string)}
    >
      <SimpleSelect.Option
        id="traditional"
        value="traditional"
        data-testid="traditional-view-option"
      >
        {I18n.t('Traditional')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="horizontal" value="horizontal" data-testid="horizontal-view-option">
        {I18n.t('Horizontal')}
      </SimpleSelect.Option>
      {!isFreeFormCriterionComments && (
        <SimpleSelect.Option id="vertical" value="vertical" data-testid="vertical-view-option">
          {I18n.t('Vertical')}
        </SimpleSelect.Option>
      )}
    </SimpleSelect>
  )
}

type AssessmentHeaderProps = {
  hidePoints: boolean
  instructorPoints: number
  pointsPossible?: number
  isFreeFormCriterionComments: boolean
  isPreviewMode: boolean
  isPeerReview: boolean
  isSelfAssessment: boolean
  isStandaloneContainer: boolean
  isTraditionalView: boolean
  onDismiss: () => void
  onViewModeChange: (viewMode: ViewMode) => void
  rubricHeader: string
  selectedViewMode: ViewMode
  selfAssessmentEnabled?: boolean
  toggleSelfAssessment: () => void
}
const AssessmentHeader = ({
  hidePoints,
  instructorPoints,
  isFreeFormCriterionComments,
  isPreviewMode,
  isPeerReview,
  isSelfAssessment,
  pointsPossible,
  isStandaloneContainer,
  isTraditionalView,
  onDismiss,
  onViewModeChange,
  rubricHeader,
  selectedViewMode,
  selfAssessmentEnabled,
  toggleSelfAssessment,
}: AssessmentHeaderProps) => {
  const showTraditionalView = () => isTraditionalView && !isSelfAssessment

  return (
    <View
      as="div"
      padding={isTraditionalView ? '0 0 medium 0' : '0'}
      overflowX="hidden"
      overflowY="hidden"
    >
      <Flex>
        <Flex.Item align="end">
          <Heading 
            level="h2" 
            data-testid="rubric-assessment-header"
            margin="xxx-small 0"
            themeOverride={{h2FontSize: "1.375rem", h2FontWeight: 700}}
          >
            {rubricHeader}
          </Heading>
        </Flex.Item>
        {!isStandaloneContainer && (
          <Flex.Item align="end">
            <CloseButton
              placement="end"
              offset="x-small"
              screenReaderLabel="Close"
              onClick={onDismiss}
            />
          </Flex.Item>
        )}
      </Flex>

      <View as="hr" margin="x-small 0 small" aria-hidden={true} />
      <Flex wrap="wrap" gap="medium 0">
        {!isSelfAssessment && (
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <ViewModeSelect
              isFreeFormCriterionComments={isFreeFormCriterionComments}
              selectedViewMode={selectedViewMode}
              onViewModeChange={onViewModeChange}
            />
          </Flex.Item>
        )}
        {showTraditionalView() && (
          <>
            {!hidePoints && (
              <Flex.Item>
                <View as="div" margin="0 large 0 0" themeOverride={{marginLarge: '2.938rem'}}>
                  <InstructorScore
                    isPeerReview={isPeerReview}
                    instructorPoints={instructorPoints}
                    isPreviewMode={isPreviewMode}
                  />
                </View>
              </Flex.Item>
            )}
          </>
        )}
      </Flex>
      {isSelfAssessment && <SelfAssessmentInstructions />}
      {!showTraditionalView() && (
        <>
          {!hidePoints && (
            <>
              {isSelfAssessment ? (
                <SelfAssessmentInstructorScore
                  instructorPoints={instructorPoints}
                  pointsPossible={pointsPossible}
                />
              ) : (
                <View as="div" margin="medium 0 0">
                  <InstructorScore
                    isPeerReview={isPeerReview}
                    instructorPoints={instructorPoints}
                    isPreviewMode={isPreviewMode}
                  />
                </View>
              )}
            </>
          )}

          <View as="hr" margin="medium 0 medium 0" aria-hidden={true} />
        </>
      )}

      {selfAssessmentEnabled && (
        <View as="div" margin="small 0 0">
          <Checkbox
            label="View Student Self-Assessment"
            data-testid="self-assessment-toggle"
            variant="toggle"
            size="medium"
            onClick={toggleSelfAssessment}
          />
        </View>
      )}
    </View>
  )
}

type AssessmentFooterProps = {
  isPreviewMode: boolean
  isStandAloneContainer: boolean
  onDismiss: () => void
  onSubmit?: () => void
}
const AssessmentFooter = ({
  isPreviewMode,
  isStandAloneContainer,
  onDismiss,
  onSubmit,
}: AssessmentFooterProps) => {
  return (
    <View as="div" data-testid="rubric-assessment-footer" overflowX="hidden" overflowY="hidden">
      <Flex justifyItems="end" margin="small 0">
        {isStandAloneContainer && (
          <Flex.Item margin="0 small 0 0">
            <Button
              color="secondary"
              onClick={() => onDismiss()}
              data-testid="cancel-rubric-assessment-button"
            >
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
        )}
        {onSubmit && !isPreviewMode && (
          <Flex.Item>
            <Button
              color="primary"
              onClick={() => onSubmit()}
              data-testid="save-rubric-assessment-button"
            >
              {I18n.t('Submit Assessment')}
            </Button>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}
