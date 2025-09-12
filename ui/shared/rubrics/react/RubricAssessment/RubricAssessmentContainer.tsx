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
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import type {
  RubricAssessmentData,
  RubricCriterion,
  RubricSubmissionUser,
  RubricRating,
  UpdateAssessmentData,
} from '../types/rubric'
import {ModernView, type ModernViewModes} from './ModernView'
import {TraditionalView} from './TraditionalView'
import {findCriterionMatchingRatingIndex, isRubricComplete} from './utils/rubricUtils'
import useLocalStorage from '@canvas/local-storage'
import * as CONSTANTS from './constants'
import {type ViewMode} from './ViewModeSelect'
import {AssessmentHeader} from './AssessmentHeader'
import {AssessmentFooter} from './AssessmentFooter'

const I18n = createI18nScope('rubrics-assessment-tray')

export type RubricAssessmentContainerProps = {
  buttonDisplay: string
  criteria: RubricCriterion[]
  currentUserId: string
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
  buttonDisplay,
  criteria,
  currentUserId,
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
  // Temporarily comment this code out for this release
  // const [viewModeSelect, setViewModeSelect] = useLocalStorage<ViewMode>(
  //   CONSTANTS.RUBRIC_VIEW_MODE_LOCALSTORAGE_KEY(currentUserId),
  //   viewModeOverride ?? CONSTANTS.RUBRIC_VIEW_MODE_DEFAULT,
  // )
  const [viewModeSelect, setViewModeSelect] = useState<ViewMode>(viewModeOverride ?? 'traditional')

  const [rubricAssessmentDraftData, setRubricAssessmentDraftData] = useState<
    RubricAssessmentData[]
  >([])
  const [showSelfAssessment, setShowSelfAssessment] = useState<boolean>(false)
  let viewMode = viewModeOverride ?? viewModeSelect
  const isTraditionalView = viewMode === 'traditional'
  const isVerticalView = viewModeSelect === 'vertical'
  if (isVerticalView && isFreeFormCriterionComments) {
    viewMode = 'horizontal'
  }
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
        buttonDisplay={buttonDisplay}
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
              isRubricComplete={isRubricComplete({
                criteria,
                isFreeFormCriterionComments,
                hidePoints,
                rubricAssessment: rubricAssessmentDraftData,
              })}
              onDismiss={onDismiss}
              onSubmit={onSubmit ? () => validateOnSubmit(rubricAssessmentDraftData) : undefined}
            />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}
