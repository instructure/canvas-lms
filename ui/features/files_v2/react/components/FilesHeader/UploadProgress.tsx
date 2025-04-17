/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useState} from 'react'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconWarningSolid, IconXLine} from '@instructure/ui-icons'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {FileOptions} from './UploadButton/FileOptions'

export type Uploader = {
  getFileName: () => string
  getFileType: () => string
  roundProgress: () => number
  abort: () => void
  file: File
  canAbort: () => boolean
  error?: {
    message: string
  }
  cancel?: () => boolean
  options: FileOptions
}

type UploadProgressProps = {
  uploader: Uploader
}

const I18n = createI18nScope('files_v2')

function generateProgressMessage(uploader: Uploader, progress: number) {
  const fileName = uploader.getFileName()
  return progress < 100
    ? I18n.t('%{fileName} - %{progress} percent uploaded', {
        fileName,
        progress,
      })
    : I18n.t('%{fileName} uploaded successfully!', {fileName})
}

const UploadProgress = ({uploader}: UploadProgressProps) => {
  const [progress, setProgress] = useState(() => uploader.roundProgress() || 0)
  const [message, setMessage] = useState<string>(() => generateProgressMessage(uploader, progress))

  const sendProgressUpdate = useCallback(
    (newProgress: number) => {
      const fileName = uploader.getFileName()
      const newMessage =
        newProgress < 100
          ? I18n.t('%{fileName} - %{progress} percent uploaded.', {
              fileName,
              progress: newProgress,
            })
          : I18n.t('%{fileName} uploaded successfully!', {fileName})

      if (message !== newMessage) {
        showFlashAlert({message, err: null, type: 'info', srOnly: true})
        setMessage(newMessage)
        setProgress(newProgress)
      }
    },
    [message, uploader],
  )

  useEffect(() => {
    if (uploader.error) {
      const message = uploader.error.message
        ? I18n.t('Error: %{message}', {message: uploader.error.message})
        : I18n.t('Error uploading file.')
      showFlashAlert({
        message: message,
        type: 'error',
        srOnly: true,
      })
      setMessage(message)
    }
  }, [uploader.error])

  useEffect(() => {
    const newProgress = uploader.roundProgress()
    if (progress !== newProgress) sendProgressUpdate(newProgress)
    return () => sendProgressUpdate(progress)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  return (
    <Flex gap="medium">
      <Flex.Item shouldGrow>
        <Flex direction="column" gap="small">
          <Flex.Item>
            <TruncateText>{uploader.getFileName()}</TruncateText>
          </Flex.Item>

          <Flex.Item>
            <ProgressBar
              meterColor={uploader.error ? 'danger' : 'info'}
              size="x-small"
              screenReaderLabel={message}
              valueNow={uploader.roundProgress()}
              valueMax={100}
              shouldAnimate
            />
          </Flex.Item>
          {uploader.error && (
            <Flex.Item>
              <Text size="small" color="danger">
                <IconWarningSolid />
                &nbsp;
                {I18n.t('File failed to upload. Please try again.')}
              </Text>
            </Flex.Item>
          )}
        </Flex>
      </Flex.Item>
      {uploader.canAbort() && (
        <Flex.Item padding="xx-small">
          <IconButton screenReaderLabel={I18n.t('Cancel upload')} onClick={uploader.cancel}>
            <IconXLine />
          </IconButton>
        </Flex.Item>
      )}
    </Flex>
  )
}

export default UploadProgress
