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
import {Text} from '@instructure/ui-text'
import {AIExperienceFormData} from '../../../types'
import CanvasFileUpload from '@canvas/canvas-file-upload/react/CanvasFileUpload'
import type {ContextFile} from '@canvas/canvas-file-upload/react/types'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {
  lightBlueButtonTheme,
  navyButtonTheme,
} from '../../../../../shared/ai-experiences/react/brand'

declare const ENV: GlobalEnv & {
  FEATURES?: {ai_experiences_context_file_upload?: boolean}
  CONTEXT_FILE_MAX_SIZE_MB?: number
}

const I18n = createI18nScope('ai_experiences_edit')

interface ConfigurationSectionProps {
  formData: AIExperienceFormData
  onChange: (
    field: keyof AIExperienceFormData,
  ) => (event: React.ChangeEvent<HTMLTextAreaElement>) => void
  showErrors: boolean
  errors: Record<string, string>
  contextFiles: ContextFile[]
  onContextFilesChange: (files: ContextFile[]) => void
  courseId: string
  initialFailedFileNames?: string[]
}

const ConfigurationSection: React.FC<ConfigurationSectionProps> = ({
  formData,
  onChange,
  showErrors,
  errors,
  contextFiles,
  onContextFilesChange,
  courseId,
  initialFailedFileNames,
}) => {
  return (
    <View as="div" margin="large 0 0 0">
      <View
        as="div"
        background="primary"
        borderWidth="small"
        borderRadius="medium"
        padding="medium"
      >
        <Heading level="h2" margin="0 0 x-small 0">
          <strong>{I18n.t('Configurations')}</strong>
        </Heading>
        <View as="div" margin="0 0 large 0">
          <Text size="medium">
            {I18n.t(
              'Define the completion rules, pedagogical guidance, and sources of the large language model (LLM).',
            )}
          </Text>
        </View>

        {/* Completion rules section */}
        <View as="div">
          <Heading level="h3" margin="0 0 xx-small 0">
            <strong>{I18n.t('Completion rules')}</strong>
          </Heading>
          <View as="div" margin="0 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t(
                'Set the learning objectives that learners need to cover in order to complete the activity.',
              )}
            </Text>
          </View>
          <FormFieldGroup description="" layout="stacked">
            <TextArea
              data-testid="ai-experience-edit-learning-objective-input"
              label={I18n.t('Learning objective targets')}
              value={formData.learning_objective}
              onChange={onChange('learning_objective')}
              required
              resize="vertical"
              height="80px"
              maxHeight="300px"
              messages={[
                ...(showErrors && errors.learning_objective
                  ? [{type: 'newError' as const, text: errors.learning_objective}]
                  : []),
                {
                  type: 'hint' as const,
                  text: I18n.t(
                    'Add a learning objective on a new line or separate by semi-colon (;).',
                  ),
                },
              ]}
            />
          </FormFieldGroup>
        </View>

        {/* Pedagogical activity guidance section */}
        <View as="div" margin="large 0 0 0">
          <Heading level="h3" margin="0 0 xx-small 0">
            <strong>{I18n.t('Pedagogical activity guidance')}</strong>
          </Heading>
          <View as="div" margin="0 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t('Define the instructions for the activity.')}
            </Text>
          </View>
          <FormFieldGroup description="" layout="stacked">
            <TextArea
              data-testid="ai-experience-edit-pedagogical-guidance-input"
              label={I18n.t('Pedagogical guidance')}
              value={formData.pedagogical_guidance}
              onChange={onChange('pedagogical_guidance')}
              resize="vertical"
              height="80px"
              maxHeight="300px"
              messages={[
                ...(showErrors && errors.pedagogical_guidance
                  ? [{type: 'newError' as const, text: errors.pedagogical_guidance}]
                  : []),
                {
                  type: 'hint' as const,
                  text: I18n.t(
                    'Provide us a prompt that tells the LLM (language learning model) how to facilitate the activity.',
                  ),
                },
              ]}
            />
          </FormFieldGroup>
        </View>

        {/* Source materials section */}
        <View as="div" margin="large 0 0 0">
          <Heading level="h3" margin="0 0 xx-small 0">
            <strong>{I18n.t('Source materials')}</strong>
          </Heading>
          <View as="div" margin="0 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t('Provide sources for the LLM to reference.')}
            </Text>
          </View>
          <FormFieldGroup description="" layout="stacked">
            <TextArea
              data-testid="ai-experience-edit-facts-input"
              label={I18n.t('Text source')}
              value={formData.facts}
              onChange={onChange('facts')}
              required
              resize="vertical"
              height="80px"
              maxHeight="300px"
              messages={[
                ...(showErrors && errors.facts
                  ? [{type: 'newError' as const, text: errors.facts}]
                  : []),
                {
                  type: 'hint' as const,
                  text: I18n.t('Copy and paste information, data, key facts, etc.'),
                },
              ]}
            />
          </FormFieldGroup>

          {/* Only render if feature flag is enabled */}
          {ENV?.FEATURES?.ai_experiences_context_file_upload && (
            <View as="div" margin="medium 0 0 0">
              <CanvasFileUpload
                files={contextFiles}
                onFilesChange={onContextFilesChange}
                courseId={courseId}
                allowedFileTypes={['.docx', '.xlsx', '.xls', '.pptx', '.pdf', '.txt', '.html']}
                maxFileSizeMB={ENV?.CONTEXT_FILE_MAX_SIZE_MB ?? 300}
                maxFiles={10}
                initialFailedFileNames={initialFailedFileNames}
                primaryButtonThemeOverride={navyButtonTheme}
                secondaryButtonThemeOverride={lightBlueButtonTheme}
              />
            </View>
          )}
        </View>
      </View>
    </View>
  )
}

export default ConfigurationSection
