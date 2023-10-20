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
import {Flex} from '@instructure/ui-flex'
import {Attachment, attachmentProp} from './Attachment'

export const AttachmentDisplay = ({...props}) => {
  return (
    <Flex alignItems="start" wrap="wrap">
      {props.attachments.map(a => (
        <Flex.Item key={a.id}>
          <Attachment
            attachment={a}
            onReplace={props.onReplaceItem.bind(null, a.id)}
            onDelete={props.onDeleteItem.bind(null, a.id)}
          />
        </Flex.Item>
      ))}
    </Flex>
  )
}

AttachmentDisplay.propTypes = {
  /**
   * List of attachments to display
   */
  attachments: PropTypes.arrayOf(attachmentProp).isRequired,
  /**
   * Behavior for replacing an individual attachment
   */
  onReplaceItem: PropTypes.func.isRequired,
  /**
   * Behavior for deleting an individual attachment
   */
  onDeleteItem: PropTypes.func.isRequired,
}

export default AttachmentDisplay
