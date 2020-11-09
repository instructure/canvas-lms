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
// import {t} from 'i18n!conversations'
// TODO: replace with frd translation function
const t = str => str

export const Attachment = ({...props}) => {
  return (
    <RemovableItem
      onRemove={props.onDelete}
      screenReaderLabel={t('Remove Attachment')}
      // TODO: handle translation arguments when i18n frd works
      childrenAriaLabel={t(`Replace ${props.attachment.displayName} button`)}
    >
      <Flex
        direction="column"
        padding="xx-small small"
        width="80px"
        onDoubleClick={props.onReplace}
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
