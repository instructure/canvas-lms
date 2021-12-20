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
import React, { useState } from 'react';
import formatMessage from "../../../../../../format-message.js";
import { modes } from "../../../reducers/imageSection.js";
import { Button } from '@instructure/ui-buttons';
import { IconArrowOpenDownLine } from '@instructure/ui-icons';
import { View } from '@instructure/ui-view';
import { Menu } from '@instructure/ui-menu';

const ModeSelect = ({
  dispatch
}) => {
  const menuFor = mode => /*#__PURE__*/React.createElement(Menu.Item, {
    key: mode.type,
    value: mode.type,
    onSelect: () => {
      dispatch({
        type: mode.type
      });
    }
  }, mode.label);

  return /*#__PURE__*/React.createElement(Menu, {
    placement: "bottom",
    trigger: /*#__PURE__*/React.createElement(Button, {
      color: "secondary",
      margin: "small"
    }, formatMessage('Add Image'), /*#__PURE__*/React.createElement(View, {
      margin: "none none none x-small"
    }, /*#__PURE__*/React.createElement(IconArrowOpenDownLine, null)))
  }, menuFor(modes.uploadImages), menuFor(modes.singleColorImages), menuFor(modes.multiColorImages), menuFor(modes.courseImages));
};

export default ModeSelect;