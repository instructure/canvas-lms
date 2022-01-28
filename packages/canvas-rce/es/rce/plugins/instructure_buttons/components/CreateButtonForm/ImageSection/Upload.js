import _objectSpread from "@babel/runtime/helpers/esm/objectSpread2";

/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import React from 'react';
import formatMessage from "../../../../../../format-message.js";
import { actions } from "../../../reducers/imageSection.js";
import { UploadFile } from "../../../../shared/Upload/UploadFile.js";
export const onSubmit = dispatch => (_editor, _accept, _selectedPanel, uploadData) => {
  const theFile = uploadData.theFile;
  dispatch(_objectSpread(_objectSpread({}, actions.SET_IMAGE), {}, {
    payload: theFile.preview
  }));
  dispatch(_objectSpread(_objectSpread({}, actions.SET_IMAGE_NAME), {}, {
    payload: theFile.name
  }));
  dispatch(actions.CLEAR_MODE);
};

const Upload = ({
  editor,
  dispatch
}) => {
  return /*#__PURE__*/React.createElement(UploadFile, {
    accept: "image/*",
    editor: editor,
    label: formatMessage('Upload Image'),
    panels: ['COMPUTER'],
    onDismiss: () => {
      dispatch(actions.CLEAR_MODE);
    },
    requireA11yAttributes: false,
    onSubmit: onSubmit(dispatch)
  });
};

export default Upload;