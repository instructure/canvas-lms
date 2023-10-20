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
import {
  canCompressImage,
  compressImage,
  shouldCompressImage,
} from '../../../../shared/compressionUtils'
import {isAnUnsupportedGifPngImage, MAX_GIF_PNG_SIZE_BYTES} from './utils'
import {actions as svgActions} from '../../../reducers/svgSettings'
import formatMessage from '../../../../../../format-message'
import {PREVIEW_WIDTH, PREVIEW_HEIGHT} from '../../../../shared/ImageCropper/constants'

const dispatchImage = async (dispatch, onChange, dataUrl, dataBlob) => {
  let image = dataUrl

  if (isAnUnsupportedGifPngImage(dataBlob)) {
    dispatch({...actions.CLEAR_IMAGE})
    return onChange({
      type: svgActions.SET_ERROR,
      payload: formatMessage(
        'GIF/PNG format images larger than {size} KB are not currently supported.',
        {size: MAX_GIF_PNG_SIZE_BYTES / 1024}
      ),
    })
  }

  dispatch({...actions.SET_IMAGE, payload: ''})
  dispatch({...actions.SET_CROPPER_OPEN, payload: true})
  onChange({type: svgActions.SET_EMBED_IMAGE, payload: ''})
  if (canCompressImage() && shouldCompressImage(dataBlob)) {
    try {
      // If compression fails, use the original one
      // TODO: We can show the user that compression failed in some way
      image = await compressImage({
        encodedImage: dataUrl,
        previewWidth: PREVIEW_WIDTH,
        previewHeight: PREVIEW_HEIGHT,
      })
    } catch (e) {
      // eslint-disable-next-line no-console
      console.error(e)
    }
    dispatch({...actions.SET_COMPRESSION_STATUS, payload: true})
  }
  dispatch({...actions.SET_IMAGE, payload: image})
  onChange({type: svgActions.SET_EMBED_IMAGE, payload: image})
}

const Course = ({dispatch, onChange, onLoading, onLoaded, canvasOrigin}) => {
  const storeProps = useStoreProps()
  const {files, bookmark, isLoading, hasMore} = storeProps.images[storeProps.contextType]
  const {setUrl, dataUrl, dataLoading, dataBlob} = useDataUrl()

  const category = 'uncategorized'

  // Handle image selection
  useEffect(() => {
    // Don't clear the current image on re-render
    if (!dataUrl || !dataBlob) return
    dispatchImage(dispatch, onChange, dataUrl, dataBlob)
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
            isLoading,
          },
        }}
        sortBy={{
          sort: 'date_added',
          order: 'desc',
        }}
        onImageEmbed={file => {
          setUrl(file.download_url)
          dispatch({...actions.SET_IMAGE_NAME, payload: file.filename})
        }}
        canvasOrigin={canvasOrigin}
      />
    </View>
  )
}

Course.propTypes = {
  dispatch: PropTypes.func,
  onChange: PropTypes.func,
  onLoading: PropTypes.func,
  onLoaded: PropTypes.func,
  canvasOrigin: PropTypes.string.isRequired,
}

Course.defaultProps = {
  dispatch: () => {},
  onChange: () => {},
  onLoading: () => {},
  onLoaded: () => {},
}

export default Course
