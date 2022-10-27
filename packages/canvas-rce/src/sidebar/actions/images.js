/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import {
  ICON_MAKER_ICONS,
  ICON_MAKER_ATTRIBUTE,
  ICON_MAKER_DOWNLOAD_URL_ATTR,
} from '../../rce/plugins/instructure_icon_maker/svg/constants'

import buildDownloadUrl from '../../rce/plugins/shared/buildDownloadUrl'

export const ADD_IMAGE = 'action.images.add_image'
export const REQUEST_INITIAL_IMAGES = 'action.images.request_initial_images'
export const REQUEST_IMAGES = 'action.images.request_images'
export const RECEIVE_IMAGES = 'action.images.receive_images'
export const FAIL_IMAGES_LOAD = 'action.images.fail_images_load'

export function createAddImage({id, filename, display_name, url, thumbnail_url}, contextType) {
  return {
    type: ADD_IMAGE,
    payload: {
      newImage: {
        id,
        filename,
        display_name,
        preview_url: url,
        thumbnail_url,
      },
      contextType,
    },
  }
}

export function requestInitialImages(contextType) {
  return {type: REQUEST_INITIAL_IMAGES, payload: {contextType}}
}

export function requestImages(contextType) {
  return {type: REQUEST_IMAGES, payload: {contextType}}
}

export function receiveImages({response, contextType, opts = {}}) {
  const {files, bookmark, searchString} = response

  return {
    type: RECEIVE_IMAGES,
    payload: {files: files.map(f => applyAttributes(f, opts)), bookmark, contextType, searchString},
  }
}

export function failImagesLoad({error, contextType}) {
  return {type: FAIL_IMAGES_LOAD, payload: {error, contextType}}
}

export const applyAttributes = (file, opts) => {
  const augmentedFile = {...file}

  if (opts.category === ICON_MAKER_ICONS) {
    augmentedFile[ICON_MAKER_ATTRIBUTE] = true
    augmentedFile[ICON_MAKER_DOWNLOAD_URL_ATTR] = buildDownloadUrl(file.download_url)
  }

  return augmentedFile
}

// dispatches the start of the load, requests a page for the collection from
// the source, then dispatches the loaded page to the store on success or
// clears the load on failure
export function fetchImages(opts = {}) {
  const {category} = opts

  return (dispatch, getState) => {
    const state = getState()
    return state.source
      .fetchImages({...state, category})
      .then(response => dispatch(receiveImages({response, contextType: state.contextType, opts})))
      .catch(error => dispatch(failImagesLoad({error, contextType: state.contextType})))
  }
}
// fetches a page only if a page is not already being loaded and the
// collection is not yet completely loaded
export function fetchNextImages(opts = {}) {
  return (dispatch, getState) => {
    const state = getState()
    const images = state.images[state.contextType]
    if (!images?.isLoading && images?.hasMore) {
      dispatch(requestImages(state.contextType))
      return dispatch(fetchImages(opts))
    }
  }
}
// fetches the next page (subject to conditions on fetchNextImages) only if the
// collection is currently empty
export function fetchInitialImages(opts = {}) {
  return (dispatch, getState) => {
    const state = getState()
    dispatch(requestInitialImages(state.contextType))
    return dispatch(fetchImages(opts))
  }
}
