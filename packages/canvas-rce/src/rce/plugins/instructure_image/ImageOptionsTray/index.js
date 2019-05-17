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
import {bool, func} from 'prop-types'
import {CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-elements'
import {Flex} from '@instructure/ui-layout'
import {Tray} from '@instructure/ui-overlays'

import formatMessage from '../../../../format-message'
import {htmlImageElement} from '../../shared/EditorContentPropTypes'

export default function ImageOptionsTray(props) {
  const {imageElement, onRequestClose, open} = props

  return (
    <Tray
      label={formatMessage('Image Options Tray')}
      onDismiss={onRequestClose}
      onEntered={props.onEntered}
      onExited={props.onExited}
      open={open}
      placement="end"
      shouldCloseOnDocumentClick
      shouldContainFocus
      shouldReturnFocus
    >
      <Flex direction="column" height="100vh">
        <Flex.Item as="header" padding="medium">
          <Flex direction="row">
            <Flex.Item grow shrink>
              <Heading as="h2">Image Stuff</Heading>
            </Flex.Item>

            <Flex.Item>
              <CloseButton onClick={onRequestClose}>{formatMessage('Close')}</CloseButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item as="div" padding="medium">
          <img alt={imageElement.alt} src={imageElement.src} />
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

ImageOptionsTray.propTypes = {
  imageElement: htmlImageElement,
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  open: bool.isRequired
}

ImageOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
}
