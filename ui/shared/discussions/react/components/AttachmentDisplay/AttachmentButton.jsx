/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {IconPaperclipLine} from '@instructure/ui-icons'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('discussion_posts')

export const AttachmentButton = props => {
  const TRUNCATE_TO = 30

  const displayFilename = () => {
    if (props.attachment?.displayName?.length > TRUNCATE_TO) {
      return (
        <AccessibleContent
          alt={I18n.t('Download %{fileName}', {
            fileName: props.attachment?.displayName?.slice(0, TRUNCATE_TO)?.concat('...'),
          })}
        >
          <Text weight="bold">
            {props.attachment?.displayName?.slice(0, TRUNCATE_TO)?.concat('...')}
          </Text>
        </AccessibleContent>
      )
    }
    return (
      <AccessibleContent
        alt={I18n.t('Download %{fileName}', {
          fileName: props.attachment?.displayName,
        })}
      >
        <Text weight="bold">{props.attachment?.displayName}</Text>
      </AccessibleContent>
    )
  }

  return (
    <RemovableItem
      onRemove={props.onDeleteItem}
      screenReaderLabel={I18n.t('Remove Attachment')}
      childrenAriaLabel={I18n.t(`Replace filename.png button`)}
      responsiveQuerySizes={props.responsiveQuerySizes}
    >
      <span className="discussions-attach-button">
        <Link
          renderIcon={<IconPaperclipLine size="small" />}
          href={props.attachment?.url}
          isWithinText={false}
        >
          <Text weight="bold">{displayFilename()}</Text>
        </Link>
      </span>
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
  onDeleteItem: PropTypes.func.isRequired,
  /**
   * Used to set the responsive state
   */
  responsiveQuerySizes: PropTypes.func.isRequired,
}
