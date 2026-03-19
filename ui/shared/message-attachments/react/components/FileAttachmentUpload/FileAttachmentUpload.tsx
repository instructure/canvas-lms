/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import PropTypes from 'prop-types'
import React, {useRef} from 'react'

import {IconButton} from '@instructure/ui-buttons'
import {IconPaperclipLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'

const I18n = createI18nScope('conversations_2')

// @ts-expect-error TS7006 (typescriptify)
export const FileAttachmentUpload = props => {
  const attachmentInput = useRef()
  // @ts-expect-error TS2339 (typescriptify)
  const handleAttachmentClick = () => attachmentInput.current?.click()

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
        // @ts-expect-error TS2322 (typescriptify)
        ref={attachmentInput}
        type="file"
        style={{display: 'none'}}
        aria-hidden={true}
        onChange={props.onAddItem}
        multiple={true}
      />
    </>
  )
}

FileAttachmentUpload.propTypes = {
  onAddItem: PropTypes.func.isRequired,
}

export default FileAttachmentUpload
