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

import {useScope as createI18nScope} from '@canvas/i18n'
import {RocketSVG} from '@instructure/canvas-media'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {DragEvent, PropsWithChildren, useRef, useState} from 'react'
import {FileUploadModals} from '../shared/FileUploadModals'
import {FileOptionsResults} from '../FilesHeader/UploadButton/FileOptions'
import {queueOptionsCollectionUploads, startUpload} from '../../../utils/uploadUtils'
import {BBFolderWrapper} from '../../../utils/fileFolderWrappers'

const I18n = createI18nScope('upload_drop_zone')

export const DragAndDropWrapper = (
  props: PropsWithChildren<{
    enabled: boolean
    minHeight: number
    currentFolder: BBFolderWrapper
    contextId: string | number
    contextType: string
  }>,
) => {
  const [fileOptions, setFileOptions] = useState<FileOptionsResults | null>(null)

  // can't use 'relatedTarget' on Safari, so we use a counter to track the number of drag events
  // that are currently happening over the container
  const counterRef = useRef(0)

  const [isOverlayShowing, setIsOverlayShowing] = useState(false)
  const showOverlay = () => {
    setIsOverlayShowing(true)
  }
  const hideOverlay = () => {
    setIsOverlayShowing(false)
  }

  const onDragOver = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault()
  }
  const onDragEnter = () => {
    counterRef.current += 1
    showOverlay()
  }
  const onDragLeave = () => {
    counterRef.current -= 1
    if (counterRef.current <= 0) {
      counterRef.current = 0
      hideOverlay()
    }
  }
  const onDrop = (e: DragEvent<HTMLDivElement>) => {
    e.preventDefault()
    counterRef.current = 0
    hideOverlay()

    const fileOptions = startUpload(
      props.currentFolder,
      props.contextId,
      props.contextType,
      () => {},
      e.dataTransfer.files,
    )
    setFileOptions(fileOptions)
  }

  const onModalResolved = (fileOptions: FileOptionsResults) => {
    setFileOptions(fileOptions)
    queueOptionsCollectionUploads(props.contextId, props.contextType, fileOptions, () => {})
  }

  const onModalClose = (fileOptions: FileOptionsResults) => {
    setFileOptions(fileOptions)
    hideOverlay()
  }

  if (!props.enabled) {
    return props.children
  }
  return (
    <div
      onDragEnter={onDragEnter}
      onDragOver={onDragOver}
      onDragLeave={onDragLeave}
      onDrop={onDrop}
      className="FileDragOverlayContainer"
      style={{
        minHeight: isOverlayShowing ? `${props.minHeight}px` : undefined,
      }}
    >
      {props.children}
      <div
        className="FileDragOverlay"
        style={{
          display: isOverlayShowing ? 'unset' : 'none',
        }}
      >
        <FileDrop
          height="100%"
          renderLabel={
            <Flex
              data-filedropcontent
              direction="column"
              height="100%"
              alignItems="center"
              justifyItems="center"
              gap="large"
            >
              <RocketSVG width="180px" height="180px" />
              <Heading variant="titleSection">{I18n.t('Drop files here to upload')}</Heading>
            </Flex>
          }
        />
      </div>
      <FileUploadModals
        fileOptions={fileOptions}
        onResolved={onModalResolved}
        onClose={onModalClose}
      />
    </div>
  )
}
