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

import {IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDownloadLine, IconRefreshLine, IconTrashLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {View} from '@instructure/ui-view'
import formatMessage from 'format-message'

/**
 * Base props shared across all caption row states
 */
interface BaseCaptionRowProps {
  captionName: string
  deleteButtonRef?: (el: Element | null) => void
}

/**
 * Props for a caption in processing state
 */
interface ProcessingCaptionRowProps extends BaseCaptionRowProps {
  workflow_state: 'processing'
}

/**
 * Props for a caption in failed state
 */
interface FailedCaptionRowProps extends BaseCaptionRowProps {
  workflow_state: 'failed'
  failedOperation?: 'upload' | 'delete' | 'asr'
  asr?: boolean
  onRetry?: () => void
  onDelete?: () => void
}

/**
 * Props for a caption in ready state
 */
interface UploadedCaptionRowProps extends BaseCaptionRowProps {
  workflow_state: 'ready'
  filename?: string
  url?: string
  onDelete?: () => void
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

export function getStatusText(
  workflow_state: CaptionRowProps['workflow_state'],
  failedOperation?: 'upload' | 'delete' | 'asr',
  asr?: boolean,
): string | undefined {
  if (workflow_state === 'processing') {
    return formatMessage('Processing...')
  }
  if (workflow_state === 'failed') {
    if (failedOperation === 'delete') return formatMessage('Delete failed')
    if (failedOperation === 'asr' || asr) return formatMessage('Generation failed')
    return formatMessage('Upload failed')
  }
  return undefined
}

/**
 * Displays a single caption row with status-specific UI
 */
export function CaptionRow(props: CaptionRowProps) {
  const {workflow_state, captionName} = props

  const {failedOperation, asr} = props as FailedCaptionRowProps
  const statusText = getStatusText(workflow_state, failedOperation, asr)
  const ariaLabel = statusText ? `${captionName}, ${statusText}` : captionName

  return (
    <View as="div" padding="space8 0" borderWidth="0 0 small 0" tabIndex={0} aria-label={ariaLabel}>
      <Flex justifyItems="space-between" alignItems="center">
        {/* Left side: Language and filename */}
        <Flex.Item shouldGrow shouldShrink>
          <View as="div">
            <View as="div" margin="xx-small 0 0 0">
              <TruncateText maxLines={1}>
                <Text variant="contentImportant" aria-hidden="true">
                  {captionName}
                </Text>
              </TruncateText>
            </View>
          </View>
        </Flex.Item>

        {/* Right side: Status-specific content */}
        <Flex.Item>
          {workflow_state === 'processing' && (
            <Flex alignItems="center" gap="small">
              <Text variant="content" aria-hidden="true">
                {statusText}
              </Text>
            </Flex>
          )}

          {workflow_state === 'failed' && (
            <Flex alignItems="center" gap="small">
              <Text size="small" color="danger" aria-hidden="true">
                {statusText}
              </Text>
              {props.onRetry && (
                <IconButton
                  screenReaderLabel={formatMessage('Retry {captionName}', {
                    captionName: props.captionName,
                  })}
                  onClick={props.onRetry}
                  size="small"
                  withBackground={false}
                  withBorder={false}
                >
                  <IconRefreshLine />
                </IconButton>
              )}
              {props.onDelete && (
                <IconButton
                  screenReaderLabel={formatMessage(DELETE_CAPTIONS_MESSAGE, {
                    captionName: props.captionName,
                  })}
                  onClick={props.onDelete}
                  size="small"
                  withBackground={false}
                  withBorder={false}
                  elementRef={props.deleteButtonRef}
                >
                  <IconTrashLine />
                </IconButton>
              )}
            </Flex>
          )}

          {workflow_state === 'ready' && (
            <Flex alignItems="center" gap="small">
              <IconButton
                screenReaderLabel={formatMessage('Download {captionName}', {
                  captionName: props.captionName,
                })}
                size="small"
                withBackground={false}
                withBorder={false}
                href={props.url}
                download={props.filename}
              >
                <IconDownloadLine />
              </IconButton>

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
                elementRef={props.deleteButtonRef}
              >
                <IconTrashLine />
              </IconButton>
            </Flex>
          )}
        </Flex.Item>
      </Flex>
      {workflow_state === 'ready' && props.isInherited && (
        <Text variant="legend" aria-hidden>
          {formatMessage(CAPTIONS_MESSAGE)}
        </Text>
      )}
    </View>
  )
}
