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

import React from 'react'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {Button} from '@instructure/ui-buttons'
import {Text} from '@instructure/ui-text'

interface ImplementationDetailModalProps {
  title: string
  content: string | undefined
  isModalOpen: boolean
  setModalOpen: Function
}

const ImplementationDetailModal = (props: ImplementationDetailModalProps) => {
  return (
    <div>
      <Modal
        label={props.title}
        open={props.isModalOpen}
        size="large"
        onDismiss={() => props.setModalOpen(false)}
      >
        <Modal.Body>
          <Text dangerouslySetInnerHTML={{__html: props.content || ''}} />
        </Modal.Body>
        <Modal.Footer>
          <Button onClick={() => props.setModalOpen(false)}>Close</Button>
        </Modal.Footer>
      </Modal>
    </div>
  )
}

export default ImplementationDetailModal
