// @ts-nocheck
/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {ReactNodeLike} from 'prop-types'
import {Heading} from '@instructure/ui-heading'
import {CloseButton} from '@instructure/ui-buttons'
import {View} from '@instructure/ui-view'
import {Modal} from '@instructure/ui-modal'
import formatMessage from 'format-message'
import {ModalProps} from '@instructure/ui-modal/types'

export function ExternalToolDialogModal(
  props: Pick<ModalProps, 'label' | 'open' | 'onOpen' | 'onClose' | 'mountNode'> & {
    onCloseButton: () => void
    name: string
    children: ReactNodeLike
  }
) {
  return (
    <Modal
      data-mce-component={true}
      label={props.label}
      onDismiss={props.onCloseButton}
      open={props.open}
      onOpen={props.onOpen}
      onClose={props.onClose}
      mountNode={props.mountNode}
    >
      <Modal.Header>
        <Heading>{props.name}</Heading>
        <CloseButton
          placement="end"
          offset="medium"
          onClick={props.onCloseButton}
          screenReaderLabel={formatMessage('Close')}
        />
      </Modal.Header>
      <Modal.Body padding="0">
        <View as="div" height="100%">
          {props.children}
        </View>
      </Modal.Body>
    </Modal>
  )
}
