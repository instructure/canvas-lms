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

import {AttachmentDisplay} from '../../components/AttachmentDisplay/AttachmentDisplay'
import {ConversationMessage} from '../../graphqlData/ConversationMessage'
import {MessageBody} from 'jsx/canvas_inbox/components/MessageBody/MessageBody'
import {PastMessages} from 'jsx/canvas_inbox/components/PastMessages/PastMessages'
import PropTypes from 'prop-types'
import React from 'react'

import {Flex} from '@instructure/ui-flex'
import {Modal} from '@instructure/ui-modal'
import {View} from '@instructure/ui-view'

const ModalBody = (props) => (
  <Modal.Body padding="none">
    <Flex direction="column" width="100%" height="100%">
      {props.children}
      <View borderWidth="small none none none" padding="x-small">
        <MessageBody onBodyChange={props.onBodyChange} messages={props.bodyMessages} />
      </View>
      {props.pastMessages?.length > 0 && <PastMessages messages={props.pastMessages} />}
      {props.attachments?.length > 0 && (
        <View borderWidth="small none none none" padding="small">
          <AttachmentDisplay
            attachments={props.attachments}
            onReplaceItem={props.replaceAttachment}
            onDeleteItem={props.removeAttachment}
          />
        </View>
      )}
    </Flex>
  </Modal.Body>
)

ModalBody.propTypes = {
  attachments: PropTypes.array,
  bodyMessages: PropTypes.arrayOf(
    PropTypes.shape({
      text: PropTypes.string,
      type: PropTypes.string,
    })
  ),
  children: PropTypes.element,
  onBodyChange: PropTypes.func,
  pastMessages: PropTypes.arrayOf(ConversationMessage.shape),
  removeAttachment: PropTypes.func,
  replaceAttachment: PropTypes.func,
}

export default ModalBody
