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
import {func, arrayOf, oneOfType, number, shape, string} from 'prop-types'
import {Modal} from '@instructure/ui-overlays'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading, List} from '@instructure/ui-elements'
import {View} from '@instructure/ui-layout'
import formatMessage from '../../../../../format-message'
import LtiTool from './LtiTool'

// TODO: we really need a way for the client to pass this to the RCE
const getLiveRegion=() => document.getElementById('flash_screenreader_holder')

export function LtiToolsModal(props) {
  return (
    <Modal
      data-mce-component
      liveRegion={getLiveRegion}
      size="medium"
      label={formatMessage('LTI Tools')}
      onDismiss={props.onDismiss}
      open
      shouldCloseOnDocumentClick
    >
      <Modal.Header>
        <CloseButton placement="end" offset="medium" onClick={props.onDismiss}>
          {formatMessage('Close')}
        </CloseButton>
        <Heading>{formatMessage('Select App')}</Heading>
      </Modal.Header>
      <Modal.Body>
        {renderTools(props.ltiButtons)}
      </Modal.Body>
      <Modal.Footer>
        <Button onClick={props.onDismiss}>{formatMessage('Cancel')}</Button>
      </Modal.Footer>
    </Modal>
  )

  function renderTools(ltiButtons) {
    return (
      <List variant="unstyled">
        {ltiButtons.sort((a, b) => a.title.localeCompare(b.title)).map((b, i) => {
          return (
            <List.Item key={b.id}>
              <View
                as="div"
                borderWidth={i === 0 ? "small none" : "none none small none"}
                padding="medium"
              >
                <LtiTool
                  title={b.title}
                  image={b.image}
                  onAction={() => {
                    b.onAction()
                    props.onDismiss()
                  }}
                  description={b.description}
                />
              </View>
            </List.Item>
          )
        })}
      </List>
    )
  }


}

LtiToolsModal.propTypes = {
  ltiButtons: arrayOf(shape({
    description: string.isRequired,
    id: oneOfType([string, number]).isRequired,
    image: string.isRequired,
    onAction: func.isRequired,
    title: string.isRequired
  })),
  onDismiss: func.isRequired
}