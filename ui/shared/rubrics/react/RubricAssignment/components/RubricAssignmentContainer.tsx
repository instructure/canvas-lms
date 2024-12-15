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
import {QueryProvider} from '@canvas/query'
import type {SaveRubricResponse} from '@canvas/rubrics/react/RubricForm/queries/RubricFormQueries'
import {View} from '@instructure/ui-view'
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
import {RubricCreateModal} from './RubricCreateModal'
import type {Rubric, RubricAssociation} from '../../types/rubric'
import {RubricAssessmentTray} from '../../RubricAssessment'
import {addRubricToAssignment, removeRubricFromAssignment, type AssignmentRubric} from '../queries'
import {RubricSearchTray} from './RubricSearchTray'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {CopyEditConfirmModal} from './CopyEditConfirmModal'
import {RubricSelfAssessmentSettings} from './RubricSelfAssessmentSettings'

const I18n = createI18nScope('enhanced-rubrics-assignment-container')

export type RubricAssignmentContainerProps = {
  accountMasterScalesEnabled: boolean
  assignmentId: string
  assignmentRubric?: AssignmentRubric
  assignmentRubricAssociation?: RubricAssociation
  canManageRubrics: boolean
  canUpdateSelfAssessment: boolean
  contextAssetString: string
  courseId: string
  rubricSelfAssessmentEnabled: boolean
  rubricSelfAssessmentFFEnabled: boolean
}
export const RubricAssignmentContainer = ({
  accountMasterScalesEnabled,
  assignmentId,
  assignmentRubric,
  assignmentRubricAssociation,
  canManageRubrics,
  canUpdateSelfAssessment,
  contextAssetString,
  courseId,
  rubricSelfAssessmentEnabled,
  rubricSelfAssessmentFFEnabled,
}: RubricAssignmentContainerProps) => {
  const [rubric, setRubric] = useState(assignmentRubric)
  const [rubricAssociation, setRubricAssociation] = useState(assignmentRubricAssociation)
  const [rubricCreateModalOpen, setRubricCreateModalOpen] = useState(false)
  const [isPreviewTrayOpen, setIsPreviewTrayOpen] = useState(false)
  const [isSearchTrayOpen, setIsSearchTrayOpen] = useState(false)
  const [searchPreviewRubric, setSearchPreviewRubric] = useState<Rubric>()
  const [canUpdateRubric, setCanUpdateRubric] = useState(assignmentRubric?.can_update)
  const [copyEditConfirmModalOpen, setCopyEditConfirmModalOpen] = useState(false)

  const handleSaveRubric = (savedRubricResponse: SaveRubricResponse) => {
    setRubric(savedRubricResponse.rubric)
    setRubricAssociation(savedRubricResponse.rubricAssociation)
    setRubricCreateModalOpen(false)
  }

  const handleRemoveRubric = async () => {
    if (rubricAssociation) {
      await removeRubricFromAssignment(courseId, rubricAssociation?.id)
      setRubric(undefined)
      setRubricAssociation(undefined)
    }
  }

  const handleAddRubric = async (rubricId: string, updatedAssociation: RubricAssociation) => {
    try {
      const response = await addRubricToAssignment(
        courseId,
        assignmentId,
        rubricId,
        updatedAssociation
      )
      setRubric(response.rubric)
      setCanUpdateRubric(response.rubric.can_update)
      setRubricAssociation(response.rubricAssociation)
      setIsSearchTrayOpen(false)
      showFlashSuccess(I18n.t('Rubric added to assignment'))()
    } catch (_error) {
      showFlashError(I18n.t('Failed to add rubric to assignment'))()
    }
  }

  const handleEditClick = () => {
    if (canUpdateRubric) {
      setRubricCreateModalOpen(true)
      return
    }

    setCopyEditConfirmModalOpen(true)
  }

  return (
    <QueryProvider>
      <View
        as="div"
        display="inline-block"
        borderColor="primary"
        borderWidth="small"
        padding="small"
        margin="medium 0"
      >
        {rubric ? (
          <View>
            <IconRubricLine />
            <View as="div" margin="0 0 0 small" display="inline-block">
              <Text>{rubric.title}</Text>
            </View>

            <Button
              margin="0 0 0 xx-large"
              // @ts-expect-error
              renderIcon={IconEyeLine}
              data-testid="preview-assignment-rubric-button"
              onClick={() => setIsPreviewTrayOpen(true)}
            >
              {I18n.t('Preview Rubric')}
            </Button>
            {canManageRubrics && (
              <IconButton
                margin="0 0 0 small"
                screenReaderLabel={I18n.t('Edit Rubric')}
                data-testid="edit-assignment-rubric-button"
                onClick={handleEditClick}
              >
                <IconEditLine />
              </IconButton>
            )}
            <IconButton
              margin="0 0 0 small"
              data-testid="remove-assignment-rubric-button"
              screenReaderLabel={I18n.t('Remove Rubric')}
              onClick={() => handleRemoveRubric()}
            >
              <IconTrashLine />
            </IconButton>
            {rubricSelfAssessmentFFEnabled && (
              <>
                <View as="hr" />
                <RubricSelfAssessmentSettings
                  assignmentId={assignmentId}
                  canUpdateSelfAssessment={canUpdateSelfAssessment}
                  rubricSelfAssessmentEnabled={rubricSelfAssessmentEnabled}
                />
              </>
            )}
          </View>
        ) : (
          <View>
            {canManageRubrics && (
              <Button
                margin="0"
                // @ts-expect-error
                renderIcon={IconAddLine}
                data-testid="create-assignment-rubric-button"
                onClick={() => setRubricCreateModalOpen(true)}
              >
                {I18n.t('Create Rubric')}
              </Button>
            )}
            <Button
              margin="0 0 0 small"
              data-testid="find-assignment-rubric-button"
              // @ts-expect-error
              renderIcon={IconSearchLine}
              onClick={() => setIsSearchTrayOpen(true)}
            >
              {I18n.t('Find Rubric')}
            </Button>
          </View>
        )}
      </View>
      <CopyEditConfirmModal
        accountMasterScalesEnabled={accountMasterScalesEnabled}
        contextAssetString={contextAssetString}
        isOpen={copyEditConfirmModalOpen}
        onConfirm={() => {
          setCopyEditConfirmModalOpen(false)
          setRubricCreateModalOpen(true)
        }}
        onDismiss={() => setCopyEditConfirmModalOpen(false)}
        rubric={rubric}
      />
      <RubricCreateModal
        isOpen={rubricCreateModalOpen}
        rubric={rubric}
        rubricAssociation={rubricAssociation}
        onDismiss={() => setRubricCreateModalOpen(false)}
        onSaveRubric={handleSaveRubric}
      />
      <RubricAssessmentTray
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
    </QueryProvider>
  )
}
