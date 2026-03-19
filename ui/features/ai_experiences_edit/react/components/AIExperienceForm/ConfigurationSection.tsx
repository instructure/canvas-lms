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
}

const ConfigurationSection: React.FC<ConfigurationSectionProps> = ({
  formData,
  onChange,
  showErrors,
  errors,
  contextFiles,
  onContextFilesChange,
  courseId,
}) => {
  return (
    <View as="div" margin="large 0 0 0">
      <View
        as="div"
        background="secondary"
        borderWidth="small"
        borderRadius="medium"
        padding="medium"
      >
        <Heading level="h2" margin="0 0 x-small 0">
          {I18n.t('Configurations')}
        </Heading>
        <View as="div" margin="0 0 large 0">
          <Text size="medium">
            {I18n.t('Define the sourcing, completion rules, and personality of this IgniteAI.')}
          </Text>
        </View>

        {/* Source materials section */}
        <View as="div">
          <Heading level="h3" margin="0 0 xx-small 0">
            {I18n.t('Source materials')}
          </Heading>
          <View as="div" margin="0 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t('Provide IgniteAI with a closed-loop of sources to reference.')}
            </Text>
          </View>
          <FormFieldGroup description="" layout="stacked">
            <TextArea
              data-testid="ai-experience-edit-facts-input"
              label={I18n.t('Text source')}
              value={formData.facts}
              onChange={onChange('facts')}
              required
              placeholder={I18n.t('Copy and paste information, data, key facts, etc.')}
              resize="vertical"
              height="80px"
              maxHeight="300px"
              messages={showErrors && errors.facts ? [{type: 'newError', text: errors.facts}] : []}
            />
          </FormFieldGroup>

          {/* Only render if feature flag is enabled */}
          {(window as any).ENV?.FEATURES?.ai_experiences_context_file_upload && (
            <View as="div" margin="medium 0 0 0">
              <CanvasFileUpload
                files={contextFiles}
                onFilesChange={onContextFilesChange}
                courseId={courseId}
                allowedFileTypes={['.docx', '.xlsx', '.xls', '.pptx', '.pdf', '.txt', '.html']}
                maxFileSizeMB={300}
                maxFiles={10}
              />
            </View>
          )}
        </View>

        {/* Completion rules section */}
        <View as="div" margin="large 0 0 0">
          <Heading level="h3" margin="0 0 xx-small 0">
            {I18n.t('Completion rules')}
          </Heading>
          <View as="div" margin="0 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t(
                'Set the learning objectives that learners need to obtain in order to complete the activity.',
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
              placeholder={I18n.t('Separate by semi-colon or next line.')}
              resize="vertical"
              height="80px"
              maxHeight="300px"
              messages={
                showErrors && errors.learning_objective
                  ? [{type: 'newError', text: errors.learning_objective}]
                  : []
              }
            />
          </FormFieldGroup>
        </View>

        {/* Personality and guidance section */}
        <View as="div" margin="large 0 0 0">
          <Heading level="h3" margin="0 0 xx-small 0">
            {I18n.t('Personality and guidance')}
          </Heading>
          <View as="div" margin="0 0 small 0">
            <Text size="small" color="secondary">
              {I18n.t('Decide the voice and instructional guidance of the IgniteAI.')}
            </Text>
          </View>
          <FormFieldGroup description="" layout="stacked">
            <TextArea
              data-testid="ai-experience-edit-pedagogical-guidance-input"
              label={I18n.t('Customize agent')}
              value={formData.pedagogical_guidance}
              onChange={onChange('pedagogical_guidance')}
              placeholder={I18n.t('Provide your own role or style of IgniteAI')}
              resize="vertical"
              height="80px"
              maxHeight="300px"
              messages={
                showErrors && errors.pedagogical_guidance
                  ? [{type: 'newError', text: errors.pedagogical_guidance}]
                  : []
              }
            />
          </FormFieldGroup>
        </View>
      </View>
    </View>
  )
}

export default ConfigurationSection
