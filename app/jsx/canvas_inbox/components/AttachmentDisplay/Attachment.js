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

import PropTypes from 'prop-types'
import React from 'react'
import {IconPaperclipLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-flex'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {RemovableItem} from '../RemovableItem/RemovableItem'
import I18n from 'i18n!conversations_2'

export const Attachment = ({...props}) => {
  let attachmentInput = null
  const handleAttachment = () => attachmentInput?.click()
  const attachmentDisplayName = props.attachment.displayName
  return (
    <RemovableItem
      onRemove={props.onDelete}
      screenReaderLabel={I18n.t('Remove Attachment')}
      childrenAriaLabel={I18n.t(`Replace %{attachmentDisplayName} button`, {attachmentDisplayName})}
    >
      <Flex
        direction="column"
        padding="xx-small small"
        width="80px"
        onDoubleClick={handleAttachment}
        data-testid="attachment"
      >
        <Flex.Item margin="none xx-small xxx-small xx-small" align="center">
          {props.attachment.thumbnailUrl ? (
            <img
              src={props.attachment.thumbnailUrl}
              alt={props.attachment.displayName}
              style={{maxWidth: '48px', maxHeight: '48px', borderRadius: '2px'}}
            />
          ) : (
            <IconPaperclipLine size="medium" data-testid="paperclip" />
          )}
        </Flex.Item>
        <Flex.Item>
          <TruncateText position="middle" maxLines={3}>
            <Text size="small">{props.attachment.displayName}</Text>
          </TruncateText>
        </Flex.Item>
      </Flex>
      <input
        data-testid="replacement-input"
        ref={input => (attachmentInput = input)}
        type="file"
        style={{display: 'none'}}
        aria-hidden
        onChange={props.onReplace}
      />
    </RemovableItem>
  )
}

export const attachmentProp = PropTypes.shape({
  id: PropTypes.string.isRequired,
  displayName: PropTypes.string.isRequired,
  thumbnailUrl: PropTypes.string
})

Attachment.propTypes = {
  attachment: attachmentProp.isRequired,
  onReplace: PropTypes.func.isRequired,
  onDelete: PropTypes.func.isRequired
}

export default Attachment
