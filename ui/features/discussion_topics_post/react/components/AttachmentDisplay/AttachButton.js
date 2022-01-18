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

import I18n from 'i18n!discussion_posts'
import PropTypes from 'prop-types'
import React from 'react'

import {CondensedButton} from '@instructure/ui-buttons'
import {IconPaperclipLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'

export const AttachButton = ({...props}) => {
  let attachmentInput = null
  const handleAttachmentClick = () => attachmentInput?.click()
  return (
    <>
      <CondensedButton
        color="primary"
        renderIcon={<IconPaperclipLine size="small" />}
        onClick={handleAttachmentClick}
        data-testid="attach-btn"
      >
        <Text weight="bold">{I18n.t('Attach')}</Text>
      </CondensedButton>
      <input
        data-testid="attachment-input"
        ref={input => (attachmentInput = input)}
        type="file"
        style={{display: 'none'}}
        aria-hidden
        onChange={props.onAttachmentUpload}
      />
    </>
  )
}

AttachButton.propTypes = {
  /**
   * function that performs on the file after button click, then upload file, upload
   */
  onAttachmentUpload: PropTypes.func.isRequired
}
