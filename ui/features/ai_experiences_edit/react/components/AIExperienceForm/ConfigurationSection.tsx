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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {IconAiLine} from '@instructure/ui-icons'
import {AIExperienceFormData} from '../../../types'

const I18n = createI18nScope('ai_experiences_edit')

interface ConfigurationSectionProps {
  formData: AIExperienceFormData
  onChange: (
    field: keyof AIExperienceFormData,
  ) => (event: React.ChangeEvent<HTMLTextAreaElement>) => void
  showErrors: boolean
  errors: Record<string, string>
}

const ConfigurationSection: React.FC<ConfigurationSectionProps> = ({
  formData,
  onChange,
  showErrors,
  errors,
}) => {
  return (
    <View as="div" margin="large 0 0 0">
      <Heading level="h2" margin="0 0 small 0">
        {I18n.t('Configurations')}
      </Heading>

      <div
        style={{
          border: '3px solid',
          borderImage: 'linear-gradient(135deg, #7B5FB3 0%, #5585C7 100%) 1',
          borderRadius: '0.25rem',
          overflow: 'hidden',
        }}
      >
        <div
          style={{
            background: 'linear-gradient(135deg, #7B5FB3 0%, #5585C7 100%)',
            padding: '1rem',
          }}
        >
          <Flex alignItems="center">
            <Flex.Item padding="0 x-small 0 0">
              <IconAiLine color="primary-inverse" />
            </Flex.Item>
            <Flex.Item>
              <View>
                <View as="div" margin="0 0 xx-small 0">
                  <Text color="primary-inverse" weight="bold" size="large">
                    {I18n.t('Learning design')}
                  </Text>
                </View>
                <Text color="primary-inverse" size="small">
                  {I18n.t('What should students know and how should the AI behave?')}
                </Text>
              </View>
            </Flex.Item>
          </Flex>
        </div>

        <div style={{padding: '1rem'}}>
          <FormFieldGroup description="" layout="stacked">
            <TextArea
              data-testid="ai-experience-edit-facts-input"
              label={I18n.t('Facts students should know')}
              value={formData.facts}
              onChange={onChange('facts')}
              placeholder={I18n.t(
                'Key facts or details the student is expected to recall (e.g., Wright brothers, 1903, Kitty Hawk).',
              )}
              resize="vertical"
              height="120px"
            />

            <TextArea
              data-testid="ai-experience-edit-learning-objective-input"
              label={I18n.t('Learning objectives')}
              value={formData.learning_objective}
              onChange={onChange('learning_objective')}
              required
              placeholder={I18n.t(
                'Enter each objective on a new line or separated by semicolons.\nExample:\n- Understand photosynthesis\n- Explain cellular respiration\n- Describe ATP production',
              )}
              resize="vertical"
              height="120px"
              messages={
                showErrors && errors.learning_objective
                  ? [{type: 'newError', text: errors.learning_objective}]
                  : []
              }
            />

            <TextArea
              data-testid="ai-experience-edit-pedagogical-guidance-input"
              label={I18n.t('Pedagogical guidance')}
              value={formData.pedagogical_guidance}
              onChange={onChange('pedagogical_guidance')}
              required
              placeholder={I18n.t(
                'Describe the role or style of the AI (e.g., friendly guide, strict examiner, storyteller).',
              )}
              resize="vertical"
              height="120px"
              messages={
                showErrors && errors.pedagogical_guidance
                  ? [{type: 'newError', text: errors.pedagogical_guidance}]
                  : []
              }
            />
          </FormFieldGroup>
        </div>
      </div>
    </View>
  )
}

export default ConfigurationSection
