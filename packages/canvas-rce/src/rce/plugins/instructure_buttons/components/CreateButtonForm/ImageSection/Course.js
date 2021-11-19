/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React from 'react'

import {View} from '@instructure/ui-view'
import ImageList from '../../../../instructure_image/Images'
import {useStoreProps} from '../../../../shared/StoreContext'
import useDataUrl from '../../../../shared/useDataUrl'

const Course = () => {
  const storeProps = useStoreProps()
  const {files, bookmark, isLoading, hasMore} = storeProps.images[storeProps.contextType]
  const {setUrl, dataUrl, dataLoading, dataError} = useDataUrl()

  // TODO Next: Set the image in the preview icon and remove log
  //            Also, properly handle data loading + error state
  console.log(dataUrl)

  return (
    <View>
      <ImageList
        fetchInitialImages={storeProps.fetchInitialImages}
        fetchNextImages={storeProps.fetchNextImages}
        contextType={storeProps.contextType}
        images={{
          [storeProps.contextType]: {
            files,
            bookmark,
            hasMore,
            isLoading
          }
        }}
        sortBy={{
          sort: 'date_added',
          order: 'desc'
        }}
        onImageEmbed={file => {
          setUrl(file.download_url)
        }}
      />
    </View>
  )
}

export default Course
