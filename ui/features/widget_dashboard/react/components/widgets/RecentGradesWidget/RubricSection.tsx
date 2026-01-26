/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import type {RubricAssessment} from '../../../types'

const I18n = createI18nScope('widget_dashboard')

interface RubricSectionProps {
  rubricAssessment: RubricAssessment | null
  submissionId: string
}

export const RubricSection: React.FC<RubricSectionProps> = ({rubricAssessment, submissionId}) => {
  if (!rubricAssessment) {
    return null
  }

  const {assessmentRatings} = rubricAssessment

  if (assessmentRatings.length === 0) {
    return null
  }

  return (
    <View as="div" data-testid={`rubric-section-${submissionId}`}>
      <Flex direction="column">
        <Flex.Item>
          <Text weight="bold" size="large" data-testid={`rubric-section-heading-${submissionId}`}>
            {I18n.t('Rubric')}
          </Text>
        </Flex.Item>
        {assessmentRatings.map(rating => {
          const criterion = rating.criterion
          if (!criterion) return null

          return (
            <Flex.Item key={rating._id || criterion._id}>
              <View as="div" padding="x-small 0">
                <Flex direction="column">
                  <Flex.Item>
                    <Flex direction="row" gap="xx-small">
                      <Flex.Item>
                        <Text
                          weight="bold"
                          size="small"
                          data-testid={`rubric-criterion-description-${criterion._id}`}
                        >
                          {criterion.description || I18n.t('Criterion')}
                        </Text>
                      </Flex.Item>
                      <Flex.Item>
                        <Text
                          weight="bold"
                          size="small"
                          data-testid={`rubric-criterion-points-${criterion._id}`}
                        >
                          {rating.points !== null && criterion.points !== null
                            ? I18n.t('%{earned}/%{possible} pts', {
                                earned: rating.points,
                                possible: criterion.points,
                              })
                            : I18n.t('N/A')}
                        </Text>
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>
                  {rating.comments && (
                    <Flex.Item>
                      <Text size="small" data-testid={`rubric-rating-comments-${criterion._id}`}>
                        {rating.comments}
                      </Text>
                    </Flex.Item>
                  )}
                </Flex>
              </View>
            </Flex.Item>
          )
        })}
      </Flex>
    </View>
  )
}
