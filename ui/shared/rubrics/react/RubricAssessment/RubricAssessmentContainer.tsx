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

import React, {useEffect} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {CloseButton, IconButton} from '@instructure/ui-buttons'
import {IconDownloadLine, IconPrinterLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import type {RubricAssessmentData, RubricCriterion} from '../types/rubric'
import {ModernView} from './ModernView'
import {TraditionalView} from './TraditionalView'
import {possibleString} from '../Points'

const I18n = useI18nScope('rubrics-assessment-tray')

const MAX_TRADITIONAL_CRITERIA_RATINGS = 5

export type ViewMode = 'horizontal' | 'vertical' | 'traditional'

type RubricAssessmentContainerProps = {
  criteria: RubricCriterion[]
  isPreviewMode: boolean
  ratingOrder: string
  rubricTitle: string
  rubricAssessmentData: RubricAssessmentData[]
  selectedViewMode: ViewMode
  onViewModeChange: (viewMode: ViewMode) => void
  onDismiss: () => void
  onUpdateAssessmentData: (criteriaId: string, points?: number) => void
}
export const RubricAssessmentContainer = ({
  criteria,
  isPreviewMode,
  ratingOrder,
  rubricTitle,
  rubricAssessmentData,
  selectedViewMode,
  onDismiss,
  onViewModeChange,
  onUpdateAssessmentData,
}: RubricAssessmentContainerProps) => {
  const isTraditionalView = selectedViewMode === 'traditional'
  const instructorPoints = rubricAssessmentData.reduce((prev, curr) => prev + curr.points, 0)
  const disableTraditionalView = criteria.some(
    c => c.ratings.length > MAX_TRADITIONAL_CRITERIA_RATINGS
  )

  const renderViewContainer = () => {
    if (isTraditionalView) {
      return (
        <TraditionalView
          criteria={criteria}
          rubricAssessmentData={rubricAssessmentData}
          rubricTitle={rubricTitle}
          onUpdateAssessmentData={onUpdateAssessmentData}
        />
      )
    }

    return (
      <ModernView
        criteria={criteria}
        isPreviewMode={isPreviewMode}
        ratingOrder={ratingOrder}
        rubricAssessmentData={rubricAssessmentData}
        selectedViewMode={selectedViewMode}
        onUpdateAssessmentData={onUpdateAssessmentData}
      />
    )
  }

  useEffect(() => {
    if (selectedViewMode === 'traditional' && disableTraditionalView) {
      onViewModeChange('vertical')
    }
  }, [criteria, disableTraditionalView, onViewModeChange, selectedViewMode])

  return (
    <View as="div" padding="medium" themeOverride={{paddingMedium: '1rem'}}>
      <View
        as="div"
        position="sticky"
        background="primary"
        stacking="above"
        style={{top: 0}}
        padding={isTraditionalView ? '0 0 medium 0' : '0'}
      >
        <Flex>
          <Flex.Item align="end">
            <Text weight="bold" size="large">
              {rubricTitle}
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

        <View as="hr" margin="x-small 0 small" />
        <Flex>
          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <ViewModeSelect
              disableTraditionalView={disableTraditionalView}
              selectedViewMode={selectedViewMode}
              onViewModeChange={onViewModeChange}
            />
          </Flex.Item>
          {isTraditionalView && (
            <Flex.Item>
              <View as="div" margin="0 large 0 0" themeOverride={{marginLarge: '2.938rem'}}>
                <InstructorScore instructorPoints={instructorPoints} />
              </View>
            </Flex.Item>
          )}
          <Flex.Item margin="0 0 0 small">
            <IconButton disabled={isPreviewMode} screenReaderLabel="Print">
              <IconPrinterLine />
            </IconButton>
          </Flex.Item>
          <Flex.Item margin="0 0 0 small">
            <IconButton disabled={isPreviewMode} screenReaderLabel="Download">
              <IconDownloadLine />
            </IconButton>
          </Flex.Item>
        </Flex>

        {!isTraditionalView && (
          <>
            <Flex.Item margin="0 0 0 small">
              <InstructorScore instructorPoints={instructorPoints} />
            </Flex.Item>

            <View as="hr" margin="medium 0 medium 0" />
          </>
        )}
      </View>

      <View>{renderViewContainer()}</View>
    </View>
  )
}

type ViewModeSelectProps = {
  disableTraditionalView: boolean
  selectedViewMode: ViewMode
  onViewModeChange: (viewMode: ViewMode) => void
}
const ViewModeSelect = ({
  disableTraditionalView,
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
      <SimpleSelect.Option id="traditional" value="traditional" isDisabled={disableTraditionalView}>
        {I18n.t('Traditional')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="horizontal" value="horizontal">
        {I18n.t('Horizontal')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="vertical" value="vertical">
        {I18n.t('Vertical')}
      </SimpleSelect.Option>
    </SimpleSelect>
  )
}

type InstructorScoreProps = {
  instructorPoints: number
}
const InstructorScore = ({instructorPoints = 0}: InstructorScoreProps) => {
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
              {I18n.t('Instructor Score')}
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
            backgroundColor: '#0B874B',
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
