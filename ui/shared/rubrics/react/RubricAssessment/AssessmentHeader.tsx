/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {ViewModeSelect, type ViewMode} from './ViewModeSelect'
import {InstructorScore} from './InstructorScore'
import {SelfAssessmentInstructions} from './SelfAssessmentInstructions'
import {SelfAssessmentInstructorScore} from './SelfAssessmentInstructorScore'

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
export const AssessmentHeader = ({
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
            themeOverride={{h2FontSize: '1.375rem', h2FontWeight: 700}}
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
