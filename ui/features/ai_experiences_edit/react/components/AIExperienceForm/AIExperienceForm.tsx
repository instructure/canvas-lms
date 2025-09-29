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

import React, {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {AIExperience, AIExperienceFormData} from '../../../types'

const I18n = createI18nScope('ai_experiences_edit')

interface AIExperienceFormProps {
  aiExperience?: AIExperience | null
  onSubmit: (data: AIExperienceFormData) => void
  isLoading: boolean
}

const AIExperienceForm: React.FC<AIExperienceFormProps> = ({aiExperience, onSubmit, isLoading}) => {
  const [formData, setFormData] = useState<AIExperienceFormData>({
    title: '',
    description: '',
    prompt: '',
    learning_objective: '',
    scenario: '',
  })

  useEffect(() => {
    if (aiExperience) {
      setFormData({
        title: aiExperience.title || '',
        description: aiExperience.description || '',
        prompt: aiExperience.prompt || '',
        learning_objective: aiExperience.learning_objective || '',
        scenario: aiExperience.scenario || '',
      })
    }
  }, [aiExperience])

  const handleInputChange =
    (field: keyof AIExperienceFormData) =>
    (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      setFormData(prev => ({
        ...prev,
        [field]: event.target.value,
      }))
    }

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault()
    onSubmit(formData)
  }

  const isEdit = !!aiExperience?.id

  return (
    <View as="div" maxWidth="800px" margin="0 auto">
      <Heading level="h1" margin="0 0 large 0">
        {isEdit ? I18n.t('Edit AI Experience') : I18n.t('Create AI Experience')}
      </Heading>

      <form onSubmit={handleSubmit}>
        <FormFieldGroup description={I18n.t('AI Experience Details')} layout="stacked">
          <TextInput
            renderLabel={I18n.t('Title')}
            value={formData.title}
            onChange={handleInputChange('title')}
            isRequired
            placeholder={I18n.t('Enter the title for your AI experience')}
          />

          <TextArea
            label={I18n.t('Description')}
            value={formData.description}
            onChange={handleInputChange('description')}
            placeholder={I18n.t('Describe the AI experience')}
            resize="vertical"
            height="120px"
          />

          <TextArea
            label={I18n.t('Facts students should know')}
            value={formData.prompt}
            onChange={handleInputChange('prompt')}
            placeholder={I18n.t('List key facts or information students should be aware of')}
            resize="vertical"
            height="120px"
          />

          <TextArea
            label={I18n.t('Learning objectives')}
            value={formData.learning_objective}
            onChange={handleInputChange('learning_objective')}
            placeholder={I18n.t('Define the learning objectives for this experience')}
            resize="vertical"
            height="120px"
          />

          <TextArea
            label={I18n.t('Scenario')}
            value={formData.scenario}
            onChange={handleInputChange('scenario')}
            placeholder={I18n.t('Describe the scenario or context for the AI experience')}
            resize="vertical"
            height="150px"
          />
        </FormFieldGroup>

        <View as="div" margin="large 0 0 0">
          <Button type="submit" color="primary" interaction={isLoading ? 'disabled' : 'enabled'}>
            {isLoading ? I18n.t('Saving...') : I18n.t('Save')}
          </Button>
        </View>
      </form>
    </View>
  )
}

export default AIExperienceForm
