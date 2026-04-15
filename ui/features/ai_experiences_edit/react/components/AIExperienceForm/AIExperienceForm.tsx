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

import React, {useState, useEffect, useMemo} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@instructure/platform-alerts'
import {AIExperience, AIExperienceFormData} from '../../../types'
import DeleteConfirmationModal from './DeleteConfirmationModal'
import FormHeader from './FormHeader'
import ConfigurationSection from './ConfigurationSection'
import FormActions from './FormActions'
import type {ContextFile} from '@canvas/canvas-file-upload/react/types'

const I18n = createI18nScope('ai_experiences_edit')

interface AIExperienceFormProps {
  aiExperience?: AIExperience | null
  onSubmit: (data: AIExperienceFormData) => void
  isLoading: boolean
  onCancel?: () => void
}

const AIExperienceForm: React.FC<AIExperienceFormProps> = ({
  aiExperience,
  onSubmit,
  isLoading,
  onCancel,
}) => {
  const [formData, setFormData] = useState<AIExperienceFormData>({
    title: '',
    description: '',
    facts: '',
    learning_objective: '',
    pedagogical_guidance: '',
  })
  const [contextFiles, setContextFiles] = useState<ContextFile[]>([])
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [showErrors, setShowErrors] = useState(false)
  const [showErrorBanner, setShowErrorBanner] = useState(false)

  useEffect(() => {
    if (aiExperience) {
      setFormData({
        title: aiExperience.title || '',
        description: aiExperience.description || '',
        facts: aiExperience.facts || '',
        learning_objective: aiExperience.learning_objective || '',
        pedagogical_guidance: aiExperience.pedagogical_guidance || '',
      })
      if (aiExperience.context_files) {
        setContextFiles(aiExperience.context_files as ContextFile[])
      }
    }
  }, [aiExperience])

  const handleInputChange =
    (field: keyof AIExperienceFormData) =>
    (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
      setFormData(prev => ({
        ...prev,
        [field]: event.target.value,
      }))
      // Clear error for this field when user starts typing
      if (errors[field]) {
        setErrors(prev => {
          const newErrors = {...prev}
          delete newErrors[field]
          return newErrors
        })
        // Hide error banner if no errors remain
        if (Object.keys(errors).length === 1) {
          setShowErrorBanner(false)
        }
      }
    }

  const handleContextFilesChange = (files: ContextFile[]) => {
    setContextFiles(files)
  }

  const validateForm = (): Record<string, string> => {
    const newErrors: Record<string, string> = {}

    if (!formData.title.trim()) {
      newErrors.title = I18n.t('Knowledge chat name required')
    }

    if (!formData.facts.trim()) {
      newErrors.facts = I18n.t('Please provide facts students should know')
    }

    if (!formData.learning_objective.trim()) {
      newErrors.learning_objective = I18n.t('Please provide at least one learning objective')
    }

    if (!formData.pedagogical_guidance.trim()) {
      newErrors.pedagogical_guidance = I18n.t('Please provide pedagogical guidance')
    }

    return newErrors
  }

  const handleSubmit = (event: React.FormEvent) => {
    event.preventDefault()

    const validationErrors = validateForm()
    setErrors(validationErrors)

    if (Object.keys(validationErrors).length > 0) {
      setShowErrors(true)
      setShowErrorBanner(true)
      return
    }

    const dataToSubmit: AIExperienceFormData = {
      ...formData,
      context_file_ids: contextFiles.map(f => f.id),
    }
    onSubmit(dataToSubmit)
  }

  const handleCancel = () => {
    if (onCancel) {
      onCancel()
    } else {
      window.history.back()
    }
  }

  const handleDeleteClick = () => {
    if (isEdit) {
      setShowDeleteModal(true)
    }
  }

  const handleConfirmDelete = async () => {
    if (!aiExperience?.id) return

    setIsDeleting(true)
    try {
      const courseId = (window as any).ENV?.COURSE_ID
      await doFetchApi({
        path: `/api/v1/courses/${courseId}/ai_experiences/${aiExperience.id}`,
        method: 'DELETE',
      })
      showFlashSuccess(I18n.t('Knowledge Chat deleted successfully'))()
      window.location.href = `/courses/${courseId}/ai_experiences`
    } catch (error: any) {
      const errorMessage =
        error?.message || I18n.t('An error occurred while deleting the Knowledge Chat')
      showFlashError(I18n.t('Failed to delete Knowledge Chat: %{error}', {error: errorMessage}))()
      setIsDeleting(false)
      setShowDeleteModal(false)
    }
  }

  const isEdit = useMemo(() => !!aiExperience?.id, [aiExperience?.id])

  return (
    <View as="div" maxWidth="1000px" margin="0 auto" padding="medium">
      {aiExperience?.failed_context_file_names?.length && (
        <Alert
          variant="error"
          renderCloseButtonLabel={false}
          margin="0 0 medium 0"
          data-testid="ai-experience-edit-index-failed-notice"
        >
          {I18n.t(
            "Activity couldn't be loaded. A source file has an issue. To try again, remove %{names} from your configurations.",
            {names: aiExperience.failed_context_file_names.join(', ')},
          )}
        </Alert>
      )}

      {showErrorBanner && showErrors && Object.keys(errors).length > 0 && (
        <Alert
          variant="error"
          renderCloseButtonLabel={I18n.t('Close')}
          onDismiss={() => setShowErrorBanner(false)}
          margin="0 0 medium 0"
        >
          {I18n.t(
            'Some required information is missing. Please complete all highlighted fields before saving.',
          )}
        </Alert>
      )}

      <FormHeader isEdit={isEdit} title={aiExperience?.title} onDeleteClick={handleDeleteClick} />

      <form onSubmit={handleSubmit} noValidate={true}>
        <View as="div" margin="0 0 large 0">
          <TextInput
            data-testid="ai-experience-edit-title-input"
            renderLabel={I18n.t('Knowledge chat name')}
            value={formData.title}
            onChange={handleInputChange('title')}
            isRequired
            messages={showErrors && errors.title ? [{type: 'newError', text: errors.title}] : []}
          />
        </View>

        <View as="div" margin="0 0 large 0">
          <TextArea
            data-testid="ai-experience-edit-description-input"
            label={I18n.t('Knowledge chat description')}
            value={formData.description}
            onChange={handleInputChange('description')}
            resize="vertical"
            height="120px"
          />
        </View>

        <ConfigurationSection
          formData={formData}
          onChange={handleInputChange}
          showErrors={showErrors}
          errors={errors}
          contextFiles={contextFiles}
          onContextFilesChange={handleContextFilesChange}
          courseId={((window as any).ENV?.COURSE_ID || '').toString()}
          initialFailedFileNames={aiExperience?.failed_context_file_names}
        />

        <FormActions isLoading={isLoading} onCancel={handleCancel} />
      </form>

      <DeleteConfirmationModal
        open={showDeleteModal}
        onDismiss={() => setShowDeleteModal(false)}
        onConfirm={handleConfirmDelete}
        title={formData.title}
        isDeleting={isDeleting}
      />
    </View>
  )
}

export default AIExperienceForm
