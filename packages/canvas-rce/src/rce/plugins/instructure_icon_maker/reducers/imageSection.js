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

import formatMessage from '../../../../format-message'

export const initialState = {
  mode: '',
  image: '',
  imageName: '',
  icon: '',
  iconFillColor: '#000000',
  collectionOpen: false,
  loading: false,
  error: undefined,
  cropperOpen: false,
  cropperSettings: null,
  compressed: false,
}

export const actions = {
  RESET_ALL: {type: 'ResetAll'},
  SET_IMAGE: {type: 'SetImage'},
  SET_IMAGE_NAME: {type: 'SetImageName'},
  SET_COMPRESSION_STATUS: {type: 'SetCompressionStatus'},
  CLEAR_IMAGE: {type: 'ClearImage'},
  SET_ICON: {type: 'SetIcon'},
  SET_ICON_FILL_COLOR: {type: 'SetIconFillColor'},
  SET_IMAGE_COLLECTION_OPEN: {type: 'SetImageCollectionOpen'},
  START_LOADING: {type: 'StartLoading'},
  STOP_LOADING: {type: 'StopLoading'},
  CLEAR_MODE: {type: 'ClearMode'},
  UPDATE_SETTINGS: {type: 'UpdateSettings'},
  SET_CROPPER_OPEN: {type: 'SetCropperOpen'},
  SET_CROPPER_SETTINGS: {type: 'SetCropperSettings'},
}

export const modes = {
  courseImages: {type: 'Course', label: formatMessage('Course Images')},
  uploadImages: {type: 'Upload', label: formatMessage('Upload Image')},
  singleColorImages: {type: 'SingleColor', label: formatMessage('Single Color Image')},
  multiColorImages: {type: 'MultiColor', label: formatMessage('Multi Color Image')},
}

const imageSection = (state, action) => {
  switch (action.type) {
    case actions.START_LOADING.type:
      return {...state, loading: true}
    case actions.STOP_LOADING.type:
      return {...state, loading: false}
    case actions.SET_IMAGE.type:
      return {...state, image: action.payload}
    case actions.SET_IMAGE_NAME.type:
      return {...state, imageName: action.payload}
    case actions.SET_COMPRESSION_STATUS.type:
      return {...state, compressed: action.payload}
    case actions.CLEAR_IMAGE.type:
      return {...state, image: '', imageName: '', compressed: false}
    case actions.SET_ICON.type:
      return {...state, icon: action.payload}
    case actions.SET_ICON_FILL_COLOR.type:
      return {...state, iconFillColor: action.payload}
    case actions.CLEAR_MODE.type:
      return {...state, mode: ''}
    case actions.SET_IMAGE_COLLECTION_OPEN.type:
      return {...state, collectionOpen: action.payload}
    case actions.RESET_ALL.type:
      return {...state, ...initialState}
    case modes.uploadImages.type:
      return {...state, mode: modes.uploadImages.type}
    case modes.singleColorImages.type:
      return {...state, mode: modes.singleColorImages.type}
    case modes.multiColorImages.type:
      return {...state, mode: modes.multiColorImages.type}
    case modes.courseImages.type:
      return {...state, mode: modes.courseImages.type}
    case actions.UPDATE_SETTINGS.type:
      return {...state, ...action.payload}
    case actions.SET_CROPPER_OPEN.type:
      return {...state, cropperOpen: action.payload}
    case actions.SET_CROPPER_SETTINGS.type:
      return {...state, cropperSettings: action.payload}
    default:
      throw Error('Unknown action for image selection reducer')
  }
}

export default imageSection
