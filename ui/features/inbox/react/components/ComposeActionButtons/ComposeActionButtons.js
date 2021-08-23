/*
 * Copyright (C) 2020 - present Instructure, Inc.
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

import I18n from 'i18n!conversations_2'
import PropTypes from 'prop-types'
import React from 'react'

import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconAttachMediaLine, IconPaperclipLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

export const ComposeActionButtons = ({...props}) => {
  return (
    <Flex justifyItems="space-between" width="100%">
      <Flex.Item>{renderUploadButtons(props)}</Flex.Item>
      <Flex.Item>{renderMessageButtons(props)}</Flex.Item>
    </Flex>
  )
}

const renderUploadButtons = props => {
  let attachmentInput = null
  const handleAttachmentClick = () => attachmentInput?.click()
  return (
    <>
      <Tooltip renderTip={I18n.t('Add an attachment')} placement="top">
        <IconButton
          screenReaderLabel={I18n.t('Add an attachment')}
          onClick={handleAttachmentClick}
          margin="xx-small"
          data-testid="attachment-upload"
        >
          <IconPaperclipLine />
        </IconButton>
      </Tooltip>
      <input
        data-testid="attachment-input"
        ref={input => (attachmentInput = input)}
        type="file"
        style={{display: 'none'}}
        aria-hidden
        onChange={props.onAttachmentUpload}
        multiple
      />
      {props.onMediaUpload && (
        <Tooltip renderTip={I18n.t('Record an audio or video comment')} placement="top">
          <IconButton
            screenReaderLabel={I18n.t('Record an audio or video comment')}
            onClick={props.onMediaUpload}
            margin="xx-small"
            data-testid="media-upload"
          >
            <IconAttachMediaLine />
          </IconButton>
        </Tooltip>
      )}
    </>
  )
}

const renderMessageButtons = props => {
  return (
    <>
      <Button
        color="secondary"
        margin="xx-small"
        onClick={props.onCancel}
        data-testid="cancel-button"
      >
        {I18n.t('Cancel')}
      </Button>
      <Button
        color={props.isSending ? 'secondary' : 'primary'}
        margin="xx-small"
        onClick={props.onSend}
        data-testid="send-button"
      >
        {props.isSending ? I18n.t('Sending...') : I18n.t('Send')}
      </Button>
    </>
  )
}

ComposeActionButtons.propTypes = {
  /**
   * Behavior when the attachment upload is clicked
   */
  onAttachmentUpload: PropTypes.func.isRequired,
  /**
   * Behavior when the media upload is clicked. Will
   * not render the button if not provided.
   */
  onMediaUpload: PropTypes.func,
  /**
   * Behavior when a cancel is clicked
   */
  onCancel: PropTypes.func.isRequired,
  /**
   * Behavior when a send is clicked
   */
  onSend: PropTypes.func.isRequired,
  /**
   * Indicates that a message is currently being sent
   */
  isSending: PropTypes.bool.isRequired
}

export default ComposeActionButtons
