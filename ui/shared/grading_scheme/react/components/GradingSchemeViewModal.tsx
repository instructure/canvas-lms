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

type Props = {
  open: boolean
  gradingScheme?: GradingScheme
  handleClose: () => void
  handleGradingSchemeDelete: (gradingSchemeId: string) => void
  editGradingScheme: (gradingSchemeId: string) => void
  canManageScheme: (gradingScheme: GradingScheme) => boolean
}
const GradingSchemeViewModal = ({
  open,
  gradingScheme,
  handleClose,
  handleGradingSchemeDelete,
  editGradingScheme,
  canManageScheme,
}: Props) => {
  if (!gradingScheme) {
    return <></>
  }
  return (
    <Modal as="form" open={open} onDismiss={handleClose} label={gradingScheme.title} size="small">
      <Modal.Header>
        <CloseButton
          screenReaderLabel={I18n.t('Close')}
          placement="end"
          offset="small"
          onClick={handleClose}
        />
        <Heading>{gradingScheme.title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <GradingSchemeView
          gradingScheme={gradingScheme}
          archivedGradingSchemesEnabled={true}
          disableDelete={!canManageScheme(gradingScheme)}
          disableEdit={!canManageScheme(gradingScheme)}
          onDeleteRequested={() => handleGradingSchemeDelete(gradingScheme.id)}
          onEditRequested={() => editGradingScheme(gradingScheme.id)}
        />
      </Modal.Body>
      <Modal.Footer>
        <Flex justifyItems="end">
          <Flex.Item>
            <Button onClick={handleClose} margin="0 x-small 0 x-small">
              {I18n.t('Cancel')}
            </Button>
          </Flex.Item>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}

export default GradingSchemeViewModal
