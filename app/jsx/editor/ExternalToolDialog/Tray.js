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
import CanvasTray from 'jsx/shared/components/CanvasTray'

export default function ExternalToolDialogTray(props) {
  const {open, label, onOpen, onClose, onCloseButton, name, children} = props
  return (
    <CanvasTray
      open={open}
      label={label}
      title={name}
      onOpen={onOpen}
      onClose={onClose}
      onDismiss={onCloseButton}
      placement="end"
      size="regular"
      padding="0"
      headerPadding="small"
    >
      {children}
    </CanvasTray>
  )
}

ExternalToolDialogTray.propTypes = {
  open: PropTypes.bool,
  label: PropTypes.string.isRequired,
  onOpen: PropTypes.func,
  onClose: PropTypes.func,
  onCloseButton: PropTypes.func,
  name: PropTypes.string.isRequired,
  children: PropTypes.node
}
