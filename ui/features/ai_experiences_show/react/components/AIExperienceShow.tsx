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

import React, {useState, useEffect, useRef} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconAiLine, IconMoreLine} from '@instructure/ui-icons'
import {IconButton, Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Modal} from '@instructure/ui-modal'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@canvas/alerts/react/FlashAlert'
import {AIExperience} from '../../types'
import LLMConversationView from '../../../../shared/ai-experiences/react/components/LLMConversationView'
import AIExperiencePublishButton from './AIExperiencePublishButton'

const I18n = createI18nScope('ai_experiences_show')

interface AIExperienceShowProps {
  aiExperience: AIExperience
}

const AIExperienceShow: React.FC<AIExperienceShowProps> = ({aiExperience}) => {
  const canManage = aiExperience.can_manage
  const [workflowState, setWorkflowState] = useState(aiExperience.workflow_state)
  const [isPreviewExpanded, setIsPreviewExpanded] = useState(() => {
    const params = new URLSearchParams(window.location.search)
    const shouldPreview = params.get('preview') === 'true'
    // Clean up URL parameter after reading it
    if (shouldPreview) {
      window.history.replaceState({}, '', window.location.pathname)
    }
    return shouldPreview
  })
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false)
  const [isDeleting, setIsDeleting] = useState(false)
  const previewCardRef = useRef<HTMLElement>(null)

  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.get('preview') === 'true') {
      setIsPreviewExpanded(true)
    }
  }, [])

  const handleEdit = () => {
    window.location.href = `/courses/${aiExperience.course_id}/ai_experiences/${aiExperience.id}/edit`
  }

  const handleDelete = async () => {
    setIsDeleting(true)
    try {
      await doFetchApi({
        path: `/api/v1/courses/${aiExperience.course_id}/ai_experiences/${aiExperience.id}`,
        method: 'DELETE',
      })
      showFlashSuccess(I18n.t('AI Experience deleted successfully'))()
      window.location.href = `/courses/${aiExperience.course_id}/ai_experiences`
    } catch (_error) {
      showFlashError(I18n.t('Failed to delete AI Experience'))()
      setIsDeleting(false)
      setIsDeleteModalOpen(false)
    }
  }

  return (
    <View as="div" maxWidth="1080px" margin="0 auto" padding="medium">
      <Flex justifyItems="space-between" alignItems="start">
        <Flex.Item shouldGrow shouldShrink>
          <Heading level="h1" margin="0 0 large 0">
            {aiExperience.title}
          </Heading>
        </Flex.Item>
        {canManage && (
          <Flex.Item>
            <Flex gap="small">
              <Flex.Item>
                <AIExperiencePublishButton
                  experienceId={aiExperience.id!}
                  courseId={aiExperience.course_id!}
                  isPublished={workflowState === 'published'}
                  canUnpublish={aiExperience.can_unpublish ?? true}
                  onPublishChange={setWorkflowState}
                />
              </Flex.Item>
              <Flex.Item>
                <Button
                  color="primary"
                  href={`/courses/${aiExperience.course_id}/ai_experiences/${aiExperience.id}/ai_conversations`}
                  data-testid="ai-experience-show-ai-conversations-button"
                >
                  {I18n.t('AI Conversations')}
                </Button>
              </Flex.Item>
              <Flex.Item>
                <Menu
                  placement="bottom end"
                  trigger={
                    <IconButton
                      screenReaderLabel={I18n.t('AI Experience settings')}
                      withBackground={false}
                      withBorder={false}
                    >
                      <IconMoreLine />
                    </IconButton>
                  }
                >
                  <Menu.Item data-testid="ai-experience-show-edit-menu-item" onSelect={handleEdit}>
                    {I18n.t('Edit')}
                  </Menu.Item>
                  <Menu.Item
                    data-testid="ai-experience-show-run-chat-simulation-menu-item"
                    disabled={true}
                  >
                    <Flex justifyItems="space-between" gap="small">
                      <Flex.Item>
                        <Text>{I18n.t('Run chat simulation')}</Text>
                      </Flex.Item>
                      <Flex.Item>
                        <Text size="small" color="secondary">
                          {I18n.t('Coming soon')}
                        </Text>
                      </Flex.Item>
                    </Flex>
                  </Menu.Item>
                  <Menu.Item
                    data-testid="ai-experience-show-delete-menu-item"
                    onSelect={() => setIsDeleteModalOpen(true)}
                  >
                    {I18n.t('Delete')}
                  </Menu.Item>
                </Menu>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        )}
      </Flex>

      {aiExperience.description && (
        <View as="div" margin="0 0 medium 0">
          <Text data-testid="ai-experience-show-description-text">{aiExperience.description}</Text>
        </View>
      )}

      <Heading level="h2" margin="large 0 small 0">
        {I18n.t('Experience')}
      </Heading>

      <LLMConversationView
        isOpen={true}
        onClose={() => setIsPreviewExpanded(false)}
        returnFocusRef={previewCardRef}
        courseId={aiExperience.course_id}
        aiExperienceId={aiExperience.id}
        aiExperienceTitle={aiExperience.title}
        facts={aiExperience.facts}
        learningObjectives={aiExperience.learning_objective}
        scenario={aiExperience.pedagogical_guidance}
        isExpanded={isPreviewExpanded}
        onToggleExpanded={() => setIsPreviewExpanded(!isPreviewExpanded)}
        isTeacherPreview={canManage}
      />

      <Heading level="h2" margin="large 0 0 0">
        {I18n.t('Configurations')}
      </Heading>

      <div
        style={{
          margin: '0.75rem 0 0 0',
          borderRadius: '0.5rem',
          overflow: 'hidden',
          border: '3px solid transparent',
          backgroundImage:
            'linear-gradient(white, white), linear-gradient(90deg, rgb(106, 90, 205) 0%, rgb(70, 130, 180) 100%)',
          backgroundOrigin: 'border-box',
          backgroundClip: 'padding-box, border-box',
        }}
      >
        <div
          style={{
            padding: '1rem',
            background: 'linear-gradient(90deg, rgb(106, 90, 205) 0%, rgb(70, 130, 180) 100%)',
          }}
        >
          <Flex gap="small" alignItems="start">
            <Flex.Item>
              <IconAiLine color="primary-inverse" size="small" />
            </Flex.Item>
            <Flex.Item shouldGrow shouldShrink>
              <View>
                <Text color="primary-inverse" weight="bold" size="large">
                  {I18n.t('Learning design')}
                </Text>
                <View as="div" margin="xx-small 0 0 0">
                  <Text color="primary-inverse" size="small">
                    {I18n.t('What should students know and how should the AI behave?')}
                  </Text>
                </View>
              </View>
            </Flex.Item>
          </Flex>
        </div>

        <View as="div" padding="medium" background="primary">
          {aiExperience.facts && (
            <View as="div" margin="0 0 medium 0">
              <Heading level="h3" margin="0 0 small 0">
                {I18n.t('Facts students should know')}
              </Heading>
              <Text data-testid="ai-experience-show-facts-text">{aiExperience.facts}</Text>
            </View>
          )}

          {aiExperience.learning_objective && (
            <View as="div" margin="0 0 medium 0">
              <Heading level="h3" margin="0 0 small 0">
                {I18n.t('Learning objectives')}
              </Heading>
              <Text data-testid="ai-experience-show-learning-objectives-text">
                {aiExperience.learning_objective}
              </Text>
            </View>
          )}

          {aiExperience.pedagogical_guidance && (
            <View as="div" margin="0 0 0 0">
              <Heading level="h3" margin="0 0 small 0">
                {I18n.t('Pedagogical guidance')}
              </Heading>
              <Text data-testid="ai-experience-show-pedagogical-guidance-text">
                {aiExperience.pedagogical_guidance}
              </Text>
            </View>
          )}
        </View>
      </div>

      <Modal
        open={isDeleteModalOpen}
        onDismiss={() => setIsDeleteModalOpen(false)}
        size="small"
        label={I18n.t('Delete AI Experience')}
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          <Heading>{I18n.t('Delete AI Experience')}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Text>
            {I18n.t('Are you sure you want to delete "%{title}"? This action cannot be undone.', {
              title: aiExperience.title,
            })}
          </Text>
        </Modal.Body>
        <Modal.Footer>
          <Button
            data-testid="ai-experience-show-delete-cancel-button"
            onClick={() => setIsDeleteModalOpen(false)}
            margin="0 small 0 0"
          >
            {I18n.t('Cancel')}
          </Button>
          <Button
            data-testid="ai-experience-show-delete-confirm-button"
            onClick={handleDelete}
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

export default AIExperienceShow
