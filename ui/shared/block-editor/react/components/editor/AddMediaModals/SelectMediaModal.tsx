/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useContext, useState} from 'react'
// @ts-expect-error
import {UploadFile, type UploadFilePanelId} from '@instructure/canvas-rce'
import {RCSPropsContext} from '../../../Contexts'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const handleMediaSubmit = async (uploadData: UploadData) => {
  if (uploadData?.fileUrl) {
    const attachment_id = uploadData.fileUrl.match(/\/media_attachments_iframe\/(\d+)/)?.[1]
    return {attachment_id, iframe_url: uploadData.fileUrl}
  } else {
    throw new Error('Selected Panel is invalid') // Should never get here
  }
}

interface AddMediaModalProps {
  open: boolean
  onSubmit: ({attachment_id, iframe_url}: {attachment_id?: string; iframe_url?: string}) => void
  onDismiss: () => void
  accept?: string
  panels?: UploadFilePanelId[]
  title?: string
}

export const SelectMediaModal = ({
  open,
  onSubmit,
  onDismiss,
  accept = 'video/*, audio/*',
  panels,
  title,
}: AddMediaModalProps) => {
  const trayProps = useContext(RCSPropsContext)

  const [uploading, setUploading] = useState(false)
  const handleSubmit = async (
    _editor: any,
    _accept: string,
    _selectedPanel: any,
    uploadData: UploadData,
    _storeProps: any,
  ) => {
    setUploading(true)
    const {attachment_id, iframe_url} = await handleMediaSubmit(uploadData)
    setUploading(false)
    onSubmit({attachment_id, iframe_url})
  }

  const defaultPanels: UploadFilePanelId[] = ['course_media', 'user_media']

  const modalPanels = panels || defaultPanels
  const label = title || I18n.t('Upload Media')

  return open ? (
    <UploadFile
      accept={accept}
      trayProps={trayProps}
      label={label}
      panels={modalPanels}
      onDismiss={onDismiss}
      onSubmit={handleSubmit}
      forBlockEditorUse={true}
      canvasOrigin={trayProps?.canvasOrigin}
      uploading={uploading}
    />
  ) : null
}

type UploadData = {
  theFile: File
  fileUrl: string
  usageRights: {
    usageRight: string
    ccLicense: string
    copyrightHolder: string
  }
}
