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

import React, {createRef, useCallback, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconUploadLine} from '@instructure/ui-icons'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'

const I18n = useI18nScope('content_migrations_redesign')

type CanvasCartridgeImporterProps = {
  onSelectPreAttachmentFile: (preAttachmentFile: File | null) => void
}

function humanReadableSize(size: number) {
  const units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
  let i = 0
  while (size >= 1024) {
    size /= 1024
    ++i
  }
  return size.toFixed(1) + ' ' + units[i]
}

const CanvasCartridgeImporter = ({onSelectPreAttachmentFile}: CanvasCartridgeImporterProps) => {
  const fileInput = createRef<HTMLInputElement>()
  const [file, setFile] = useState<File | null>(null)

  const handleSelectFile = useCallback(() => {
    const files = fileInput.current?.files
    if (!files) {
      return
    }
    const selectedFile = files[0]

    if (ENV.UPLOAD_LIMIT && selectedFile.size > ENV.UPLOAD_LIMIT) {
      setFile(null)
      onSelectPreAttachmentFile(null)
      showFlashError(
        I18n.t('Your migration can not exceed %{file_size}', {
          file_size: humanReadableSize(ENV.UPLOAD_LIMIT),
        })
      )
    } else {
      setFile(selectedFile)
      onSelectPreAttachmentFile(selectedFile)
    }
  }, [fileInput, onSelectPreAttachmentFile])

  return (
    <>
      <View margin="none none x-small none" style={{display: 'block'}}>
        <label htmlFor="migrationFileUpload">
          <Text weight="bold">{I18n.t('Source')}</Text>
        </label>
      </View>
      <input
        id="migrationFileUpload"
        data-testid="migrationFileUpload"
        type="file"
        ref={fileInput}
        accept=".zip,.imscc,.mbz,.xml"
        onChange={handleSelectFile}
        style={{display: 'none'}}
      />
      <Button color="secondary" onClick={() => fileInput.current?.click()}>
        <IconUploadLine />
        &nbsp;
        {I18n.t('Choose File')}
      </Button>
      <View margin="none none none medium">
        <Text>{file ? file.name : I18n.t('No file chosen')}</Text>
      </View>
    </>
  )
}

export default CanvasCartridgeImporter
