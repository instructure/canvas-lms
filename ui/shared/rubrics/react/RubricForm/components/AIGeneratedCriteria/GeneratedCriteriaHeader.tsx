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
import RegenerateCriteriaButton from './RegenerateCriteriaButton'

const I18n = createI18nScope('rubrics-form-generated-criteria')

type GeneratedCriteriaHeaderProps = {
  aiFeedbackLink?: string
  canRegenerate?: boolean
  isGenerating?: boolean
  onRegenerateAll: (additionalPrompt: string) => void
}
export const GeneratedCriteriaHeader = ({
  aiFeedbackLink,
  canRegenerate = false,
  isGenerating = false,
  onRegenerateAll,
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
      <Flex gap="medium" wrap="wrap">
        <Flex.Item shouldShrink shouldGrow>
          <Heading level="h4">
            <Flex alignItems="center" gap="small">
              <IconAiColoredSolid />
              <Text>{I18n.t('Criteria Auto-Generated')}</Text>
            </Flex>
          </Heading>
        </Flex.Item>
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
          <RegenerateCriteriaButton
            buttonColor="ai-primary"
            disabled={isGenerating || !canRegenerate}
            toolTipText={
              canRegenerate ? '' : I18n.t('There are no criteria available for regeneration')
            }
            onRegenerate={onRegenerateAll}
          />
        </Flex.Item>
      </Flex>
    </View>
  )
}
