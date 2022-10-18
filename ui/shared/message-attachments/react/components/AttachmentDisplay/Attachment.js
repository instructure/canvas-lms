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

import {getFileThumbnail} from '@canvas/util/fileHelper'
import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {RemovableItem} from '../RemovableItem/RemovableItem'

import {Flex} from '@instructure/ui-flex'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'

const I18n = useI18nScope('conversations_2')

export const Attachment = ({...props}) => {
  if (props.attachment.isLoading) {
    return <Spinner renderTitle={I18n.t('Loading')} size="medium" />
  }

  let attachmentInput = null
  const handleAttachment = () => attachmentInput?.click()
  const attachmentDisplayName = props.attachment.display_name
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
          {getFileThumbnail(props.attachment, 'medium')}
        </Flex.Item>
        <Flex.Item>
          <TruncateText position="middle" maxLines={3}>
            <Text size="small">{props.attachment.display_name}</Text>
          </TruncateText>
        </Flex.Item>
      </Flex>
      <input
        data-testid="replacement-input"
        ref={input => (attachmentInput = input)}
        type="file"
        style={{display: 'none'}}
        aria-hidden={true}
        onChange={props.onReplace}
      />
    </RemovableItem>
  )
}

export const attachmentProp = PropTypes.shape({
  id: PropTypes.string,
  display_name: PropTypes.string,
  thumbnail_url: PropTypes.string,
  mime_class: PropTypes.string,
  isLoading: PropTypes.bool,
})

Attachment.propTypes = {
  attachment: attachmentProp.isRequired,
  onReplace: PropTypes.func.isRequired,
  onDelete: PropTypes.func.isRequired,
}

export default Attachment
