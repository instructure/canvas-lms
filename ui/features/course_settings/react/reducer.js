/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import initialState from './store/initialState'

const courseImageHandlers = {
  MODAL_VISIBILITY(state, action) {
    state.showModal = action.payload.showModal
    return state
  },
  UPLOADING_IMAGE(state, _action) {
    state.uploadingImage = true
    return state
  },
  GOT_COURSE_IMAGE(state, action) {
    state.courseImage = action.payload.imageString
    state.imageUrl = action.payload.imageUrl
    state.gettingImage = false
    return state
  },
  SET_COURSE_IMAGE_ID(state, action) {
    state.imageUrl = action.payload.imageUrl
    state.courseImage = action.payload.imageId
    state.showModal = false
    state.uploadingImage = false
    return state
  },
  SET_COURSE_IMAGE_URL(state, action) {
    state.imageUrl = action.payload.imageUrl
    state.courseImage = action.payload.imageUrl
    state.showModal = false
    state.uploadingImage = false
    return state
  },
  ERROR_UPLOADING_IMAGE(state) {
    state.uploadingImage = false
    return state
  },
  REMOVING_IMAGE(state) {
    state.removingImage = true
    return state
  },
  REMOVED_IMAGE(state) {
    state.imageUrl = ''
    state.courseImage = 'abc'
    state.removingImage = false
    return state
  },
  ERROR_REMOVING_IMAGE(state) {
    state.removingImage = false
    return state
  },
}

const courseImage = (state = initialState, action) => {
  if (courseImageHandlers[action.type]) {
    const newState = {...state}
    return courseImageHandlers[action.type](newState, action)
  } else {
    return state
  }
}

export default courseImage
