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

import PropTypes from 'prop-types'
import React from 'react'
import {AttachmentButton} from './AttachmentButton'

import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'

export function AttachmentDisplay(props) {
  const removeAttachment = () => {
    props.setAttachment(null)
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          itemSpacing: '0 small 0 0',
          textSize: 'small',
        },
        desktop: {
          itemSpacing: 'none',
          textSize: 'medium',
        },
      }}
      render={(_responsiveProps, _matches) =>
        props.attachment?._id && (
          <AttachmentButton attachment={props.attachment} onDeleteItem={removeAttachment} />
        )
      }
    />
  )
}

AttachmentDisplay.propTypes = {
  /**
   * Array of one attachment, from useState
   * This toggles AttachmentButton (attachment present) vs AttachButton (no attachment)
   */
  attachment: PropTypes.object,
  /**
   * Used to set the attachments prop, if no attachment is set
   */
  setAttachment: PropTypes.func.isRequired,
}

export default AttachmentDisplay
