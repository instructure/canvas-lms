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

import React, {useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {colors} from '@instructure/canvas-theme'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'
import type {
  RubricAssessmentData,
  RubricAssessmentSelect,
  RubricCriterion,
  UpdateAssessmentData,
} from '../types/rubric'
import {ModernView} from './ModernView'
import {TraditionalView} from './TraditionalView'
import {possibleString} from '../Points'

const I18n = useI18nScope('rubrics-assessment-tray')

const MAX_TRADITIONAL_CRITERIA_RATINGS = 5

export type ViewMode = 'horizontal' | 'vertical' | 'traditional'
const {ash, shamrock} = colors

type RubricAssessmentContainerProps = {
  criteria: RubricCriterion[]
  hidePoints: boolean
  isPreviewMode: boolean
  isPeerReview: boolean
  isFreeFormCriterionComments: boolean
  ratingOrder: string
  rubricTitle: string
  rubricAssessmentData: RubricAssessmentData[]
  rubricAssessmentId: string
  rubricAssessors: RubricAssessmentSelect
  rubricSavedComments?: Record<string, string[]>
  selectedViewMode: ViewMode
  onAccessorChange: (accessorId: string) => void
  onViewModeChange: (viewMode: ViewMode) => void
  onDismiss: () => void
  onSubmit?: () => void
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
}
export const RubricAssessmentContainer = ({
  criteria,
  hidePoints,
  isPreviewMode,
  isPeerReview,
  isFreeFormCriterionComments,
  ratingOrder,
  rubricTitle,
  rubricAssessmentData,
  rubricAssessmentId,
  rubricAssessors,
  rubricSavedComments = {},
  selectedViewMode,
  onAccessorChange,
  onDismiss,
  onSubmit,
  onViewModeChange,
  onUpdateAssessmentData,
}: RubricAssessmentContainerProps) => {
  const isTraditionalView = selectedViewMode === 'traditional'
  const instructorPoints = rubricAssessmentData.reduce((prev, curr) => prev + (curr.points ?? 0), 0)
  const disableTraditionalView = criteria.some(
    c => c.ratings.length > MAX_TRADITIONAL_CRITERIA_RATINGS
  )

  const [distanceToBottom, setDistanceToBottom] = useState<number>(0)
  const containerRef = useRef<HTMLElement>()

  useEffect(() => {
    const calculateDistance = () => {
      if (containerRef.current) {
        const rect = (containerRef.current as HTMLElement).getBoundingClientRect()
        const isMasquerade = !!document.querySelector('body.is-masquerading-or-student-view')
        const masqueradeHeight = isMasquerade ? 50 : 0
        const distance = window.innerHeight - rect.bottom - masqueradeHeight
        setDistanceToBottom(distance)
      }
    }

    calculateDistance()
  }, [containerRef])

  const renderViewContainer = () => {
    if (isTraditionalView) {
      return (
        <TraditionalView
          criteria={criteria}
          hidePoints={hidePoints}
          ratingOrder={ratingOrder}
          rubricAssessmentData={rubricAssessmentData}
          rubricTitle={rubricTitle}
          rubricSavedComments={rubricSavedComments}
          isPreviewMode={isPreviewMode}
          isPeerReview={isPeerReview}
          isFreeFormCriterionComments={isFreeFormCriterionComments}
          onUpdateAssessmentData={onUpdateAssessmentData}
        />
      )
    }

    return (
      <ModernView
        criteria={criteria}
        hidePoints={hidePoints}
        isPreviewMode={isPreviewMode}
        isPeerReview={isPeerReview}
        ratingOrder={ratingOrder}
        rubricSavedComments={rubricSavedComments}
        rubricAssessmentData={rubricAssessmentData}
        selectedViewMode={selectedViewMode}
        onUpdateAssessmentData={onUpdateAssessmentData}
        isFreeFormCriterionComments={isFreeFormCriterionComments}
      />
    )
  }

  useEffect(() => {
    if (selectedViewMode === 'traditional' && disableTraditionalView) {
      onViewModeChange('vertical')
    }
  }, [criteria, disableTraditionalView, onViewModeChange, selectedViewMode])

  const rubricHeader = isPeerReview ? I18n.t('Peer Review') : I18n.t('Rubric')

  return (
    <View as="div" padding="medium medium 0 medium" themeOverride={{paddingMedium: '1rem'}}>
      <Flex
        as="div"
        direction="column"
        height={`${distanceToBottom}px`}
        elementRef={elRef => {
          if (elRef instanceof HTMLElement) {
            containerRef.current = elRef
          }
        }}
      >
        <Flex.Item as="header">
          <AssessmentHeader
            disableTraditionalView={disableTraditionalView}
            hidePoints={hidePoints}
            instructorPoints={instructorPoints}
            isFreeFormCriterionComments={isFreeFormCriterionComments}
            isPreviewMode={isPreviewMode}
            isPeerReview={isPeerReview}
            isTraditionalView={isTraditionalView}
            onAccessorChange={onAccessorChange}
            onDismiss={onDismiss}
            onViewModeChange={onViewModeChange}
            rubricAssessmentId={rubricAssessmentId}
            rubricAssessors={rubricAssessors}
            rubricHeader={rubricHeader}
            selectedViewMode={selectedViewMode}
          />
        </Flex.Item>
        <Flex.Item shouldGrow={true} shouldShrink={true} as="main">
          <View as="div" overflowY="auto">
            {renderViewContainer()}
          </View>
        </Flex.Item>
        {!isPreviewMode && onSubmit && (
          <Flex.Item as="footer">
            <AssessmentFooter onSubmit={onSubmit} />
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

type ViewModeSelectProps = {
  disableTraditionalView: boolean
  isFreeFormCriterionComments: boolean
  selectedViewMode: ViewMode
  onViewModeChange: (viewMode: ViewMode) => void
}
const ViewModeSelect = ({
  disableTraditionalView,
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
        isDisabled={disableTraditionalView}
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

type InstructorScoreProps = {
  instructorPoints: number
  isPeerReview: boolean
  isPreviewMode: boolean
}
const InstructorScore = ({
  instructorPoints = 0,
  isPeerReview,
  isPreviewMode,
}: InstructorScoreProps) => {
  return (
    <Flex as="div" height="3rem" alignItems="center">
      <Flex.Item as="div" width="13.813rem" align="center">
        <div
          style={{
            lineHeight: '3rem',
            width: '13.813rem',
            height: '3rem',
            backgroundColor: '#F5F5F5',
            borderRadius: '.35rem 0 0 .35rem',
          }}
        >
          <View as="span" margin="0 0 0 small">
            <Text size="medium" weight="bold">
              {isPeerReview ? I18n.t('Peer Review Score') : I18n.t('Instructor Score')}
            </Text>
          </View>
        </div>
      </Flex.Item>
      <Flex.Item as="div" width="4.313rem" height="3rem">
        <div
          style={{
            lineHeight: '3rem',
            width: '4.313rem',
            height: '3rem',
            backgroundColor: isPreviewMode ? ash : shamrock,
            borderRadius: '0 .35rem .35rem 0',
            textAlign: 'center',
          }}
        >
          <Text
            size="medium"
            weight="bold"
            color="primary-inverse"
            data-testid="rubric-assessment-instructor-score"
          >
            {possibleString(instructorPoints)}
          </Text>
        </div>
      </Flex.Item>
    </Flex>
  )
}

type AccessorSelectProps = {
  rubricAssessmentId: string
  rubricAssessors: RubricAssessmentSelect
  showLabel: boolean
  onAccessorChange: (accessorId: string) => void
}
const AccessorSelect = ({
  rubricAssessmentId,
  rubricAssessors,
  showLabel,
  onAccessorChange,
}: AccessorSelectProps) => {
  const label = I18n.t('Select Rubric')
  return (
    <SimpleSelect
      data-testid="rubric-assessment-accessor-select"
      renderLabel={showLabel ? label : <ScreenReaderContent>{label}</ScreenReaderContent>}
      value={rubricAssessmentId}
      onChange={(e, {value}) => onAccessorChange((value ?? '') as string)}
    >
      {rubricAssessors.map(assessor => (
        <SimpleSelect.Option key={assessor.id} id={assessor.id} value={assessor.id}>
          {assessor.name ?? ''}
        </SimpleSelect.Option>
      ))}
    </SimpleSelect>
  )
}

type AssessmentHeaderProps = {
  disableTraditionalView: boolean
  hidePoints: boolean
  instructorPoints: number
  isFreeFormCriterionComments: boolean
  isPreviewMode: boolean
  isPeerReview: boolean
  isTraditionalView: boolean
  onDismiss: () => void
  onViewModeChange: (viewMode: ViewMode) => void
  onAccessorChange: (accessorId: string) => void
  rubricAssessmentId: string
  rubricAssessors: RubricAssessmentSelect
  rubricHeader: string
  selectedViewMode: ViewMode
}
const AssessmentHeader = ({
  disableTraditionalView,
  hidePoints,
  instructorPoints,
  isFreeFormCriterionComments,
  isPreviewMode,
  isPeerReview,
  isTraditionalView,
  onAccessorChange,
  onDismiss,
  onViewModeChange,
  rubricAssessmentId,
  rubricAssessors,
  rubricHeader,
  selectedViewMode,
}: AssessmentHeaderProps) => {
  return (
    <View
      as="div"
      padding={isTraditionalView ? '0 0 medium 0' : '0'}
      overflowX="hidden"
      overflowY="hidden"
    >
      <Flex>
        <Flex.Item align="end">
          <Text weight="bold" size="large" data-testid="rubric-assessment-header">
            {rubricHeader}
          </Text>
        </Flex.Item>
        <Flex.Item align="end">
          <CloseButton
            placement="end"
            offset="x-small"
            screenReaderLabel="Close"
            onClick={onDismiss}
          />
        </Flex.Item>
      </Flex>

      <View as="hr" margin="x-small 0 small" aria-hidden={true} />
      <Flex>
        <Flex.Item shouldGrow={true} shouldShrink={true}>
          <ViewModeSelect
            disableTraditionalView={disableTraditionalView}
            isFreeFormCriterionComments={isFreeFormCriterionComments}
            selectedViewMode={selectedViewMode}
            onViewModeChange={onViewModeChange}
          />
        </Flex.Item>
        {isTraditionalView && (
          <>
            {rubricAssessors.length > 0 && rubricAssessmentId && (
              <Flex.Item>
                <View as="div" margin="0 large 0 0" themeOverride={{marginLarge: '2.938rem'}}>
                  <AccessorSelect
                    rubricAssessmentId={rubricAssessmentId}
                    rubricAssessors={rubricAssessors}
                    showLabel={false}
                    onAccessorChange={onAccessorChange}
                  />
                </View>
              </Flex.Item>
            )}
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
        {/* <Flex.Item margin="0 0 0 small">
          <IconButton disabled={isPreviewMode} screenReaderLabel="Print">
            <IconPrinterLine />
          </IconButton>
        </Flex.Item>
        <Flex.Item margin="0 0 0 small">
          <IconButton disabled={isPreviewMode} screenReaderLabel="Download">
            <IconDownloadLine />
          </IconButton>
        </Flex.Item> */}
      </Flex>

      {!isTraditionalView && (
        <>
          {rubricAssessors.length > 0 && rubricAssessmentId && (
            <Flex.Item margin="0 0 0 small">
              <AccessorSelect
                rubricAssessmentId={rubricAssessmentId}
                rubricAssessors={rubricAssessors}
                showLabel={true}
                onAccessorChange={onAccessorChange}
              />
            </Flex.Item>
          )}

          {!hidePoints && (
            <Flex.Item margin="0 0 0 small">
              <InstructorScore
                isPeerReview={isPeerReview}
                instructorPoints={instructorPoints}
                isPreviewMode={isPreviewMode}
              />
            </Flex.Item>
          )}

          <View as="hr" margin="medium 0 medium 0" aria-hidden={true} />
        </>
      )}
    </View>
  )
}

type AssessmentFooterProps = {
  onSubmit?: () => void
}
const AssessmentFooter = ({onSubmit}: AssessmentFooterProps) => {
  return (
    <View as="div" data-testid="rubric-assessment-footer">
      <View as="hr" margin="0" />
      <Flex justifyItems="end" margin="small 0">
        <Flex.Item>
          <Button
            color="primary"
            onClick={() => onSubmit?.()}
            data-testid="save-rubric-assessment-button"
          >
            {I18n.t('Submit Assessment')}
          </Button>
        </Flex.Item>
      </Flex>
    </View>
  )
}
