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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'

const I18n = createI18nScope('rubrics-assessment')

type SelfAssessmentInstructorScoreProps = {
  instructorPoints?: number
  pointsPossible?: number
}
export const SelfAssessmentInstructorScore = ({
  instructorPoints,
  pointsPossible = 0,
}: SelfAssessmentInstructorScoreProps) => {
  return (
    <Flex>
      <Flex.Item shouldGrow={true} align="center" margin="0 0 0 small">
        <Text size="medium" weight="bold">
          {I18n.t('Self-Assessment Score')}
        </Text>
      </Flex.Item>
      <Flex.Item>
        <div
          style={{
            padding: '9px 25px',
            backgroundColor: '#F3F9F6',
            border: '2px dashed #03893D',
            borderRadius: '4px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
          }}
        >
          <Text weight="bold" data-testid="rubric-self-assessment-instructor-score">
            <Text size="medium">{`${instructorPoints || '--'}/`}</Text>
            <Text size="small">{pointsPossible}</Text>
          </Text>
        </div>
      </Flex.Item>
    </Flex>
  )
}
