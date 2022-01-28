import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

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
import React, { useReducer, useState, useEffect, Suspense } from 'react';
import formatMessage from "../../../../../../format-message.js";
import reducer, { actions, initialState, modes } from "../../../reducers/imageSection.js";
import { actions as svgActions } from "../../../reducers/svgSettings.js";
import { Button } from '@instructure/ui-buttons';
import { Flex } from '@instructure/ui-flex';
import { Group } from "../Group.js";
import { IconCropSolid } from '@instructure/ui-icons';
import { ImageCropperModal } from "../ImageCropper/index.js";
import { Spinner } from '@instructure/ui-spinner';
import { Text } from '@instructure/ui-text';
import { TruncateText } from '@instructure/ui-truncate-text';
import { View } from '@instructure/ui-view';
import Course from "./Course.js";
import ModeSelect from "./ModeSelect.js";
import PreviewIcon from "../../../../shared/PreviewIcon.js";
export const ImageSection = ({
  settings,
  onChange,
  editing,
  editor
}) => {
  const _useState = useState(false),
        _useState2 = _slicedToArray(_useState, 2),
        openCropModal = _useState2[0],
        setOpenCropModal = _useState2[1];

  const _useReducer = useReducer(reducer, initialState),
        _useReducer2 = _slicedToArray(_useReducer, 2),
        state = _useReducer2[0],
        dispatch = _useReducer2[1];

  const Upload = /*#__PURE__*/React.lazy(() => import('./Upload'));
  const allowedModes = {
    [modes.courseImages.type]: Course,
    [modes.uploadImages.type]: Upload
  };
  useEffect(() => {
    if (editing) {
      dispatch({
        type: actions.SET_IMAGE.type,
        payload: settings.encodedImage
      });
    }
  }, [settings.encodedImage]);
  useEffect(() => {
    if (editing) {
      dispatch({
        type: actions.SET_IMAGE_NAME.type,
        payload: settings.encodedImageName
      });
    }
  }, [settings.encodedImageName]);
  useEffect(() => {
    onChange({
      type: svgActions.SET_ENCODED_IMAGE,
      payload: state.image
    });
  }, [state.image]);
  useEffect(() => {
    onChange({
      type: svgActions.SET_ENCODED_IMAGE_TYPE,
      payload: state.mode
    });
  }, [state.mode]);
  useEffect(() => {
    onChange({
      type: svgActions.SET_ENCODED_IMAGE_NAME,
      payload: state.imageName
    });
  }, [state.imageName]);
  return /*#__PURE__*/React.createElement(Group, {
    as: "section",
    defaultExpanded: true,
    summary: formatMessage('Image')
  }, /*#__PURE__*/React.createElement(Flex, {
    direction: "column",
    margin: "small"
  }, /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(Text, {
    weight: "bold"
  }, formatMessage('Current Image'))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(Flex, null, /*#__PURE__*/React.createElement(Flex.Item, {
    shouldGrow: true
  }, /*#__PURE__*/React.createElement(Flex, null, /*#__PURE__*/React.createElement(Flex.Item, {
    margin: "0 small 0 0"
  }, /*#__PURE__*/React.createElement(PreviewIcon, {
    variant: "large",
    testId: "selected-image-preview",
    image: state.image,
    loading: state.loading
  })))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(View, {
    maxWidth: "200px",
    as: "div"
  }, /*#__PURE__*/React.createElement(TruncateText, null, /*#__PURE__*/React.createElement(Text, null, state.imageName ? state.imageName : formatMessage('None Selected'))))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(ModeSelect, {
    dispatch: dispatch
  })))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(Suspense, {
    fallback: /*#__PURE__*/React.createElement(Flex, {
      justifyItems: "center"
    }, /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(Spinner, {
      renderTitle: formatMessage('Loading')
    })))
  }, !!allowedModes[state.mode] && /*#__PURE__*/React.createElement(allowedModes[state.mode], {
    dispatch,
    editor
  }))), /*#__PURE__*/React.createElement(Flex.Item, null, /*#__PURE__*/React.createElement(Button, {
    renderIcon: IconCropSolid,
    onClick: () => {
      setOpenCropModal(true);
    }
  }), openCropModal && /*#__PURE__*/React.createElement(ImageCropperModal, {
    open: openCropModal,
    onClose: () => setOpenCropModal(false),
    image: state.image
  }))));
};