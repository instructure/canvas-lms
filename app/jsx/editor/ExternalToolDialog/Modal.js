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
import PropTypes from 'prop-types'
import {Modal} from '@instructure/ui-overlays'

import {Heading} from '@instructure/ui-elements'
import {CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-layout'

export default function ExternalToolDialogModal(props) {
  const {open, label, onOpen, onClose, onCloseButton, closeLabel, name, children} = props
  return (
    <Modal open={open} label={label} onOpen={onOpen} onClose={onClose}>
      <Modal.Header>
        <CloseButton placement="end" offset="medium" variant="icon" onClick={onCloseButton}>
          {closeLabel}
        </CloseButton>
        <Heading>{name}</Heading>
      </Modal.Header>
      <Modal.Body padding="0">
        <Flex direction="column">{children}</Flex>
      </Modal.Body>
    </Modal>
  )
}

ExternalToolDialogModal.propTypes = {
  open: PropTypes.bool,
  label: PropTypes.string.isRequired,
  onOpen: PropTypes.func,
  onClose: PropTypes.func,
  onCloseButton: PropTypes.func,
  closeLabel: PropTypes.string.isRequired,
  name: PropTypes.string.isRequired,
  children: PropTypes.node
}
