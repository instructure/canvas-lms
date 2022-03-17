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

import {useScope as useI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React from 'react'
import {RemovableItem} from './RemovableItem'

import {IconPaperclipLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('discussion_posts')

export const AttachmentButton = props => {
  const TRUNCATE_TO = 30
  return (
    <RemovableItem
      onRemove={props.onDeleteItem}
      screenReaderLabel={I18n.t('Remove Attachment')}
      childrenAriaLabel={I18n.t(`Replace filename.png button`)}
    >
      <Link
        renderIcon={<IconPaperclipLine size="small" />}
        href={props.attachment?.url}
        isWithinText={false}
      >
        <Text weight="bold">
          {props.attachment?.displayName?.length > TRUNCATE_TO
            ? props.attachment?.displayName?.slice(0, TRUNCATE_TO)?.concat('...')
            : props.attachment?.displayName}
        </Text>
      </Link>
    </RemovableItem>
  )
}

AttachmentButton.propTypes = {
  /**
   * This button renders when attachment is given we
   * use many attributes from it.
   */
  attachment: PropTypes.object.isRequired,
  /**
   * When we click the close (x button) on the RemovableItem.
   * Used to delete the attachment.
   */
  onDeleteItem: PropTypes.func.isRequired
}
