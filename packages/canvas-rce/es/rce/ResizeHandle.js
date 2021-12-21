import _slicedToArray from "@babel/runtime/helpers/esm/slicedToArray";

/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import React, { useState } from 'react';
import { func, string } from 'prop-types';
import { DraggableCore } from 'react-draggable';
import keycode from 'keycode';
import { View } from '@instructure/ui-view';
import { IconDragHandleLine } from '@instructure/ui-icons';
import DraggingBlocker from "./DraggingBlocker.js";
import formatMessage from "../format-message.js";
const RESIZE_STEP = 16;
export default function ResizeHandle(props) {
  const _useState = useState(false),
        _useState2 = _slicedToArray(_useState, 2),
        dragging = _useState2[0],
        setDragging = _useState2[1]; // tracking isFocused rather than leveraging instui Focusable
  // because Focusable doesn't detect whan ResizeHandle gets focus


  const _useState3 = useState(false),
        _useState4 = _slicedToArray(_useState3, 2),
        isFocused = _useState4[0],
        setIsFocused = _useState4[1];

  return /*#__PURE__*/React.createElement(View, {
    "aria-label": formatMessage('Drag handle. Use up and down arrows to resize'),
    title: formatMessage('Resize'),
    as: "span",
    borderRadius: "medium",
    display: "inline-block",
    withFocusOutline: isFocused,
    padding: "0 xx-small",
    position: "relative",
    role: "button",
    "data-btn-id": props['data-btn-id'],
    tabIndex: props.tabIndex,
    onKeyDown: function (event) {
      if (event.keyCode === keycode.codes.up) {
        event.preventDefault();
        event.stopPropagation();
        props.onDrag(event, {
          deltaY: -16
        });
      } else if (event.keyCode === keycode.codes.down) {
        event.preventDefault();
        event.stopPropagation();
        props.onDrag(event, {
          deltaY: RESIZE_STEP
        });
      }
    },
    onFocus: function (event) {
      var _props$onFocus;

      setIsFocused(true);
      (_props$onFocus = props.onFocus) === null || _props$onFocus === void 0 ? void 0 : _props$onFocus.call(props, event);
    },
    onBlur: function () {
      setIsFocused(false);
    }
  }, /*#__PURE__*/React.createElement(DraggableCore, {
    offsetParent: document.body,
    onDrag: props.onDrag,
    onStart: function () {
      setDragging(true);
    },
    onStop: function () {
      setDragging(false);
    }
  }, /*#__PURE__*/React.createElement(View, {
    cursor: "ns-resize"
  }, /*#__PURE__*/React.createElement(IconDragHandleLine, null))), /*#__PURE__*/React.createElement(DraggingBlocker, {
    dragging: dragging
  }));
}
ResizeHandle.propTypes = {
  onDrag: func,
  onFocus: func,
  tabIndex: string,
  'data-btn-id': string
};
ResizeHandle.defaultProps = {
  onDrag: () => {},
  tabIndex: '-1'
};