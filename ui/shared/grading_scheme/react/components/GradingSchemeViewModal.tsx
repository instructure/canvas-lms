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
import React from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Modal} from '@instructure/ui-modal'
import type {GradingScheme} from '../../gradingSchemeApiModel'
import {Heading} from '@instructure/ui-heading'
import {GradingSchemeView} from './view/GradingSchemeView'
import {CloseButton, Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('GradingSchemeViewModal')

export type GradingSchemeViewModalProps = {
  open: boolean
  gradingScheme?: GradingScheme
  isCourseDefault?: boolean
  viewingFromAccountManagementPage?: boolean
  handleClose: () => void
  openDeleteModal: (gradingScheme: GradingScheme) => void
  editGradingScheme: (gradingSchemeId: string) => void
  canManageScheme: (gradingScheme: GradingScheme) => boolean
}
const GradingSchemeViewModal = ({
  open,
  gradingScheme,
  isCourseDefault = false,
  viewingFromAccountManagementPage = false,
  handleClose,
  openDeleteModal,
  editGradingScheme,
  canManageScheme,
}: GradingSchemeViewModalProps) => {
  if (!gradingScheme) {
    return <></>
  }
  const archivedGradingSchemesDisableEdit =
    !viewingFromAccountManagementPage && gradingScheme.context_type === 'Account'
  const disableEditSchemeData =
    archivedGradingSchemesDisableEdit || gradingScheme.assessed_assignment || isCourseDefault
  return (
    <Modal
      as="form"
      open={open}
      onDismiss={handleClose}
      label={gradingScheme.title}
      size="small"
      data-testid="grading-scheme-view-modal"
    >
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={handleClose}
          data-testid="grading-scheme-view-modal-close-button"
        />
        <Heading data-testid="grading-scheme-view-modal-title">{gradingScheme.title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <GradingSchemeView
          gradingScheme={gradingScheme}
          archivedGradingSchemesEnabled={true}
          disableDelete={!canManageScheme(gradingScheme) || (disableEditSchemeData ?? false)}
          disableEdit={!canManageScheme(gradingScheme) || (disableEditSchemeData ?? false)}
          archivedGradingSchemesDisableEdit={archivedGradingSchemesDisableEdit}
          onDeleteRequested={() => openDeleteModal(gradingScheme)}
          onEditRequested={() => editGradingScheme(gradingScheme.id)}
        />
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={handleClose}>{I18n.t('Cancel')}</Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeViewModal
