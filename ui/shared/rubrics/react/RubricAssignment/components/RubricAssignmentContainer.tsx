/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {SaveRubricResponse} from '@canvas/rubrics/react/RubricForm/queries/RubricFormQueries'
import {View} from '@instructure/ui-view'
import type {ViewProps} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
import {
  IconAddLine,
  IconEditLine,
  IconEyeLine,
  IconRubricLine,
  IconSearchLine,
  IconTrashLine,
} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {RubricCreateModal} from './RubricCreateModal'
import type {Rubric, RubricAssociation} from '../../types/rubric'
import {RubricAssessmentTray} from '../../RubricAssessment'
import {addRubricToAssignment, AssignmentRubric, removeRubricFromAssignment} from '../queries'
import {RubricSearchTray} from './RubricSearchTray/RubricSearchTray'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {RubricSelfAssessmentSettings} from './RubricSelfAssessmentSettings'
import {DeleteConfirmModal} from './DeleteConfirmModal'
import {Tooltip} from '@instructure/ui-tooltip'
import {queryClient} from '@canvas/query'
import {QueryClientProvider} from '@tanstack/react-query'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('enhanced-rubrics-assignment-container')

export type RubricAssignmentContainerProps = {
  assignmentId: string
  assignmentPointsPossible?: number
  assignmentRubric?: AssignmentRubric
  assignmentRubricAssociation?: RubricAssociation
  canManageRubrics: boolean
  courseId: string
  currentUserId: string
  rubricSelfAssessmentFFEnabled: boolean
  aiRubricsEnabled: boolean
  onRubricChange?: (rubric: Rubric | undefined) => void
  containerStyles?: Partial<ViewProps>
}
export const RubricAssignmentContainer = ({
  assignmentId,
  assignmentPointsPossible,
  assignmentRubric,
  assignmentRubricAssociation,
  canManageRubrics,
  courseId,
  currentUserId,
  rubricSelfAssessmentFFEnabled,
  aiRubricsEnabled,
  onRubricChange,
  containerStyles: customContainerStyles,
}: RubricAssignmentContainerProps) => {
  const [rubric, setRubric] = useState(assignmentRubric)
  const [rubricAssociation, setRubricAssociation] = useState(assignmentRubricAssociation)
  const [rubricCreateModalOpen, setRubricCreateModalOpen] = useState(false)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [isSearchTrayOpen, setIsSearchTrayOpen] = useState(false)
  const [searchPreviewRubric, setSearchPreviewRubric] = useState<Rubric>()
  const [isDeleteConfirmModalOpen, setIsDeleteConfirmModalOpen] = useState(false)
  const [_criteriaViaLlm, setCriteriaViaLlm] = useState(false)
  const [assignmentPoints, setAssignmentPoints] = useState(assignmentPointsPossible)

  const deleteTooltipText =
    (rubric?.association_count ?? 0) > 1 ? I18n.t('Unlink Rubric') : I18n.t('Delete Rubric')

  const handleSaveRubric = (
    savedRubricResponse: SaveRubricResponse,
    updatePointsPossible?: boolean,
  ) => {
    setRubric(savedRubricResponse.rubric)
    setRubricAssociation(savedRubricResponse.rubricAssociation)
    setRubricCreateModalOpen(false)

    handleUpdateAssignmentPoints(
      savedRubricResponse.rubric?.pointsPossible,
      savedRubricResponse.rubricAssociation?.useForGrading,
      updatePointsPossible,
    )
    onRubricChange?.(savedRubricResponse.rubric)
  }

  const handleRemoveRubric = async () => {
    if (rubricAssociation) {
      await removeRubricFromAssignment(courseId, rubricAssociation?.id)
      setRubric(undefined)
      setRubricAssociation(undefined)
      setIsDeleteConfirmModalOpen(false)
      onRubricChange?.(undefined)
    }
  }

  const handleAddRubric = async (rubricId: string, updatedAssociation: RubricAssociation) => {
    try {
      const response = await addRubricToAssignment(
        courseId,
        assignmentId,
        rubricId,
        updatedAssociation,
      )
      setRubric(response.rubric)
      setRubricAssociation(response.rubricAssociation)
      setIsSearchTrayOpen(false)
      onRubricChange?.(response.rubric)
      showFlashSuccess(I18n.t('Rubric added to assignment'))()
    } catch (_error) {
      showFlashError(I18n.t('Failed to add rubric to assignment'))()
    }
  }

  const handleEditClick = () => {
    if (!canManageRubrics) {
      return
    }

    setCriteriaViaLlm(false)
    setRubricCreateModalOpen(true)
  }

  const handleUpdateAssignmentPoints = (
    pointsPossible?: number,
    useForGrading?: boolean,
    updatePointsPossible?: boolean,
  ) => {
    if (useForGrading && updatePointsPossible) {
      setAssignmentPoints(pointsPossible ?? 0)
      // Vanilla JS is used here because the assignment points are updated in the assignment
      // show page which is rendered by ERB and needs to update existing DOM elements.
      const pointsPossibleElement = document.querySelector('#assignment_show .points_possible')
      if (pointsPossibleElement) {
        pointsPossibleElement.textContent = String(pointsPossible ?? 0)
      }

      const discussion_points_text = I18n.t(
        'discussion_points_possible',
        {one: '%{count} point possible', other: '%{count} points possible'},
        {
          count: pointsPossible,
          precision: 2,
          strip_insignificant_zeros: true,
        },
      )

      const discussionPointsElement = document.querySelector('.discussion-title .discussion-points')
      if (discussionPointsElement) {
        discussionPointsElement.textContent = discussion_points_text
      }
    }
  }

  const containerStyles = customContainerStyles ?? {
    borderColor: 'primary',
    borderWidth: 'small',
    padding: 'small',
    margin: 'medium 0',
  }

  return (
    <QueryClientProvider client={queryClient}>
      <View as="div" display="inline-block" {...containerStyles}>
        {rubric ? (
          <>
            <Flex as="div" justifyItems="space-between" alignItems="center">
              <Flex.Item shouldGrow shouldShrink overflowX="hidden">
                <Flex gap="small" alignItems="center">
                  <Flex.Item>
                    <IconRubricLine />
                  </Flex.Item>
                  <Flex.Item shouldGrow shouldShrink overflowX="hidden">
                    <Text>
                      <TruncateText truncate="word" ellipsis="...">
                        {rubric.title}
                      </TruncateText>
                    </Text>
                  </Flex.Item>
                </Flex>
              </Flex.Item>
              <Flex.Item>
                <Button
                  margin="0 0 0 xx-large"
                  renderIcon={<IconEyeLine />}
                  data-testid="preview-assignment-rubric-button"
                  onClick={() => setIsPreviewTrayOpen(true)}
                >
                  {I18n.t('Preview Rubric')}
                </Button>

                {canManageRubrics && (
                  <Tooltip renderTip={I18n.t('Edit Rubric')}>
                    <IconButton
                      margin="0 0 0 small"
                      screenReaderLabel={I18n.t('Edit Rubric')}
                      data-testid="edit-assignment-rubric-button"
                      onClick={handleEditClick}
                    >
                      <IconEditLine />
                    </IconButton>
                  </Tooltip>
                )}

                <Tooltip renderTip={deleteTooltipText}>
                  <IconButton
                    margin="0 0 0 small"
                    data-testid="remove-assignment-rubric-button"
                    screenReaderLabel={deleteTooltipText}
                    onClick={() => setIsDeleteConfirmModalOpen(true)}
                  >
                    <IconTrashLine />
                  </IconButton>
                </Tooltip>

                <Tooltip renderTip={I18n.t('Replace Rubric')}>
                  <IconButton
                    margin="0 0 0 small"
                    screenReaderLabel={I18n.t('Replace Rubric')}
                    data-testid="find-assignment-rubric-icon-button"
                    onClick={() => setIsSearchTrayOpen(true)}
                  >
                    <IconSearchLine />
                  </IconButton>
                </Tooltip>
              </Flex.Item>
            </Flex>
            <View>
              {rubricSelfAssessmentFFEnabled && (
                <>
                  <View as="hr" />
                  <RubricSelfAssessmentSettings assignmentId={assignmentId} rubricId={rubric.id} />
                </>
              )}
            </View>
          </>
        ) : (
          <View>
            {canManageRubrics && (
              <>
                <Button
                  margin="0"
                  renderIcon={<IconAddLine />}
                  data-testid="create-assignment-rubric-button"
                  onClick={() => {
                    setCriteriaViaLlm(false)
                    setRubricCreateModalOpen(true)
                  }}
                >
                  {I18n.t('Create Rubric')}
                </Button>
              </>
            )}
            <Button
              margin="0 0 0 small"
              data-testid="find-assignment-rubric-button"
              renderIcon={<IconSearchLine />}
              onClick={() => setIsSearchTrayOpen(true)}
            >
              {I18n.t('Find Rubric')}
            </Button>
          </View>
        )}
      </View>
      <DeleteConfirmModal
        associationCount={rubric?.association_count ?? 0}
        isOpen={isDeleteConfirmModalOpen}
        onConfirm={() => handleRemoveRubric()}
        onDismiss={() => setIsDeleteConfirmModalOpen(false)}
      />
      <RubricCreateModal
        assignmentId={assignmentId}
        assignmentPointsPossible={assignmentPoints}
        isOpen={rubricCreateModalOpen}
        rubric={rubric}
        rubricAssociation={rubricAssociation}
        aiRubricsEnabled={aiRubricsEnabled}
        onDismiss={() => {
          setCriteriaViaLlm(false)
          setRubricCreateModalOpen(false)
        }}
        onSaveRubric={handleSaveRubric}
      />
      <RubricAssessmentTray
        currentUserId={currentUserId}
        hidePoints={rubricAssociation?.hidePoints}
        isOpen={isPreviewTrayOpen}
        isPreviewMode={false}
        rubric={searchPreviewRubric ?? rubric}
        rubricAssessmentData={[]}
        shouldCloseOnDocumentClick={true}
        onDismiss={() => setIsPreviewTrayOpen(false)}
      />
      <RubricSearchTray
        courseId={courseId}
        isOpen={isSearchTrayOpen}
        onPreview={previewRubric => {
          setSearchPreviewRubric(previewRubric)
          setIsPreviewTrayOpen(true)
        }}
        onDismiss={() => {
          setIsSearchTrayOpen(false)
          setIsPreviewTrayOpen(false)
          setSearchPreviewRubric(undefined)
        }}
        onAddRubric={handleAddRubric}
      />
    </QueryClientProvider>
  )
}
