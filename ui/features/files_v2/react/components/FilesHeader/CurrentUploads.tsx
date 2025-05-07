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

import {useCallback, useEffect, useState} from 'react'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import UploadProgress, {Uploader} from './UploadProgress'
import FileRenameForm from '../FilesHeader/UploadButton/FileRenameForm'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {type ResolvedName} from '../FilesHeader/UploadButton/FileOptions'

type CurrentUploadsProps = {
  onUploadChange?: (uploadsCount: number) => void
}

const CurrentUploads = ({onUploadChange}: CurrentUploadsProps) => {
  const [currentUploads, setCurrentUploads] = useState<Uploader[]>([])
  const [conflictedUploads, setConflictedUploads] = useState<Uploader[]>([])

  const handleUploadQueueChange = useCallback(() => {
    const allUploaders = UploadQueue.getAllUploaders()
    const conflicted = allUploaders.filter(uploader => uploader.error?.response.status === 409)
    setCurrentUploads(allUploaders)
    setConflictedUploads(conflicted)
  }, [])

  const onNameConflictResolved = (fileNameOptions: ResolvedName): void => {
    FileOptionsCollection.resetState()
    FileOptionsCollection.onNameConflictResolved(fileNameOptions)
    FileOptionsCollection.setState({
      newOptions: true,
    })
    FileOptionsCollection.onChange()
    conflictedUploads[0].cancel?.()
  }

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => onUploadChange?.(currentUploads.length), [currentUploads])

  useEffect(() => {
    UploadQueue.addChangeListener(handleUploadQueueChange)
    return () => UploadQueue.removeChangeListener(handleUploadQueueChange)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (currentUploads.length) {
    return (
      <>
        <View as="div" data-testid="current-uploads" className="current_uploads" padding="medium">
          <Flex direction="column" gap="medium">
            {currentUploads.map(uploader => {
              return (
                <Flex.Item key={uploader.getFileName()}>
                  <UploadProgress uploader={uploader} />
                </Flex.Item>
              )
            })}
          </Flex>
        </View>
        {conflictedUploads.length > 0 && (
          <FileRenameForm
            open={conflictedUploads.length > 0}
            onClose={() => {
              conflictedUploads[0].cancel?.()
            }}
            fileOptions={conflictedUploads[0].options}
            onNameConflictResolved={fileNameOptions => {
              onNameConflictResolved(fileNameOptions)
            }}
          />
        )}
      </>
    )
  } else {
    return null
  }
}

export default CurrentUploads
