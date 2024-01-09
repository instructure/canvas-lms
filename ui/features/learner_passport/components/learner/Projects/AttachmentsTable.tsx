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

import React, {useCallback} from 'react'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconDownloadLine} from '@instructure/ui-icons'
import {Table} from '@instructure/ui-table'
import {TruncateText} from '@instructure/ui-truncate-text'
import type {ViewProps} from '@instructure/ui-view'
import type {AttachmentData} from '../../types'
import {
  renderFileTypeIcon,
  isUrlToLocalCanvasFile,
  showFilePreviewInOverlay,
} from '../../shared/utils'

type AttachmnetsTableProps = {
  attachments: AttachmentData[]
}

const AttachmentsTable = ({attachments}: AttachmnetsTableProps) => {
  const handleDownloadAttachment = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      const attachmentId = (event.target as HTMLButtonElement).getAttribute('data-attachmentid')
      if (!attachmentId) return
      const thisAttachment = attachments.find(attachment => attachment.id === attachmentId)
      if (!thisAttachment) return

      let href = thisAttachment.url
      if (isUrlToLocalCanvasFile(thisAttachment.url)) {
        const url = new URL(thisAttachment.url)
        url.searchParams.set('download', '1')
        href = url.href
      }

      const link = document.createElement('a')
      link.setAttribute('dowload', thisAttachment.filename)
      link.href = href
      link.click()
    },
    [attachments]
  )

  const renderSize = (sz: string | number) => {
    const size = Number(sz)
    if (size < 1024) {
      return `${size} bytes`
    } else if (size < 1024 * 1024) {
      return `${Math.round((size / 1024) * 10) / 10} KB`
    } else {
      return `${Math.round((size / (1024 * 1024)) * 10) / 10} MB`
    }
  }

  return (
    <Table caption="attachments" layout="auto">
      <Table.Head>
        <Table.Row>
          <Table.ColHeader id="fliename">File name</Table.ColHeader>
          <Table.ColHeader id="size" width="10rem">
            Size
          </Table.ColHeader>
          <Table.ColHeader id="action" width="10rem">
            Action
          </Table.ColHeader>
        </Table.Row>
      </Table.Head>
      <Table.Body>
        {attachments.map((attachment: AttachmentData) => {
          return (
            <Table.Row key={attachment.id}>
              <Table.Cell>
                <Flex gap="small">
                  <Flex.Item shouldGrow={false}>
                    {renderFileTypeIcon(attachment.contentType)}
                  </Flex.Item>
                  <Flex.Item shouldGrow={true}>
                    <a
                      href={attachment.url}
                      target={attachment.filename}
                      onClick={showFilePreviewInOverlay}
                    >
                      <TruncateText>{attachment.display_name}</TruncateText>
                    </a>
                  </Flex.Item>
                </Flex>
              </Table.Cell>
              <Table.Cell>{renderSize(attachment.size)}</Table.Cell>
              <Table.Cell>
                <Button
                  size="small"
                  renderIcon={IconDownloadLine}
                  data-attachmentid={attachment.id}
                  onClick={handleDownloadAttachment}
                >
                  Download
                </Button>
              </Table.Cell>
            </Table.Row>
          )
        })}
      </Table.Body>
    </Table>
  )
}

export default AttachmentsTable
