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
import {useScope as useI18nScope} from '@canvas/i18n'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Text} from '@instructure/ui-text'
import {Flex} from '@instructure/ui-flex'

const I18n = useI18nScope('copy_warnings_modal')

interface CopyWarningsModalProps {
  errorMessages: string[]
}

const CopyWarningsModal = ({errorMessages}: CopyWarningsModalProps) => {
  const [open, setOpen] = useState(true)

  const handleCloseModal = () => {
    setOpen(false)
  }

  return (
    <Modal size="auto" open={open} onDismiss={handleCloseModal} label={I18n.t('Attention')}>
      <Modal.Body>
        <Flex direction="column">
          {errorMessages.map(warning => (
            <Flex.Item>
              <strong>*</strong>
              <Text>{warning}</Text>
            </Flex.Item>
          ))}
        </Flex>
      </Modal.Body>
    </Modal>
  )
}

export default CopyWarningsModal
