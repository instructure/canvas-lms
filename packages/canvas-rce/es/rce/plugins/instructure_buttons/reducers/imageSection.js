import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

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
import formatMessage from "../../../../format-message.js";
export const initialState = {
  mode: '',
  image: '',
  imageName: '',
  loading: false,
  error: void 0
};
export const actions = {
  SET_IMAGE: {
    type: 'SetImage'
  },
  SET_IMAGE_NAME: {
    type: 'SetImageName'
  },
  START_LOADING: {
    type: 'StartLoading'
  },
  STOP_LOADING: {
    type: 'StopLoading'
  },
  CLEAR_MODE: {
    type: 'ClearMode'
  }
};
export const modes = {
  courseImages: {
    type: 'Course',
    label: formatMessage('Course Images')
  },
  uploadImages: {
    type: 'Upload',
    label: formatMessage('Upload Image')
  },
  singleColorImages: {
    type: 'SingleColor',
    label: formatMessage('Single Color Image')
  },
  multiColorImages: {
    type: 'MultiColor',
    label: formatMessage('Multi Color Image')
  }
};

const imageSection = (state, action) => {
  switch (action.type) {
    case actions.START_LOADING.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        loading: true
      });

    case actions.STOP_LOADING.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        loading: false
      });

    case actions.SET_IMAGE.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        image: action.payload
      });

    case actions.SET_IMAGE_NAME.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        imageName: action.payload
      });

    case actions.CLEAR_MODE.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        mode: ''
      });

    case modes.uploadImages.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        mode: modes.uploadImages.type
      });

    case modes.singleColorImages.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        mode: modes.singleColorImages.type
      });

    case modes.multiColorImages.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        mode: modes.multiColorImages.type
      });

    case modes.courseImages.type:
      return _objectSpread(_objectSpread({}, state), {}, {
        mode: modes.courseImages.type
      });

    default:
      throw Error('Unknown action for image selection reducer');
  }
};

export default imageSection;