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

import {useScope as createI18nScope} from '@canvas/i18n'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {possibleStringValue} from '../../Points'

const I18n = createI18nScope('rubrics-form')

type CriteriaBuilderHeaderProps = {
  hidePoints: boolean
  hideScoreTotal: boolean
  isAIRubricsAvailable: boolean
  pointsPossible: number
  rubricId?: string
}
export const CriteriaBuilderHeader = ({
  hidePoints,
  hideScoreTotal,
  isAIRubricsAvailable,
  rubricId,
  pointsPossible,
}: CriteriaBuilderHeaderProps) => {
  return (
    <View as="div" margin="large 0 small 0">
      <Flex>
        <Flex.Item shouldGrow={true}>
          <Heading
            level="h2"
            as="h2"
            data-testid="rubric-criteria-builder-header"
            themeOverride={{h2FontWeight: 700, h2FontSize: '22px', lineHeight: '1.75rem'}}
          >
            {isAIRubricsAvailable ? I18n.t('Rubric Generator') : I18n.t('Criteria Builder')}
          </Heading>
        </Flex.Item>
        {!hidePoints && !hideScoreTotal && (
          <Flex.Item>
            <Heading
              level="h2"
              as="h2"
              data-testid={`rubric-points-possible-${rubricId}`}
              themeOverride={{h2FontWeight: 700, h2FontSize: '22px', lineHeight: '1.75rem'}}
            >
              {I18n.t('%{pointsPossible} Points Possible', {
                pointsPossible: possibleStringValue(pointsPossible),
              })}
            </Heading>
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}
