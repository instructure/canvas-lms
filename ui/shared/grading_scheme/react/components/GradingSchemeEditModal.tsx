/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import React, {useRef} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import type {GradingScheme, GradingSchemeTemplate} from '../../gradingSchemeApiModel'
import {Heading} from '@instructure/ui-heading'
import {Flex} from '@instructure/ui-flex'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {
  type GradingSchemeEditableData,
  GradingSchemeInput,
  type GradingSchemeInputHandle,
} from './form/GradingSchemeInput'
import {Alert} from '@instructure/ui-alerts'

const I18n = useI18nScope('GradingSchemeViewModal')

export type GradingSchemeEditModalProps = {
  open: boolean
  gradingScheme?: GradingScheme
  handleCancelEdit: (gradingSchemeId: string) => void
  openDeleteModal: (gradingScheme: GradingScheme) => void
  handleUpdateScheme: (
    gradingSchemeFormInput: GradingSchemeEditableData,
    gradingSchemeId: string
  ) => void
  defaultGradingSchemeTemplate: GradingScheme
  defaultPointsGradingScheme: GradingSchemeTemplate
  viewingFromAccountManagementPage?: boolean
  isCourseDefault?: boolean
}
const GradingSchemeEditModal = ({
  open,
  gradingScheme,
  handleCancelEdit,
  openDeleteModal,
  handleUpdateScheme,
  defaultGradingSchemeTemplate,
  defaultPointsGradingScheme,
  viewingFromAccountManagementPage,
  isCourseDefault,
}: GradingSchemeEditModalProps) => {
  const gradingSchemeUpdateRef = useRef<GradingSchemeInputHandle>(null)
  if (!gradingScheme) {
    return <></>
  }

  const editSchemeDataDisabled =
    (!viewingFromAccountManagementPage && gradingScheme.context_type === 'Account') ||
    gradingScheme.assessed_assignment ||
    isCourseDefault
  return (
    <Modal
      as="form"
      open={open}
      onDismiss={() => handleCancelEdit(gradingScheme.id)}
      label={I18n.t('Edit Grading Scheme')}
      size="small"
      data-testid="grading-scheme-edit-modal"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={() => handleCancelEdit(gradingScheme.id)}
          data-testid="grading-scheme-edit-modal-close-button"
        />
        <Heading data-testid="grading-scheme-edit-modal-title">{gradingScheme.title}</Heading>
      </Modal.Header>
      <Modal.Body padding="medium medium x-small">
        {gradingScheme.id !== '' && editSchemeDataDisabled && (
          <Alert
            variant="info"
            margin="0 0 medium 0"
            hasShadow={false}
            renderCloseButtonLabel="Close"
          >
            {!viewingFromAccountManagementPage && gradingScheme.context_type === 'Account'
              ? I18n.t(
                  "Percentages and points can't be edited because it is an account level grading scheme."
                )
              : isCourseDefault
              ? I18n.t(
                  "Percentages and points can't be edited because it is being used as the default grading scheme."
                )
              : I18n.t(
                  "Percentages and points can't be edited because it is currently being used."
                )}
          </Alert>
        )}
        <GradingSchemeInput
          schemeInputType={gradingScheme.points_based ? 'points' : 'percentage'}
          initialFormDataByInputType={{
            percentage: {
              data: gradingScheme.points_based
                ? defaultGradingSchemeTemplate.data
                : gradingScheme.data,
              title: gradingScheme.title,
              pointsBased: false,
              scalingFactor: 1.0,
            },
            points: {
              data: gradingScheme.points_based
                ? gradingScheme.data
                : defaultPointsGradingScheme.data,
              title: gradingScheme.title,
              pointsBased: true,
              scalingFactor: gradingScheme.points_based
                ? gradingScheme.scaling_factor
                : defaultPointsGradingScheme.scaling_factor,
            },
          }}
          ref={gradingSchemeUpdateRef}
          onSave={modifiedGradingScheme => {
            handleUpdateScheme(modifiedGradingScheme, gradingScheme.id)
          }}
          editSchemeDataDisabled={editSchemeDataDisabled}
        />
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button
              onClick={() => openDeleteModal(gradingScheme)}
              disabled={editSchemeDataDisabled}
              data-testid="grading-scheme-edit-modal-delete-button"
            >
              {I18n.t('Delete')}
            </Button>
            <Button onClick={() => handleCancelEdit(gradingScheme.id)} margin="0 x-small 0 x-small">
              {I18n.t('Cancel')}
            </Button>
            <Button
              onClick={() => {
                gradingSchemeUpdateRef.current?.savePressed()
              }}
              color="primary"
              data-testid="grading-scheme-edit-modal-update-button"
            >
              {I18n.t('Save')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeEditModal
