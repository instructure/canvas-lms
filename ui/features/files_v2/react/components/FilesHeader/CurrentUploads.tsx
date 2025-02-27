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

type CurrentUploadsProps = {
  onUploadChange?: (uploadsCount: number) => void
}

const CurrentUploads = ({onUploadChange}: CurrentUploadsProps) => {
  const [currentUploads, setCurrentUploads] = useState<Uploader[]>([])

  const handleUploadQueueChange = useCallback(
    () => setCurrentUploads(UploadQueue.getAllUploaders()),
    [],
  )

  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => onUploadChange?.(currentUploads.length), [currentUploads])

  useEffect(() => {
    UploadQueue.addChangeListener(handleUploadQueueChange)
    return () => UploadQueue.removeChangeListener(handleUploadQueueChange)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  if (currentUploads.length) {
    return (
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
    )
  } else {
    return null
  }
}

export default CurrentUploads
