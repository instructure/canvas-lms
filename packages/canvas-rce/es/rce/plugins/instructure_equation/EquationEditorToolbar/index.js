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
import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { Tabs } from '@instructure/ui-tabs';
import { ScreenReaderContent } from '@instructure/ui-a11y-content';
import { Button } from '@instructure/ui-buttons';
import buttons from "./buttons.js";
import { convertLatexToMarkup } from "../mathlive/index.js";
const buttonContainerStyle = {
  display: 'inline-block',
  marginBottom: '5px',
  paddingRight: '5px'
};
export default function EquationEditorToolbar(props) {
  const _useState = useState('Basic'),
        _useState2 = _slicedToArray(_useState, 2),
        selectedTab = _useState2[0],
        setSelectedTab = _useState2[1];

  return /*#__PURE__*/React.createElement(Tabs, {
    variant: "secondary",
    size: "medium",
    onRequestTabChange: (event, {
      index
    }) => {
      setSelectedTab(buttons[index].name);
    }
  }, buttons.map(section => /*#__PURE__*/React.createElement(Tabs.Panel, {
    key: section.name,
    padding: "small none",
    renderTitle: section.name,
    isSelected: selectedTab === section.name
  }, section.commands.map(({
    displayName,
    command,
    advancedCommand
  }) => {
    const name = displayName || command;
    const icon = /*#__PURE__*/React.createElement("span", {
      dangerouslySetInnerHTML: {
        __html: convertLatexToMarkup(name, {
          mathstyle: 'textstyle'
        })
      }
    }); // I'm inlining styles here because for some reason the RCE plugin plays
    // poorly with the way webpack is compiling styles, causing rules from a
    // styles.css file to not show up. It would be nice to figure out how to
    // fix this, though.

    return /*#__PURE__*/React.createElement("div", {
      style: buttonContainerStyle,
      key: name
    }, /*#__PURE__*/React.createElement(Button, {
      onClick: () => props.executeCommand(command, advancedCommand),
      icon: icon
    }, /*#__PURE__*/React.createElement(ScreenReaderContent, null, "LaTeX: ", name)));
  }))));
}
EquationEditorToolbar.propTypes = {
  executeCommand: PropTypes.func.isRequired
};