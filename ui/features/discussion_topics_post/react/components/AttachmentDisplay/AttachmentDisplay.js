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
import React, {useContext} from 'react'
import {AttachmentButton} from './AttachmentButton'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'
import {UploadButton} from './UploadButton'
import {uploadFiles} from '@canvas/upload-file'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('discussion_topics_post')
export function AttachmentDisplay(props) {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const removeAttachment = () => {
    props.setAttachment(null)
  }

  const fileUploadUrl = attachmentFolderId => {
    return `/api/v1/folders/${attachmentFolderId}/files`
  }

  const addAttachment = async e => {
    const files = Array.from(e.currentTarget?.files)
    if (files.length !== 1) {
      setOnFailure(I18n.t('Error adding file to discussion message'))
    }

    props.setAttachmentToUpload(true)

    setOnSuccess(I18n.t('Uploading file'))

    try {
      const newFiles = await uploadFiles(
        files,
        fileUploadUrl(ENV.DISCUSSION?.ATTACHMENTS_FOLDER_ID)
      )
      const newFile = {
        _id: newFiles[0].id,
        url: newFiles[0].url,
        displayName: newFiles[0].display_name,
      }
      props.setAttachment(newFile)
    } catch (err) {
      setOnFailure(I18n.t('Error uploading file'))
    } finally {
      props.setAttachmentToUpload(false)
    }
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
        props.attachment?._id ? (
          <AttachmentButton attachment={props.attachment} onDeleteItem={removeAttachment} />
        ) : (
          <UploadButton
            attachmentToUpload={props.attachmentToUpload}
            onAttachmentUpload={addAttachment}
          />
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
  /**
   * Used to set the setAttachmentsToUpload prop, allows for returning loading state
   */
  setAttachmentToUpload: PropTypes.func.isRequired,
  /**
   * toggles loading state
   */
  attachmentToUpload: PropTypes.bool,
}

export default AttachmentDisplay
