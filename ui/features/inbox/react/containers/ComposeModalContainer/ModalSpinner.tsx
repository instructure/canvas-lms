/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'

type Props = {
  label: string
  message: string
  onExited: () => void
  open: boolean
}

const ModalSpinner = (props: Props) => (
  <Modal
    open={props.open}
    label={props.label}
    shouldCloseOnDocumentClick={false}
    onExited={props.onExited}
  >
    <Modal.Body>
      <Flex direction="column" textAlign="center">
        <Flex.Item>
          <Spinner renderTitle={props.label} size="large" delay={300} />
        </Flex.Item>
        <Flex.Item>
          <Text>{props.message}</Text>
        </Flex.Item>
      </Flex>
    </Modal.Body>
  </Modal>
)

ModalSpinner.defaultProps = {
  open: true,
}

export default ModalSpinner
