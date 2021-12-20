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
import React from 'react';
import { bool, func, node, string } from 'prop-types';
import formatMessage from "../../../../format-message.js";
import { ToggleGroup } from '@instructure/ui-toggle-details';
import { Text } from '@instructure/ui-text';
import { View } from '@instructure/ui-view';
export default function AccordionSection({
  collection,
  children,
  onToggle,
  expanded,
  label
}) {
  const toggleLabel = expanded ? formatMessage('Collapse to hide {types}', {
    types: label
  }) : formatMessage('Expand to see {types}', {
    types: label
  });
  return /*#__PURE__*/React.createElement(View, {
    as: "div",
    borderWidth: "0 0 small 0",
    "data-testid": "instructure_links-AccordionSection"
  }, /*#__PURE__*/React.createElement(ToggleGroup, {
    toggleLabel: toggleLabel,
    summary: /*#__PURE__*/React.createElement(View, {
      display: "inline-block",
      padding: "0 0 0 small"
    }, /*#__PURE__*/React.createElement(Text, {
      weight: "bold"
    }, label)),
    expanded: expanded,
    onToggle: (_e, expanded) => onToggle(expanded ? collection : ''),
    border: false
  }, /*#__PURE__*/React.createElement(React.Fragment, null, children)));
}
AccordionSection.propTypes = {
  collection: string.isRequired,
  children: node.isRequired,
  onToggle: func.isRequired,
  expanded: bool.isRequired,
  label: string.isRequired
};