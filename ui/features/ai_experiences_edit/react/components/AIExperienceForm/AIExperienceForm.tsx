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
import {Button, CloseButton, IconButton} from '@instructure/ui-buttons'
import {TextInput} from '@instructure/ui-text-input'
import {TextArea} from '@instructure/ui-text-area'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {
  IconAiLine,
  IconArrowOpenDownLine,
  IconMoreLine,
  IconPublishSolid,
} from '@instructure/ui-icons'
import {Menu} from '@instructure/ui-menu'
import {Modal} from '@instructure/ui-modal'
import {Pill} from '@instructure/ui-pill'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {AIExperience, AIExperienceFormData} from '../../../types'

const I18n = createI18nScope('ai_experiences_edit')

interface AIExperienceFormProps {
  aiExperience?: AIExperience | null
  onSubmit: (data: AIExperienceFormData, shouldPreview?: boolean) => void
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
  const [showPreviewModal, setShowPreviewModal] = useState(false)
  const [showDeleteModal, setShowDeleteModal] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)

  useEffect(() => {
    if (aiExperience) {
      setFormData({
        title: aiExperience.title || '',
        description: aiExperience.description || '',
        facts: aiExperience.facts || '',
        learning_objective: aiExperience.learning_objective || '',
        pedagogical_guidance: aiExperience.pedagogical_guidance || '',
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

  const handleCancel = () => {
    if (onCancel) {
      onCancel()
    } else {
      window.history.back()
    }
  }

  const handlePreviewExperience = () => {
    setShowPreviewModal(true)
  }

  const handleConfirmPreview = () => {
    setShowPreviewModal(false)
    // Save as draft first, then redirect to preview
    onSubmit(formData, true)
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
      showFlashSuccess(I18n.t('AI Experience deleted successfully'))()
      window.location.href = `/courses/${courseId}/ai_experiences`
    } catch (_error) {
      showFlashError(I18n.t('Failed to delete AI Experience'))()
      setIsDeleting(false)
      setShowDeleteModal(false)
    }
  }

  const isEdit = !!aiExperience?.id

  return (
    <View as="div" maxWidth="1000px" margin="0 auto" padding="medium">
      <Flex justifyItems="space-between" alignItems="start" margin="0 0 large 0">
        <Heading level="h1" margin="0">
          {isEdit ? I18n.t('Edit AI Experience') : I18n.t('New AI Experience')}
        </Heading>
        <Flex gap="small" alignItems="center">
          <IconPublishSolid color="secondary" />
          <Text color="secondary">{I18n.t('Not published')}</Text>
          <Menu
            placement="bottom end"
            trigger={
              <IconButton
                screenReaderLabel={I18n.t('More options')}
                withBackground={false}
                withBorder={false}
              >
                <IconMoreLine />
              </IconButton>
            }
          >
            <Menu.Item onClick={handleDeleteClick} disabled={!isEdit}>
              {I18n.t('Delete')}
            </Menu.Item>
          </Menu>
        </Flex>
      </Flex>

      <form onSubmit={handleSubmit}>
        <View as="div" margin="0 0 large 0">
          <TextInput
            renderLabel={I18n.t('Title')}
            value={formData.title}
            onChange={handleInputChange('title')}
            isRequired
            placeholder=""
          />
        </View>

        <View as="div" margin="0 0 large 0">
          <TextArea
            label={I18n.t('Description')}
            value={formData.description}
            onChange={handleInputChange('description')}
            required
            placeholder=""
            resize="vertical"
            height="120px"
          />
        </View>

        <View as="div" margin="large 0 0 0">
          <Heading level="h2" margin="0 0 small 0">
            {I18n.t('Configurations')}
          </Heading>

          <View
            as="div"
            borderWidth="small"
            borderColor="primary"
            borderRadius="medium"
            padding="0"
            margin="0"
          >
            <div
              style={{
                background: 'linear-gradient(135deg, #7B5FB3 0%, #5585C7 100%)',
                padding: '1rem',
              }}
            >
              <Flex gap="small" alignItems="center">
                <IconAiLine color="primary-inverse" />
                <View>
                  <Text color="primary-inverse" weight="bold" size="large">
                    {I18n.t('Learning design')}
                  </Text>
                  <br />
                  <Text color="primary-inverse" size="small">
                    {I18n.t('What should students know and how should the AI behave?')}
                  </Text>
                </View>
              </Flex>
            </div>

            <View as="div" padding="medium">
              <FormFieldGroup description="" layout="stacked">
                <TextArea
                  label={I18n.t('Facts students should know')}
                  value={formData.facts}
                  onChange={handleInputChange('facts')}
                  placeholder={I18n.t(
                    'Key facts or details the student is expected to recall (e.g., Wright brothers, 1903, Kitty Hawk).',
                  )}
                  resize="vertical"
                  height="120px"
                />

                <TextArea
                  label={I18n.t('Learning objectives')}
                  value={formData.learning_objective}
                  onChange={handleInputChange('learning_objective')}
                  required
                  placeholder={I18n.t(
                    'What the student should be able to explain or demonstrate after this activity.',
                  )}
                  resize="vertical"
                  height="120px"
                />

                <TextArea
                  label={I18n.t('Pedagogical guidance')}
                  value={formData.pedagogical_guidance}
                  onChange={handleInputChange('pedagogical_guidance')}
                  placeholder={I18n.t(
                    'Describe the role or style of the AI (e.g., friendly guide, strict examiner, storyteller).',
                  )}
                  resize="vertical"
                  height="120px"
                />
              </FormFieldGroup>
            </View>
          </View>
        </View>

        <Flex justifyItems="end" margin="large 0 0 0" gap="small">
          <Button onClick={handleCancel}>{I18n.t('Cancel')}</Button>
          <Menu
            placement="top"
            trigger={<Button renderIcon={<IconArrowOpenDownLine />}>{I18n.t('Preview')}</Button>}
          >
            <Menu.Item onClick={handlePreviewExperience}>{I18n.t('Preview experience')}</Menu.Item>
            <Menu.Item disabled>
              <div
                style={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  gap: '0.5rem',
                  paddingRight: '1rem',
                }}
              >
                <span style={{whiteSpace: 'nowrap'}}>{I18n.t('Run chat simulation')}</span>
                <Pill color="info">{I18n.t('Coming soon')}</Pill>
              </div>
            </Menu.Item>
          </Menu>
          <Button type="submit" color="primary" interaction={isLoading ? 'disabled' : 'enabled'}>
            {isLoading ? I18n.t('Saving...') : I18n.t('Save as draft')}
          </Button>
        </Flex>
      </form>

      <Modal
        open={showPreviewModal}
        onDismiss={() => setShowPreviewModal(false)}
        size="small"
        label={I18n.t('Preview AI experience')}
        shouldCloseOnDocumentClick
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => setShowPreviewModal(false)}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Preview AI experience')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Text>
            {I18n.t(
              'We will save this experience as a draft so you can preview it. Please confirm to proceed.',
            )}
          </Text>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={() => setShowPreviewModal(false)} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button onClick={handleConfirmPreview} color="primary">
            {I18n.t('Confirm')}
          </Button>
        </Modal.Footer>
      </Modal>

      <Modal
        open={showDeleteModal}
        onDismiss={() => setShowDeleteModal(false)}
        size="small"
        label={I18n.t('Delete AI Experience')}
        shouldCloseOnDocumentClick
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => setShowDeleteModal(false)}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Delete AI Experience')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Text>
            {I18n.t('Are you sure you want to delete "%{title}"? This action cannot be undone.', {
              title: formData.title || I18n.t('this AI experience'),
            })}
          </Text>
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={() => setShowDeleteModal(false)} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button
            onClick={handleConfirmDelete}
            color="danger"
            interaction={isDeleting ? 'disabled' : 'enabled'}
          >
            {isDeleting ? I18n.t('Deleting...') : I18n.t('Delete')}
          </Button>
        </Modal.Footer>
      </Modal>
    </View>
  )
}

export default AIExperienceForm
