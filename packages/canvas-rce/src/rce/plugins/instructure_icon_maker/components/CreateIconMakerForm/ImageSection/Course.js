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

import React, {useEffect} from 'react'
import PropTypes from 'prop-types'
import {View} from '@instructure/ui-view'
import ImageList from '../../../../instructure_image/Images'
import {useStoreProps} from '../../../../shared/StoreContext'
import useDataUrl from '../../../../shared/useDataUrl'
import {actions} from '../../../reducers/imageSection'
import {canCompressImage, compressImage, shouldCompressImage} from './compressionUtils'

const dispatchImage = async (dispatch, dataUrl, dataBlob) => {
  let image = dataUrl
  dispatch({...actions.SET_IMAGE, payload: ''})
  dispatch({...actions.SET_CROPPER_OPEN, payload: true})
  if (canCompressImage() && shouldCompressImage(dataBlob)) {
    try {
      // If compression fails, use the original one
      // TODO: We can show the user that compression failed in some way
      image = await compressImage(dataUrl)
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e)
    }
    dispatch({...actions.SET_COMPRESSION_STATUS, payload: true})
  }
  dispatch({...actions.SET_IMAGE, payload: image})
}

const Course = ({dispatch, onLoading, onLoaded}) => {
  const storeProps = useStoreProps()
  const {files, bookmark, isLoading, hasMore} = storeProps.images[storeProps.contextType]
  const {setUrl, dataUrl, dataLoading, dataBlob} = useDataUrl()

  const category = 'uncategorized'

  // Handle image selection
  useEffect(() => {
    // Don't clear the current image on re-render
    if (!dataUrl || !dataBlob) return
    dispatchImage(dispatch, dataUrl, dataBlob)
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dataUrl, dataBlob])

  // Handle loading states
  useEffect(() => {
    dispatch(dataLoading ? actions.START_LOADING : actions.STOP_LOADING)

    if (dataUrl) {
      dispatch({...actions.SET_IMAGE_COLLECTION_OPEN, payload: false})
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dataLoading])

  useEffect(() => {
    if (isLoading) onLoading && onLoading()
    else onLoaded && onLoaded()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isLoading])

  return (
    <View>
      <ImageList
        fetchInitialImages={() => storeProps.fetchInitialImages({category})}
        fetchNextImages={() => storeProps.fetchNextImages({category})}
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
          dispatch({...actions.SET_IMAGE_NAME, payload: file.filename})
        }}
      />
    </View>
  )
}

Course.propTypes = {
  dispatch: PropTypes.func,
  onLoading: PropTypes.func,
  onLoaded: PropTypes.func
}

Course.defaultProps = {
  dispatch: () => {},
  onLoading: () => {},
  onLoaded: () => {}
}

export default Course
