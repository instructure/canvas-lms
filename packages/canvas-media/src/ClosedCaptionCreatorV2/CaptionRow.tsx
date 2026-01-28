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

import {Alert} from '@instructure/ui-alerts'
import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDownloadLine, IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import formatMessage from 'format-message'

/**
 * Base props shared across all caption row states
 */
interface BaseCaptionRowProps {
  captionName: string
  liveRegion: () => HTMLElement | null
}

/**
 * Props for a caption in processing state
 */
interface ProcessingCaptionRowProps extends BaseCaptionRowProps {
  status: 'processing'
  processingText?: string
}

/**
 * Props for a caption in failed state
 */
interface FailedCaptionRowProps extends BaseCaptionRowProps {
  status: 'failed'
  errorMessage?: string
  onRetry?: () => void
  onDelete: () => void
}

/**
 * Props for a caption in uploaded state
 */
interface UploadedCaptionRowProps extends BaseCaptionRowProps {
  status: 'uploaded'
  onDownload?: () => void
  onDelete: () => void
  isInherited?: boolean
}

/**
 * Discriminated union of all caption row prop types
 */
export type CaptionRowProps =
  | ProcessingCaptionRowProps
  | FailedCaptionRowProps
  | UploadedCaptionRowProps

const CAPTIONS_MESSAGE =
  'Captions inherited from a parent course cannot be removed. You can replace by uploading a new caption file.'
const DELETE_CAPTIONS_MESSAGE = 'Delete {captionName}'

/**
 * Displays a single caption row with status-specific UI
 */
export function CaptionRow(props: CaptionRowProps) {
  const {status, captionName} = props

  return (
    <View as="div" padding="space8 0" borderWidth="0 0 small 0">
      <Flex justifyItems="space-between" alignItems="center">
        {/* Left side: Language and filename */}
        <Flex.Item shouldGrow shouldShrink>
          <View as="div">
            <View as="div" margin="xx-small 0 0 0">
              <TruncateText maxLines={1}>
                <Text variant="contentImportant">{captionName}</Text>
              </TruncateText>
            </View>
          </View>
        </Flex.Item>

        {/* Right side: Status-specific content */}
        <Flex.Item>
          {status === 'processing' && (
            <Flex alignItems="center" gap="small">
              <Text variant="content">
                {props.processingText || formatMessage('Processing...')}
              </Text>
            </Flex>
          )}

          {status === 'failed' && (
            <>
              {/* Error message alert for screen readers */}
              {props.errorMessage && (
                <Alert
                  liveRegion={props.liveRegion}
                  screenReaderOnly={true}
                  isLiveRegionAtomic={true}
                  liveRegionPoliteness="assertive"
                >
                  {formatMessage('{captionName} caption upload failed: {errorMessage}', {
                    captionName: props.captionName,
                    errorMessage: props.errorMessage,
                  })}
                </Alert>
              )}

              <Flex alignItems="center" gap="small">
                <Text size="small" color="danger">
                  {props.errorMessage || 'Upload failed'}
                </Text>

                <IconButton
                  screenReaderLabel={formatMessage(DELETE_CAPTIONS_MESSAGE, {captionName})}
                  onClick={props.onDelete}
                  size="small"
                  withBackground={false}
                  withBorder={false}
                >
                  <IconTrashLine />
                </IconButton>
              </Flex>
            </>
          )}

          {status === 'uploaded' && (
            <Flex alignItems="center" gap="small">
              {props.onDownload && (
                <IconButton
                  screenReaderLabel={formatMessage('Download {captionName}', {
                    captionName: props.captionName,
                  })}
                  onClick={props.onDownload}
                  size="small"
                  withBackground={false}
                  withBorder={false}
                >
                  <IconDownloadLine />
                </IconButton>
              )}

              <IconButton
                screenReaderLabel={
                  props.isInherited
                    ? formatMessage(CAPTIONS_MESSAGE)
                    : formatMessage(DELETE_CAPTIONS_MESSAGE, {captionName: props.captionName})
                }
                disabled={props.isInherited}
                onClick={props.onDelete}
                size="small"
                withBackground={false}
                withBorder={false}
                interaction={props.isInherited ? 'disabled' : 'enabled'}
              >
                <IconTrashLine />
              </IconButton>
            </Flex>
          )}
        </Flex.Item>
      </Flex>
      {status === 'uploaded' && props.isInherited && (
        <Text variant="legend" aria-hidden>
          {formatMessage(CAPTIONS_MESSAGE)}
        </Text>
      )}
    </View>
  )
}
