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

import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconAiColoredSolid} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import RegenerateCriteria from './RegenerateCriteria'

const I18n = createI18nScope('rubrics-form-generated-criteria')

type GeneratedCriteriaHeaderProps = {
  aiFeedbackLink?: string
  onRegenerateAll: (additionalPrompt: string) => void
  isGenerating?: boolean
}
export const GeneratedCriteriaHeader = ({
  aiFeedbackLink,
  onRegenerateAll,
  isGenerating = false,
}: GeneratedCriteriaHeaderProps) => {
  return (
    <View
      as="div"
      margin="medium 0 small 0"
      padding="small"
      borderRadius="medium"
      background="secondary"
      data-testid="generate-criteria-header"
    >
      <Flex gap="medium">
        <Flex.Item>
          <Heading level="h4">
            <Flex alignItems="center" gap="small">
              <IconAiColoredSolid />
              <Text>{I18n.t('Criteria Auto-Generated')}</Text>
            </Flex>
          </Heading>
        </Flex.Item>
        <Flex.Item shouldGrow={true}></Flex.Item>
        <Flex.Item>
          <Flex gap="small">
            {aiFeedbackLink && (
              <Flex.Item>
                <a
                  data-testid="give-feedback-link"
                  href={aiFeedbackLink}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {I18n.t('Give Feedback')}
                </a>
              </Flex.Item>
            )}
            <Flex.Item>
              <RegenerateCriteria
                buttonColor="ai-primary"
                disabled={isGenerating}
                onRegenerate={onRegenerateAll}
              />
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </View>
  )
}
