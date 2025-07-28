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
import {colors} from '@instructure/canvas-theme'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {possibleString} from '../Points'

const I18n = createI18nScope('rubrics-assessment')

type InstructorScoreProps = {
  instructorPoints: number
  isPeerReview: boolean
  isPreviewMode: boolean
}
export const InstructorScore = ({
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
            backgroundColor: '#F2F4F4',
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
            backgroundColor: isPreviewMode ? colors.contrasts.grey4570 : colors.contrasts.green4570,
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
