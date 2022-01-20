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
import React, {useContext} from 'react'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {AttachButton} from './AttachButton'
import {AttachmentButton} from './AttachmentButton'

import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'
import {uploadFiles} from '@canvas/upload-file'

export function AttachmentDisplay(props) {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)

  const removeAttachment = id => {
    props.setAttachments(prev => {
      const index = prev.findIndex(attachment => attachment.id === id)
      prev.splice(index, 1)
      return [...prev]
    })
  }

  const fileUploadUrl = attachmentFolderId => {
    return `/api/v1/folders/${attachmentFolderId}/files`
  }

  const addAttachment = async e => {
    const files = Array.from(e.currentTarget?.files)
    if (!(files.length === 1)) {
      setOnFailure(I18n.t('Error adding files to discussion message'))
    }

    const newAttachmentsToUpload = files.map(file => {
      return {isLoading: true, id: file.url ? `${file.url}` : `${file.name}`}
    })

    props.setAttachmentsToUpload(prev => prev.concat(newAttachmentsToUpload))

    setOnSuccess(I18n.t('Uploading files'))

    try {
      const newFiles = await uploadFiles(
        files,
        fileUploadUrl(ENV.DISCUSSION?.ATTACHMENTS_FOLDER_ID)
      )
      props.setAttachments(prev => prev.concat(newFiles))
    } catch (err) {
      setOnFailure(I18n.t('Error uploading files'))
    } finally {
      props.setAttachmentsToUpload(prev => {
        const attachmentsStillUploading = prev.filter(
          file => !newAttachmentsToUpload.includes(file)
        )
        return attachmentsStillUploading
      })
    }
  }

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          itemSpacing: '0 small 0 0',
          textSize: 'small'
        },
        desktop: {
          itemSpacing: 'none',
          textSize: 'medium'
        }
      }}
      render={(responsiveProps, matches) =>
        props.attachments.length ? (
          <AttachmentButton attachment={props.attachments[0]} onDeleteItem={removeAttachment} />
        ) : (
          <AttachButton onAttachmentUpload={addAttachment} />
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
  attachments: PropTypes.array.isRequired,
  /**
   * Used to set the attachments prop, if no attachment is set
   */
  setAttachments: PropTypes.func.isRequired,
  /**
   * Used to set the setAttachmentsToUpload prop, allows for returning loading state
   */
  setAttachmentsToUpload: PropTypes.func.isRequired
}

export default AttachmentDisplay
