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

import React, {useState, useRef} from 'react'
import {InstUISettingsProvider} from '@instructure/emotion'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'
import {IconMoreLine, IconClockLine} from '@instructure/ui-icons'
import {IconButton, Button} from '@instructure/ui-buttons'
import {Alert} from '@instructure/ui-alerts'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

declare const ENV: GlobalEnv & {
  FEATURES?: {ai_experiences_context_file_upload?: boolean}
}
import {Menu} from '@instructure/ui-menu'
import {Modal} from '@instructure/ui-modal'
import {Tooltip} from '@instructure/ui-tooltip'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashSuccess, showFlashError} from '@instructure/platform-alerts'
import {AIExperience} from '../../types'
import {FileList} from '@canvas/canvas-file-upload/react/FileList'
import LLMConversationView from '../../../../shared/ai-experiences/react/components/LLMConversationView'
import AIExperiencePublishButton from './AIExperiencePublishButton'
import {roundedTheme} from '../../../../shared/ai-experiences/react/brand'

const I18n = createI18nScope('ai_experiences_show')

interface AIExperienceShowProps {
  aiExperience: AIExperience
}

const AIExperienceShow: React.FC<AIExperienceShowProps> = ({aiExperience}) => {
  const canManage = aiExperience.can_manage
  const indexStatus = aiExperience.context_index_status
  const isIndexing = indexStatus === 'in_progress'
  const isIndexFailed = indexStatus === 'failed'
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
      showFlashSuccess(I18n.t('Knowledge Chat deleted successfully'))()
      window.location.href = `/courses/${aiExperience.course_id}/ai_experiences`
    } catch (_error) {
      showFlashError(I18n.t('Failed to delete Knowledge Chat'))()
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
                  contextReady={aiExperience.context_ready ?? true}
                  indexFailed={isIndexFailed}
                  onPublishChange={setWorkflowState}
                />
              </Flex.Item>
              <Flex.Item>
                {isIndexing || isIndexFailed ? (
                  <Tooltip
                    renderTip={
                      isIndexFailed
                        ? I18n.t('A source file failed to process')
                        : I18n.t('Source files are still being processed')
                    }
                    on={['hover', 'focus']}
                  >
                    <Button
                      color="primary"
                      interaction="disabled"
                      data-testid="ai-experience-show-ai-conversations-button"
                    >
                      {I18n.t('Conversations')}
                    </Button>
                  </Tooltip>
                ) : (
                  <Button
                    color="primary"
                    href={`/courses/${aiExperience.course_id}/ai_experiences/${aiExperience.id}/ai_conversations`}
                    data-testid="ai-experience-show-ai-conversations-button"
                  >
                    {I18n.t('Conversations')}
                  </Button>
                )}
              </Flex.Item>
              <Flex.Item>
                <Menu
                  placement="bottom end"
                  trigger={
                    <IconButton
                      screenReaderLabel={I18n.t('Knowledge Chat settings')}
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
          <Text data-testid="ai-experience-show-description-text">
            <span style={{whiteSpace: 'pre-wrap'}}>{aiExperience.description}</span>
          </Text>
        </View>
      )}

      {aiExperience.learning_objective && !canManage && (
        <View as="div" margin="large 0">
          <Heading level="h2" margin="0 0 small 0">
            {I18n.t('Learning Objectives')}
          </Heading>
          <View
            as="div"
            padding="medium"
            background="primary"
            borderWidth="small"
            borderRadius="medium"
          >
            <Text size="medium" data-testid="ai-experience-show-student-goals-text">
              <span style={{whiteSpace: 'pre-wrap'}}>{aiExperience.learning_objective}</span>
            </Text>
          </View>
        </View>
      )}

      {canManage && isIndexFailed ? (
        <Alert
          variant="error"
          renderCloseButtonLabel={false}
          data-testid="ai-experience-show-index-failed-notice"
        >
          {I18n.t(
            "Activity couldn't be loaded. A source file has an issue. To try again, remove %{names} from ",
            {
              names: aiExperience.failed_context_file_names?.length
                ? aiExperience.failed_context_file_names.join(', ')
                : I18n.t('the file'),
            },
          )}
          <a
            href={`/courses/${aiExperience.course_id}/ai_experiences/${aiExperience.id}/edit`}
            data-testid="ai-experience-show-index-failed-edit-button"
          >
            {I18n.t('your configurations')}
          </a>
          {I18n.t('.')}
        </Alert>
      ) : canManage && isIndexing ? (
        <View
          as="div"
          padding="large"
          background="secondary"
          borderWidth="small"
          borderRadius="medium"
          textAlign="center"
          data-testid="ai-experience-show-indexing-notice"
        >
          <Flex direction="column" alignItems="center" gap="small">
            <Flex.Item>
              <IconClockLine size="medium" color="secondary" />
            </Flex.Item>
            <Flex.Item>
              <Text weight="bold">{I18n.t('Source files are still being processed')}</Text>
            </Flex.Item>
            <Flex.Item>
              <Text color="secondary">
                {I18n.t(
                  'Preview and Conversations will be available once processing is complete. Check back later.',
                )}
              </Text>
            </Flex.Item>
          </Flex>
        </View>
      ) : (
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
      )}

      {canManage && (
        <>
          <InstUISettingsProvider theme={roundedTheme}>
            <View
              as="div"
              margin="large 0 0 0"
              borderWidth="small"
              borderRadius="medium"
              background="primary"
              padding="medium"
            >
              <View as="div" margin="0 0 medium 0">
                <Heading level="h2" margin="0 0 xx-small 0">
                  {I18n.t('Configurations')}
                </Heading>
                <Text size="small" color="secondary">
                  {I18n.t(
                    'The completion rules, pedagogical guidance, and sources of the large language model (LLM).',
                  )}
                </Text>
              </View>

              {aiExperience.learning_objective && (
                <View as="div" margin="0 0 medium 0">
                  <Heading level="h3" margin="0 0 small 0">
                    {I18n.t('Learning Objectives')}
                  </Heading>
                  <Text data-testid="ai-experience-show-learning-objectives-text">
                    <span style={{whiteSpace: 'pre-wrap'}}>{aiExperience.learning_objective}</span>
                  </Text>
                </View>
              )}

              {aiExperience.pedagogical_guidance && (
                <View as="div" margin="0 0 medium 0">
                  <Heading level="h3" margin="0 0 small 0">
                    {I18n.t('Pedagogical activity guidance')}
                  </Heading>
                  <Text data-testid="ai-experience-show-pedagogical-guidance-text">
                    <span style={{whiteSpace: 'pre-wrap'}}>
                      {aiExperience.pedagogical_guidance}
                    </span>
                  </Text>
                </View>
              )}

              {aiExperience.facts && (
                <View as="div" margin="0 0 medium 0">
                  <Heading level="h3" margin="0 0 small 0">
                    {I18n.t('Text source')}
                  </Heading>
                  <Text data-testid="ai-experience-show-facts-text">
                    <span style={{whiteSpace: 'pre-wrap'}}>{aiExperience.facts}</span>
                  </Text>
                </View>
              )}

              {ENV?.FEATURES?.ai_experiences_context_file_upload &&
                (aiExperience.context_files?.length ?? 0) > 0 && (
                  <View as="div" margin="medium 0 0 0">
                    <Heading level="h3" margin="0 0 small 0">
                      {I18n.t('File sources')}
                    </Heading>
                    <FileList
                      files={aiExperience.context_files!.filter(
                        f => !aiExperience.failed_context_file_names?.includes(f.display_name),
                      )}
                      uploadingFileNames={new Set()}
                      failedFileNames={new Set(aiExperience.failed_context_file_names ?? [])}
                    />
                  </View>
                )}
            </View>
          </InstUISettingsProvider>
        </>
      )}

      <Modal
        open={isDeleteModalOpen}
        onDismiss={() => setIsDeleteModalOpen(false)}
        size="small"
        label={I18n.t('Delete Knowledge Chat')}
        shouldCloseOnDocumentClick={true}
      >
        <Modal.Header>
          <Heading>{I18n.t('Delete Knowledge Chat')}</Heading>
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
