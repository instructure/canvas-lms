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

import {useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {colors} from '@instructure/canvas-theme'
import {Table} from '@instructure/ui-table'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import type {
  RubricAssessmentData,
  RubricCriterion,
  RubricSubmissionUser,
  UpdateAssessmentData,
} from '../types/rubric'
import {TraditionalViewCriterionRow} from './TraditionalViewCriterionRow'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'

const I18n = createI18nScope('rubrics-assessment-tray')

export type TraditionalViewProps = {
  criteria: RubricCriterion[]
  hidePoints: boolean
  isFreeFormCriterionComments: boolean
  isPeerReview?: boolean
  isPreviewMode: boolean
  ratingOrder?: string
  rubricAssessmentData: RubricAssessmentData[]
  rubricSavedComments?: Record<string, string[]>
  rubricTitle: string
  selfAssessment?: RubricAssessmentData[]
  submissionUser?: RubricSubmissionUser
  validationErrors?: string[]
  onUpdateAssessmentData: (params: UpdateAssessmentData) => void
}

export const TraditionalView = ({
  criteria,
  hidePoints,
  isFreeFormCriterionComments,
  isPeerReview,
  isPreviewMode,
  ratingOrder = 'descending',
  rubricAssessmentData,
  rubricSavedComments,
  rubricTitle,
  selfAssessment,
  submissionUser,
  validationErrors,
  onUpdateAssessmentData,
}: TraditionalViewProps) => {
  const pointsColumnWidth = hidePoints ? 0 : 8.875
  const criteriaColumnWidth = 11.25
  const maxRatingsCount = Math.max(...criteria.map(criterion => criterion.ratings.length))
  const ratingsColumnMinWidth = 8.5 * maxRatingsCount
  const gridMinWidth = `${pointsColumnWidth + criteriaColumnWidth + ratingsColumnMinWidth}rem`

  const headers = useMemo(() => {
    const headers = [
      {
        id: 'rubric-header-criteria',
        label: I18n.t('Criteria'),
      },
    ]

    if (isFreeFormCriterionComments) {
      headers.push({
        id: 'rubric-header-comments',
        label: I18n.t('Comments'),
      })
    } else {
      headers.push({
        id: 'rubric-header-ratings',
        label: I18n.t('Ratings'),
      })
    }

    if (!hidePoints) {
      headers.push({
        id: 'rubric-header-points',
        label: I18n.t('Points'),
      })
    }

    return headers
  }, [isFreeFormCriterionComments, hidePoints])

  return (
    <View
      as="div"
      margin="0 0 small 0"
      data-testid="rubric-assessment-traditional-view"
      minWidth={gridMinWidth}
      borderColor={colors.primitives.grey14}
      borderWidth="small"
    >
      <View
        as="div"
        width="100%"
        background="secondary"
        padding="x-small small"
        themeOverride={{paddingXSmall: '0.438rem'}}
      >
        <Text weight="bold">{rubricTitle}</Text>
      </View>

      <table style={{width: '100%', height: '100%'}}>
        <caption aria-hidden="true">
          <ScreenReaderContent>{rubricTitle || I18n.t('Rubric')}</ScreenReaderContent>
        </caption>
        <Table.Head
          themeOverride={{
            background: colors.primitives.grey11,
          }}
        >
          <tr>
            {headers.map((header, index) => (
              <View
                as="td"
                key={header.id}
                id={header.id}
                background="secondary"
                borderColor={colors.primitives.grey14}
                borderWidth={`small ${index === headers.length - 1 ? 0 : 'small'} small 0`}
                padding="x-small small"
              >
                <Text weight="bold">{header.label}</Text>
              </View>
            ))}
          </tr>
        </Table.Head>

        <Table.Body>
          {criteria.map((criterion, index) => {
            const criterionAssessment = rubricAssessmentData.find(
              data => data.criterionId === criterion.id,
            )
            const criterionSelfAssessment = selfAssessment?.find(
              data => data.criterionId === criterion.id,
            )

            const isLastIndex = criteria.length - 1 === index

            return (
              <TraditionalViewCriterionRow
                // we use the array index because rating may not have an id
                key={`criterion-${criterion.id}-${index}`}
                colCount={headers.length}
                criterion={criterion}
                criterionAssessment={criterionAssessment}
                criterionSelfAssessment={criterionSelfAssessment}
                hidePoints={hidePoints}
                isFreeFormCriterionComments={isFreeFormCriterionComments}
                isLastIndex={isLastIndex}
                isPeerReview={isPeerReview}
                isPreviewMode={isPreviewMode}
                onUpdateAssessmentData={onUpdateAssessmentData}
                ratingOrder={ratingOrder}
                ratingsColumnMinWidth={ratingsColumnMinWidth}
                rubricSavedComments={rubricSavedComments?.[criterion.id] ?? []}
                shouldFocusFirstRating={validationErrors?.[0] === criterion.id}
                submissionUser={submissionUser}
                validationErrors={validationErrors}
              />
            )
          })}
        </Table.Body>
      </table>
    </View>
  )
}
