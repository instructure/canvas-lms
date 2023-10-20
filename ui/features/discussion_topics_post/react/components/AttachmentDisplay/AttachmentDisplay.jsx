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
import {uploadFile} from '@canvas/upload-file'
import {useScope as useI18nScope} from '@canvas/i18n'
import {DiscussionManagerUtilityContext} from '../../utils/constants'

const I18n = useI18nScope('discussion_topics_post')
export function AttachmentDisplay(props) {
  const {setOnFailure, setOnSuccess} = useContext(AlertManagerContext)
  const {isGradedDiscussion} = useContext(DiscussionManagerUtilityContext)

  const removeAttachment = () => {
    props.setAttachment(null)
  }

  // This method uses the uploadFile helper method to upload a discussion attachment
  // Normally attachments will be placed in the discussion attachment folder
  // Graded discussion attachments should not count against user quotas, so they use a different url/process and aren't affected by quotas
  const addAttachment = async e => {
    // URL destination changes based on the type of discussion
    const fileUploadURL = isGradedDiscussion
      ? '/files/pending'
      : `/api/v1/folders/${ENV.DISCUSSION?.ATTACHMENTS_FOLDER_ID}/files`
    const files = Array.from(e.currentTarget?.files)

    // We are only allowing a single file submission, if there is not exactly 1 file, set failure and cancel the upload
    if (files.length !== 1) {
      setOnFailure(I18n.t('Error adding file to discussion message'))
      return
    }
    const fileToUpload = files[0]

    // Set state to upload in progress
    props.setAttachmentToUpload(true)
    setOnSuccess(I18n.t('Uploading file'))

    try {
      // attachmentInformation structure changes depending on the type of discussion
      let attachmentInformation = {}
      if (isGradedDiscussion) {
        // If the file is submitted in a graded discussion, a different path is used that requires different information
        // This is required to get the file to be uploaded to the submissions folder and ignore the quota limits

        attachmentInformation['attachment[filename]'] = fileToUpload.name
        attachmentInformation['attachment[content_type]'] = fileToUpload.type
        attachmentInformation['attachment[intent]'] = 'submit' // directs the logic in the files_controller to skip quota checks
        attachmentInformation['attachment[context_code]'] = `${ENV?.context_asset_string}` // used to find the correct course folder
        attachmentInformation['attachment[asset_string]'] = `${ENV?.DISCUSSION.ASSIGNMENT}` // required for downloads to go to submission folder
      } else {
        // If uploading file to the attachment folder, only name and type are required
        attachmentInformation = {
          name: fileToUpload.name,
          content_type: fileToUpload.type,
        }
      }

      // Changed from uploadFiles to uploadFile because we need to control the pre-flight data ( attachmentInformation)
      const newFile = await uploadFile(fileUploadURL, attachmentInformation, fileToUpload)

      const newFileInfo = {
        _id: newFile.id,
        url: newFile.url,
        displayName: newFile.display_name,
      }
      props.setAttachment(newFileInfo)
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
          ENV.can_attach_entries && (
            <UploadButton
              attachmentToUpload={props.attachmentToUpload}
              onAttachmentUpload={addAttachment}
            />
          )
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
