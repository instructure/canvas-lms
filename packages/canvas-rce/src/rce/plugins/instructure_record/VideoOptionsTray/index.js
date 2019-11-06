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

import {bool, func, shape, string} from 'prop-types'
import {Button, CloseButton} from '@instructure/ui-buttons'

import {Flex} from '@instructure/ui-layout'
import {Heading} from '@instructure/ui-elements'
import React from 'react'
import {Tray} from '@instructure/ui-overlays'

import formatMessage from '../../../../format-message'

export default function VideoOptionsTray(props) {
  const {onRequestClose, open} = props

  function handleSave(event) {
    event.preventDefault()
  }

  return (
    <Tray
      label={formatMessage('Video Options Tray')}
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
              <Heading as="h2">{formatMessage('Video Options')}</Heading>
            </Flex.Item>

            <Flex.Item>
              <CloseButton onClick={onRequestClose}>{formatMessage('Close')}</CloseButton>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        <Flex.Item as="form" grow margin="none" shrink>
          <Flex justifyItems="space-between" direction="column" height="100%">
            <Flex.Item
              background="light"
              borderWidth="small none none none"
              padding="small medium"
              textAlign="end"
            >
              <Button onClick={handleSave} variant="primary">
                {formatMessage('Done')}
              </Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>
      </Flex>
    </Tray>
  )
}

VideoOptionsTray.propTypes = {
  onEntered: func,
  onExited: func,
  onRequestClose: func.isRequired,
  onSave: func.isRequired,
  open: bool.isRequired
}

VideoOptionsTray.defaultProps = {
  onEntered: null,
  onExited: null
}
