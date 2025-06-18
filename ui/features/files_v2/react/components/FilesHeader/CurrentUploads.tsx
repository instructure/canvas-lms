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
import {usePrevious} from 'react-use'
import {queryClient} from '@canvas/query'
import UploadQueue from '@canvas/files/react/modules/UploadQueue'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import UploadProgress, {Uploader} from './UploadProgress'
import FileRenameForm from '../FilesHeader/UploadButton/FileRenameForm'
import FileOptionsCollection from '@canvas/files/react/modules/FileOptionsCollection'
import {type ResolvedName} from '../FilesHeader/UploadButton/FileOptions'
import {queueOptionsCollectionUploads} from '../../../utils/uploadUtils'
import {useFileManagement} from '../../contexts/FileManagementContext'

const hasInProgressUploads = (uploaders: Uploader[], conflicted: Uploader[]) => {
  // we can't just use UploadQueue.pendingUploads() because errored uploads are counted
  // so if there is at least one non-errored upload, or at least one name-conflicted upload
  // then there is an upload in progress
  return uploaders.some(uploader => !uploader.error) || conflicted.length > 0
}

const CurrentUploads = () => {
  const [currentUploads, setCurrentUploads] = useState<Uploader[]>([])
  const [conflictedUploads, setConflictedUploads] = useState<Uploader[]>([])
  const {contextId, contextType} = useFileManagement()
  const previouslyHadInProgressUploads = usePrevious(
    hasInProgressUploads(currentUploads, conflictedUploads),
  )

  const handleUploadQueueChange = useCallback(() => {
    const allUploaders = UploadQueue.getAllUploaders()
    const conflicted = allUploaders.filter(uploader => uploader.error?.response.status === 409)
    setCurrentUploads(allUploaders)
    setConflictedUploads(conflicted)

    // we only want to refetch when we go from having active uploads to not having any
    // otherwise we will refetch every time a user removes an errored upload from the queue
    if (previouslyHadInProgressUploads && !hasInProgressUploads(allUploaders, conflicted)) {
      queryClient.refetchQueries({queryKey: ['quota'], type: 'active'})
      queryClient.refetchQueries({queryKey: ['files'], type: 'active'})
    }
  }, [previouslyHadInProgressUploads])

  const onNameConflictResolved = (fileNameOptions: ResolvedName): void => {
    FileOptionsCollection.resetState()
    FileOptionsCollection.onNameConflictResolved(fileNameOptions)
    FileOptionsCollection.setState({
      newOptions: true,
    })
    queueOptionsCollectionUploads(
      contextId,
      contextType,
      FileOptionsCollection.getState(),
      conflictedUploads[0].cancel,
    )
  }

  useEffect(() => {
    UploadQueue.addChangeListener(handleUploadQueueChange)
    return () => UploadQueue.removeChangeListener(handleUploadQueueChange)
  }, [handleUploadQueueChange])

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
